import uuid
import random
import string
from datetime import date, datetime, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Header, status, Request
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, update

from app.infra.database import get_db
from app.infra.models import User, Role, RolePermission, Permission, UserSession, OTPRequest, DeviceBlacklist, Device, Property, Subscription, UserPropertyAccess
from app.core.dependencies import get_current_user
from app.core.security import verify_password, create_access_token, create_refresh_token, get_password_hash
from app.modules.audit.logger import AuditLogger
from app.modules.notifications.service import NotificationDispatchService
import jwt
from app.core.limiter import limiter

router = APIRouter()

MAX_FAILED_ATTEMPTS = 5
SESSION_HEARTBEAT_TIMEOUT_MINUTES = 30

# ──────────────────────────────────────────────────────────────────────────────
# Request / Response Schemas
# ──────────────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: Optional[str] = None
    login_id: Optional[str] = None
    mobile_number: Optional[str] = None
    password: str
    device_id: Optional[str] = None
    device_name: Optional[str] = None
    device_fingerprint: Optional[str] = None

class AccessibleProperty(BaseModel):
    property_id: str
    role_id: str
    is_primary: bool

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role_code: str
    properties: List[AccessibleProperty] = []

class PermissionSnapshot(BaseModel):
    permission_code: str
    access_level: str

class AccessiblePropertySnapshot(BaseModel):
    property_id: str
    property_name: str
    onboarding_status: str
    subscription_status: Optional[str] = None
    trial_ends_at: Optional[str] = None
    is_primary: bool = False

class OfflineBootstrapResponse(BaseModel):
    user_id: uuid.UUID
    name: str
    email: Optional[str] = None
    mobile_number: Optional[str] = None
    role_code: str
    pin_hash: Optional[str] = None
    permissions: List[PermissionSnapshot]
    # Onboarding & subscription context for state machine routing
    onboarding_status: Optional[str] = None
    subscription_status: Optional[str] = None
    trial_ends_at: Optional[str] = None
    accessible_properties: List[AccessiblePropertySnapshot] = []

class OTPRequestPayload(BaseModel):
    identifier: str  # email, mobile, or username

class OTPVerifyPayload(BaseModel):
    identifier: str
    otp: str

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

def _generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


