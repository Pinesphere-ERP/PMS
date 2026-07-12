import uuid
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status
import jwt

from app.infra.models import User, Device
from app.core.security import verify_password, create_access_token, create_refresh_token
from app.core.config import settings
from .schemas import LoginRequest, TokenResponse, OfflineBootstrapRequest, RefreshRequest

class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def authenticate_user(self, login_data: LoginRequest) -> User:
        query = select(User).filter(User.email == login_data.email)
        if login_data.property_id:
            query = query.filter(User.property_id == login_data.property_id)
            
        result = await self.db.execute(query)
        user = result.scalars().first()
        
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
            
        if not verify_password(login_data.password, user.password_hash):
            user.failed_login_attempts += 1
            if user.failed_login_attempts >= 5:
                user.status = "LOCKED"
            await self.db.commit()
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
            
        if user.status != "ACTIVE":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"User account is {user.status}")
            
        # Reset failed attempts
        if user.failed_login_attempts > 0:
            user.failed_login_attempts = 0
            await self.db.commit()
            
        return user

    async def verify_device(self, device_uid: str, property_id: uuid.UUID) -> Device:
        result = await self.db.execute(select(Device).filter(
            Device.device_uid == device_uid,
            Device.property_id == property_id
        ))
        device = result.scalars().first()
        if not device:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unregistered device")
        if device.status not in ["active", "pending_approval"]:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Device is not active")
        return device

    async def login(self, login_data: LoginRequest) -> TokenResponse:
        user = await self.authenticate_user(login_data)
        device = await self.verify_device(login_data.device_uid, user.property_id)
        
        access_token = create_access_token(
            user_id=str(user.id),
            tenant_id=str(user.property_id),
            device_fp=device.device_uid
        )
        refresh_token = create_refresh_token(
            user_id=str(user.id),
            device_fp=device.device_uid
        )
        
        return TokenResponse(access_token=access_token, refresh_token=refresh_token)

    async def refresh_token(self, request: RefreshRequest) -> TokenResponse:
        try:
            payload = jwt.decode(request.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            user_id_str = payload.get("sub")
            device_fp = payload.get("device_fp")
            
            if not user_id_str or device_fp != request.device_uid:
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
                
            result = await self.db.execute(select(User).filter(User.id == uuid.UUID(user_id_str)))
            user = result.scalars().first()
            
            if not user or user.status != "ACTIVE":
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User inactive or not found")
                
            access_token = create_access_token(
                user_id=str(user.id),
                tenant_id=str(user.property_id),
                device_fp=device_fp
            )
            refresh_token = create_refresh_token(
                user_id=str(user.id),
                device_fp=device_fp,
                family_id=payload.get("family")
            )
            
            return TokenResponse(access_token=access_token, refresh_token=refresh_token)
            
        except jwt.PyJWTError:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
