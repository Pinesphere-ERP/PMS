import uuid
from datetime import datetime, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, update
from sqlalchemy.orm import selectinload

from app.infra.database import get_db
from app.infra.models import User, Role, RolePermission, Permission, UserSession
from app.core.dependencies import get_current_user
from app.core.security import verify_password, create_access_token, create_refresh_token, get_password_hash
from app.modules.audit.logger import AuditLogger
import jwt

router = APIRouter()

class LoginRequest(BaseModel):
    email: str  # Can be email, username, or mobile number
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

@router.post("/login", response_model=TokenResponse)
async def login(
    payload: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    # Try finding user by email, username, or mobile
    stmt = select(User).options(selectinload(User.property_access)).where(
        or_(
            User.email == payload.email,
            User.username == payload.email,
            User.mobile_number == payload.email
        )
    )
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    # Password validation (checking password_hash or pin_hash depending on what matches)
    is_valid = False
    if user:
        if user.password_hash and verify_password(payload.password, user.password_hash):
            is_valid = True
        elif user.pin_hash and verify_password(payload.password, user.pin_hash):
            is_valid = True

    if not is_valid:
        await AuditLogger.log(
            db,
            module_name="auth",
            action_type="login_failure",
            target_entity="user",
            target_record_id=uuid.uuid4(),
            new_value={"identifier": payload.email, "reason": "invalid_credentials"},
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )

    if user.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"User account is {user.status.lower()}"
        )

    # Generate tokens
    access_token = create_access_token(
        user_id=str(user.id),
        tenant_id=str(user.property_id or ""),
        device_fp=payload.device_fingerprint or ""
    )
    refresh_token = create_refresh_token(
        user_id=str(user.id),
        device_fp=payload.device_fingerprint or ""
    )

    # Track session in database
    device_id = None
    if payload.device_id:
        try:
            device_id = uuid.UUID(payload.device_id)
        except ValueError:
            pass

    session = UserSession(
        id=uuid.uuid4(),
        user_id=user.id,
        device_id=device_id or uuid.uuid4(),  # fallback if no valid device_id
        session_token=access_token,
        is_offline_session=False,
        expires_at=datetime.utcnow() + timedelta(days=1)
    )
    db.add(session)
    await db.flush()

    await AuditLogger.log(
        db,
        module_name="auth",
        action_type="login_success",
        target_entity="user",
        target_record_id=user.id,
        user_id=user.id,
        property_id=user.property_id,
        new_value={"identifier": payload.email},
    )

    accessible_properties = []
    if user.property_id:
        accessible_properties.append(
            AccessibleProperty(
                property_id=str(user.property_id),
                role_id=str(user.role_id),
                is_primary=True
            )
        )
    
    for access in user.property_access:
        if access.status == "ACTIVE" and str(access.property_id) != str(user.property_id):
            accessible_properties.append(
                AccessibleProperty(
                    property_id=str(access.property_id),
                    role_id=str(access.role_id),
                    is_primary=False
                )
            )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        properties=accessible_properties
    )

@router.post("/offline-bootstrap", response_model=OfflineBootstrapResponse)
async def offline_bootstrap(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Fetch user's role
    role_stmt = select(Role).where(Role.id == current_user.role_id)
    role_res = await db.execute(role_stmt)
    role = role_res.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")
        
    # Fetch role permissions
    perm_stmt = select(RolePermission, Permission).join(
        Permission, RolePermission.permission_id == Permission.id
    ).where(RolePermission.role_id == current_user.role_id)
    perm_res = await db.execute(perm_stmt)
    rows = perm_res.all()
    
    permissions_list = [
        PermissionSnapshot(
            permission_code=row.Permission.permission_code,
            access_level=row.RolePermission.access_level
        )
        for row in rows
    ]
    
    return OfflineBootstrapResponse(
        user_id=current_user.id,
        name=current_user.name,
        mobile_number=current_user.mobile_number,
        role_code=role.role_code,
        pin_hash=current_user.pin_hash,
        permissions=permissions_list
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    refresh_token: str,
    device_fingerprint: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    # For now, simulate token refresh by returning a fresh set of tokens if signature checks out
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
            
        new_access = create_access_token(
            user_id=str(user.id),
            tenant_id=str(user.property_id or ""),
            device_fp=device_fingerprint or ""
        )
        new_refresh = create_refresh_token(
            user_id=str(user.id),
            device_fp=device_fingerprint or ""
        )
        
        return TokenResponse(
            access_token=new_access,
            refresh_token=new_refresh
        )
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Invalidate current session
    stmt = update(UserSession).where(
        UserSession.user_id == current_user.id,
        UserSession.revoked_at.is_(None)
    ).values(revoked_at=datetime.utcnow(), revoked_reason="LOGOUT")
    await db.execute(stmt)
    
    await AuditLogger.log(
        db,
        module_name="auth",
        action_type="logout",
        target_entity="user",
        target_record_id=current_user.id,
        user_id=current_user.id,
        property_id=current_user.active_property_id,
    )
    return {"status": "success"}
