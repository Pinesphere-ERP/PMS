import uuid
import random
import string
from datetime import datetime, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Header, status, Request
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, update

from app.infra.database import get_db
from app.infra.models import User, Role, RolePermission, Permission, UserSession, OTPRequest, DeviceBlacklist, Device
from app.core.dependencies import get_current_user
from app.core.security import verify_password, create_access_token, create_refresh_token, get_password_hash
from app.modules.audit.logger import AuditLogger
from app.modules.notifications.service import NotificationDispatchService
import jwt

router = APIRouter()

MAX_FAILED_ATTEMPTS = 5
SESSION_HEARTBEAT_TIMEOUT_MINUTES = 30

# ──────────────────────────────────────────────────────────────────────────────
# Request / Response Schemas
# ──────────────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: str
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

class OfflineBootstrapResponse(BaseModel):
    user_id: uuid.UUID
    name: str
    mobile_number: Optional[str] = None
    role_code: str
    pin_hash: Optional[str] = None
    permissions: List[PermissionSnapshot]

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
async def login(
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
            
    user = await _resolve_user(db, payload.email)

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
async def request_unlock_otp(payload: OTPRequestPayload, db: AsyncSession = Depends(get_db)):
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

    return OfflineBootstrapResponse(
        user_id=current_user.id,
        name=current_user.name,
        mobile_number=current_user.mobile_number,
        role_code=role.role_code,
        pin_hash=current_user.pin_hash,
        permissions=permissions_list,
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