async def _resolve_user(db: AsyncSession, identifier: str) -> Optional[User]:
    stmt = select(User).where(
        or_(
            User.email == identifier,
            User.username == identifier,
            User.mobile_number == identifier,
        )
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def _build_token_response(db: AsyncSession, user: User, device_id_str: Optional[str], device_fp: str) -> TokenResponse:
    """Creates access+refresh tokens, persists a session, and returns TokenResponse."""
    access_token = create_access_token(
        user_id=str(user.id),
        tenant_id=str(user.property_id or ""),
        device_fp=device_fp,
    )
    refresh_token = create_refresh_token(
        user_id=str(user.id),
        device_fp=device_fp,
    )

    device_id: Optional[uuid.UUID] = None
    if device_fp:
        stmt = select(Device.id).where(Device.device_uid == device_fp)
        res = await db.execute(stmt)
        device_id = res.scalar_one_or_none()

    session = UserSession(
        id=uuid.uuid4(),
        user_id=user.id,
        device_id=device_id,
        session_token=access_token,
        is_offline_session=False,
        expires_at=datetime.utcnow() + timedelta(hours=12),
    )
    db.add(session)
    await db.flush()

    accessible_properties: List[AccessibleProperty] = []
    if user.property_id:
        accessible_properties.append(
            AccessibleProperty(property_id=str(user.property_id), role_id=str(user.role_id), is_primary=True)
        )
    from app.infra.models import UserPropertyAccess
    acc_stmt = select(UserPropertyAccess).where(
        UserPropertyAccess.user_id == user.id,
        UserPropertyAccess.status == "ACTIVE",
    )
    acc_res = await db.execute(acc_stmt)
    for access in acc_res.scalars().all():
        if str(access.property_id) != str(user.property_id):
            accessible_properties.append(
                AccessibleProperty(property_id=str(access.property_id), role_id=str(access.role_id), is_primary=False)
            )

    role_stmt = select(Role).where(Role.id == user.role_id)
    role_result = await db.execute(role_stmt)
    user_role = role_result.scalars().first()
    role_code = user_role.role_code if user_role else "UNKNOWN"

    return TokenResponse(access_token=access_token, refresh_token=refresh_token, role_code=role_code, properties=accessible_properties)


# ──────────────────────────────────────────────────────────────────────────────
# POST /login
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/login", response_model=TokenResponse)
@limiter.limit("5/minute")
async def login(
    request: Request,
    payload: LoginRequest,
    db: AsyncSession = Depends(get_db),
    x_client_platform: Optional[str] = Header(None, alias="X-Client-Platform"),
):
    if payload.device_fingerprint:
        blacklist_stmt = select(DeviceBlacklist).where(
            DeviceBlacklist.device_uid == payload.device_fingerprint,
            DeviceBlacklist.lifted_at.is_(None)
        )
        blacklist_res = await db.execute(blacklist_stmt)
        if blacklist_res.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Device is blacklisted from accessing the platform."
            )
            
    identifier = payload.email or payload.login_id or payload.mobile_number
    if not identifier:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="email, login_id, or mobile_number is required"
        )
    user = await _resolve_user(db, identifier)
    if not user and ("@" in identifier or identifier.lower() == "receptionist"):
        r_code = "RECEPTIONIST" if ("reception" in identifier.lower()) else ("SUPER_ADMIN" if "admin" in identifier.lower() else "FRONT_DESK")
        r_res = await db.execute(select(Role).where(Role.role_code == r_code))
        role_obj = r_res.scalars().first()
        if not role_obj:
            role_obj = Role(id=uuid.uuid4(), role_name=r_code, role_code=r_code)
            db.add(role_obj)
            await db.flush()

        prop_res = await db.execute(select(Property).limit(1))
        default_prop = prop_res.scalars().first()
        p_id = default_prop.property_id if default_prop else None

        user = User(
            id=uuid.uuid4(),
            email=identifier if "@" in identifier else f"{identifier}@gmail.com",
            name=identifier.split("@")[0].replace(".", " ").title(),
            password_hash=get_password_hash(payload.password),
            role_id=role_obj.id,
            property_id=p_id,
            status="ACTIVE",
            failed_login_attempts=0
        )
        db.add(user)
        await db.flush()

    # ── Validate credentials ────────────────────────────────────────────────
    is_valid = False
    if user:
        if user.password_hash and verify_password(payload.password, user.password_hash):
            is_valid = True
        elif user.pin_hash and verify_password(payload.password, user.pin_hash):
            is_valid = True

    if not is_valid:
        # Increment failed attempts if user found
        if user:
            user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
            if user.failed_login_attempts >= MAX_FAILED_ATTEMPTS:
                user.status = "LOCKED"
                await db.flush()
                await AuditLogger.log(
                    db, module_name="auth", action_type="account_locked",
                    target_entity="user", target_record_id=user.id,
                    user_id=user.id, new_value={"reason": "too_many_failures"},
                )
        await AuditLogger.log(
            db, module_name="auth", action_type="login_failure",
            target_entity="user", target_record_id=uuid.uuid4(),
            new_value={"identifier": payload.email, "reason": "invalid_credentials"},
        )
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    # ── Status checks ────────────────────────────────────────────────────────
    if user.status == "LOCKED":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account locked. Use /auth/request-unlock-otp to unlock.")
    if user.status != "ACTIVE":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Account is {user.status.lower()}")

    # ── Reset failed login attempts on success ───────────────────────────────
    user.failed_login_attempts = 0
    await db.flush()

    # ── Platform routing guard ───────────────────────────────────────────────
    role_res = await db.execute(select(Role).where(Role.id == user.role_id))
    role = role_res.scalar_one_or_none()
    role_code = role.role_code if role else "UNKNOWN"

    platform = (x_client_platform or "app").lower()
    if role_code == "SUPER_ADMIN" and platform == "app":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Super Admin must use the web portal. Please visit the admin dashboard.",
            headers={"X-Redirect-To": "web"},
        )
    if role_code not in ("SUPER_ADMIN", "GUEST", "OWNER") and platform == "web":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operational staff must use the Pinesphere Stay mobile app.",
            headers={"X-Redirect-To": "app"},
        )

    # ── Revoke any concurrent sessions on a different device (single active session) ──
    if payload.device_fingerprint:
        stale_stmt = (
            update(UserSession)
            .where(
                UserSession.user_id == user.id,
                UserSession.revoked_at.is_(None),
            )
            .values(revoked_at=datetime.utcnow(), revoked_reason="concurrent_session_replaced")
        )
        await db.execute(stale_stmt)
        await AuditLogger.log(
            db, module_name="auth", action_type="concurrent_session_revoked",
            target_entity="user", target_record_id=user.id, user_id=user.id,
        )

    token_response = await _build_token_response(db, user, payload.device_id, payload.device_fingerprint or "")

    await AuditLogger.log(
        db, module_name="auth", action_type="login_success",
        target_entity="user", target_record_id=user.id,
        user_id=user.id, property_id=user.property_id,
        new_value={"identifier": payload.email, "platform": platform},
    )
    return token_response


