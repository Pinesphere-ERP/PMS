from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Any

from src.infra.database import get_db
from src.domain.auth.models import User, Device, Tenant
from src.domain.auth.schemas import UserLogin, TokenResponse, DeviceRegistrationRequest, DeviceResponse
from src.core.security import verify_password, create_access_token, create_refresh_token

router = APIRouter()

@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin, db: AsyncSession = Depends(get_db)):
    # Find user
    stmt = select(User).where(User.email == credentials.email)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user")

    # Handle device registration/lookup
    device_stmt = select(Device).where(
        Device.fingerprint == credentials.device_fingerprint,
        Device.user_id == user.id
    )
    device_result = await db.execute(device_stmt)
    device = device_result.scalar_one_or_none()

    if not device:
        # First time login from this device, register it as untrusted
        device = Device(
            user_id=user.id,
            tenant_id=user.tenant_id,
            fingerprint=credentials.device_fingerprint,
            name=credentials.device_name,
            is_trusted=False # Must be approved by admin/owner
        )
        db.add(device)
        await db.commit()
        await db.refresh(device)
        
    if not device.is_trusted:
        # According to PDF: Every mobile must be registered and approved.
        # We allow login but restrict sync capabilities until trusted.
        pass 

    # Generate tokens
    access_token = create_access_token(
        user_id=str(user.id),
        tenant_id=str(user.tenant_id),
        device_fp=device.fingerprint
    )
    refresh_token = create_refresh_token(
        user_id=str(user.id),
        device_fp=device.fingerprint
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@router.post("/devices/register", response_model=DeviceResponse)
async def register_device(req: DeviceRegistrationRequest, db: AsyncSession = Depends(get_db)):
    # This endpoint could be used before login for strict MDM (Mobile Device Management)
    pass