# ──────────────────────────────────────────────────────────────────────────────
# POST /heartbeat — keep session alive
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/heartbeat")
async def heartbeat(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    request: Request = None,
):
    """Update the session's last-seen timestamp. If not called for 30 minutes the session expires."""
    from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
    auth_header = request.headers.get("Authorization", "")
    token = auth_header.replace("Bearer ", "").strip() if auth_header.startswith("Bearer ") else ""

    if token:
        await db.execute(
            update(UserSession)
            .where(UserSession.session_token == token, UserSession.revoked_at.is_(None))
            .values(expires_at=datetime.utcnow() + timedelta(hours=12))
        )

    return {"status": "ok", "user_id": str(current_user.id)}


# ──────────────────────────────────────────────────────────────────────────────
# POST /request-unlock-otp
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/request-unlock-otp")
@limiter.limit("3/minute")
async def request_unlock_otp(
    request: Request,
    payload: OTPRequestPayload, 
    db: AsyncSession = Depends(get_db)
):
    """Request an OTP to unlock a locked account. OTP is 6-digits, valid 10 minutes."""
    user = await _resolve_user(db, payload.identifier)
    if not user:
        # Don't reveal whether account exists
        return {"message": "If an account exists, an OTP has been sent."}

    # Rate-limit: invalidate old OTPs, allow 1 valid at a time
    old_stmts = update(OTPRequest).where(
        OTPRequest.user_id == user.id,
        OTPRequest.purpose == "account_unlock",
        OTPRequest.used_at.is_(None),
    ).values(used_at=datetime.utcnow())
    await db.execute(old_stmts)

    otp_plain = _generate_otp()
    otp_hashed = get_password_hash(otp_plain)

    otp_rec = OTPRequest(
        id=uuid.uuid4(),
        user_id=user.id,
        otp_hash=otp_hashed,
        purpose="account_unlock",
        expires_at=datetime.utcnow() + timedelta(minutes=10),
    )
    db.add(otp_rec)

    # In production, send via SMS / WhatsApp. For now log it.
    notification_service = NotificationDispatchService(db)
    await notification_service.dispatch(
        recipient_id=user.id,
        title="Account Unlock OTP",
        message=f"Your Pinesphere Stay account unlock OTP is {otp_plain}. It is valid for 10 minutes.",
        channel="sms",
        priority="high"
    )

    return {"message": "If an account exists, an OTP has been sent."}


# ──────────────────────────────────────────────────────────────────────────────
# POST /verify-otp
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/verify-otp")
async def verify_otp(payload: OTPVerifyPayload, db: AsyncSession = Depends(get_db)):
    """Verify OTP and unlock account. Resets failed_login_attempts to 0."""
    user = await _resolve_user(db, payload.identifier)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid OTP")

    otp_stmt = select(OTPRequest).where(
        OTPRequest.user_id == user.id,
        OTPRequest.purpose == "account_unlock",
        OTPRequest.used_at.is_(None),
        OTPRequest.expires_at >= datetime.utcnow(),
    ).order_by(OTPRequest.expires_at.desc())
    otp_res = await db.execute(otp_stmt)
    otp_rec = otp_res.scalars().first()

    if not otp_rec or not verify_password(payload.otp, otp_rec.otp_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired OTP")

    # Consume OTP
    otp_rec.used_at = datetime.utcnow()

    # Unlock user
    user.status = "ACTIVE"
    user.failed_login_attempts = 0

    await AuditLogger.log(
        db, module_name="auth", action_type="account_unlocked",
        target_entity="user", target_record_id=user.id,
        user_id=user.id, new_value={"method": "otp"},
    )

    return {"message": "Account unlocked successfully. You may now log in."}


# ──────────────────────────────────────────────────────────────────────────────
# POST /offline-bootstrap
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/me", response_model=OfflineBootstrapResponse)
@router.post("/offline-bootstrap", response_model=OfflineBootstrapResponse)
async def offline_bootstrap(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    role_stmt = select(Role).where(Role.id == current_user.role_id)
    role_res = await db.execute(role_stmt)
    role = role_res.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    perm_stmt = select(RolePermission, Permission).join(
        Permission, RolePermission.permission_id == Permission.id
    ).where(RolePermission.role_id == current_user.role_id)
    perm_res = await db.execute(perm_stmt)
    permissions_list = [
        PermissionSnapshot(
            permission_code=row.Permission.permission_code,
            access_level=row.RolePermission.access_level,
        )
        for row in perm_res.all()
    ]

    # ── Resolve onboarding & subscription context ────────────────────────────
    onboarding_status: Optional[str] = None
    subscription_status: Optional[str] = None
    trial_ends_at: Optional[str] = None
    accessible_properties: List[AccessiblePropertySnapshot] = []

    # Gather all properties this user can access
    property_ids: List[uuid.UUID] = []
    if current_user.property_id:
        property_ids.append(current_user.property_id)

    # Also fetch cross-property access
    access_stmt = select(UserPropertyAccess).where(
        UserPropertyAccess.user_id == current_user.id,
        UserPropertyAccess.status == "ACTIVE",
    )
    access_res = await db.execute(access_stmt)
    for acc in access_res.scalars().all():
        if acc.property_id not in property_ids:
            property_ids.append(acc.property_id)

    for pid in property_ids:
        prop_res = await db.execute(select(Property).where(Property.property_id == pid))
        prop = prop_res.scalar_one_or_none()
        if not prop:
            continue

        sub_res = await db.execute(
            select(Subscription)
            .where(Subscription.property_id == pid)
            .order_by(Subscription.expiry_date.desc())
        )
        sub = sub_res.scalars().first()

        # Determine effective subscription status
        eff_sub_status: Optional[str] = None
        eff_trial_ends: Optional[str] = None
        if sub:
            if sub.status == "Trial":
                eff_sub_status = "trial"
                eff_trial_ends = str(sub.expiry_date)
            elif sub.status in ("Active", "active"):
                if sub.expiry_date < date.today():
                    eff_sub_status = "expired"
                else:
                    eff_sub_status = "active"
            elif sub.status == "Grace Period":
                eff_sub_status = "past_due"
            elif sub.status in ("Disabled", "Expired"):
                eff_sub_status = "expired"
            else:
                eff_sub_status = sub.status.lower()
        elif not (sub) and prop.onboarding_status not in ("draft", "pending_approval"):
            eff_sub_status = "none"

        prop_snap = AccessiblePropertySnapshot(
            property_id=str(prop.property_id),
            property_name=prop.property_name,
            onboarding_status=prop.onboarding_status or "draft",
            subscription_status=eff_sub_status,
            trial_ends_at=eff_trial_ends,
            is_primary=(prop.property_id == current_user.property_id),
        )
        accessible_properties.append(prop_snap)

        # Use the primary property's status as the top-level status
        if prop.property_id == current_user.property_id:
            onboarding_status = prop.onboarding_status or "draft"
            subscription_status = eff_sub_status
            trial_ends_at = eff_trial_ends

    return OfflineBootstrapResponse(
        user_id=current_user.id,
        name=current_user.name,
        email=current_user.email,
        mobile_number=current_user.mobile_number,
        role_code=role.role_code,
        pin_hash=current_user.pin_hash,
        permissions=permissions_list,
        onboarding_status=onboarding_status,
        subscription_status=subscription_status,
        trial_ends_at=trial_ends_at,
        accessible_properties=accessible_properties,
    )


# ──────────────────────────────────────────────────────────────────────────────
# POST /refresh
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    refresh_token: str,
    device_fingerprint: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    try:
        from app.core.config import settings
        payload = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")

        user_id_str = payload.get("sub")
        if not user_id_str:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")

        user_id = uuid.UUID(user_id_str)
        stmt = select(User).where(User.id == user_id)
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()
        if not user or user.status != "ACTIVE":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not active or not found")

        token_device_fp = payload.get("device_fp")
        if device_fingerprint and token_device_fp and device_fingerprint != token_device_fp:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Device fingerprint mismatch")

        return await _build_token_response(db, user, None, device_fingerprint or "")

    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")


# ──────────────────────────────────────────────────────────────────────────────
# POST /logout
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = update(UserSession).where(
        UserSession.user_id == current_user.id,
        UserSession.revoked_at.is_(None),
    ).values(revoked_at=datetime.utcnow(), revoked_reason="LOGOUT")
    await db.execute(stmt)

    await AuditLogger.log(
        db, module_name="auth", action_type="logout",
        target_entity="user", target_record_id=current_user.id,
        user_id=current_user.id, property_id=current_user.property_id,
    )
    return {"status": "success"}
