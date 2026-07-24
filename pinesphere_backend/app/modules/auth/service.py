import uuid
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status
import jwt

from app.infra.models import User, Device, DeviceLoginHistory
from app.core.security import verify_password, create_access_token, create_refresh_token
from app.core.config import settings
from .schemas import LoginRequest, TokenResponse, OfflineBootstrapRequest, RefreshRequest, DeviceTelemetry

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

    async def verify_device(self, device_uid: str, property_id: Optional[uuid.UUID], telemetry: Optional[DeviceTelemetry], user_id: uuid.UUID) -> Device:
        # We find device by uid
        if not device_uid:
            device_uid = str(uuid.uuid4()) # Fallback if not provided
            
        result = await self.db.execute(select(Device).filter(Device.device_uid == device_uid))
        device = result.scalars().first()
        
        from datetime import datetime, timezone
        now = datetime.now(timezone.utc).replace(tzinfo=None)

        if not device:
            device = Device(
                device_uid=device_uid,
                property_id=property_id,
                device_name="Auto-registered Device",
                status="active",
                first_login_at=now,
                login_count=1,
                last_login_at=now,
            )
            self.db.add(device)
        else:
            device.last_login_at = now
            device.login_count += 1
            if property_id and not device.property_id:
                device.property_id = property_id
        
        # Apply telemetry
        if telemetry:
            device.manufacturer = telemetry.manufacturer or device.manufacturer
            device.device_type = telemetry.device_type or device.device_type
            device.platform = telemetry.platform or device.platform
            device.os_version = telemetry.os_version or device.os_version
            device.browser_name = telemetry.browser_name or device.browser_name
            device.browser_version = telemetry.browser_version or device.browser_version
            device.app_version = telemetry.app_version or device.app_version
            device.build_number = telemetry.build_number or device.build_number

        await self.db.commit()
        await self.db.refresh(device)
        
        # Create Login History
        history = DeviceLoginHistory(
            user_id=user_id,
            device_id=device.id,
            login_timestamp=now,
            public_ip=telemetry.public_ip if telemetry else None,
            network_type=telemetry.network_type if telemetry else None,
            isp=telemetry.isp if telemetry else None,
            latitude=telemetry.latitude if telemetry else None,
            longitude=telemetry.longitude if telemetry else None,
            city=telemetry.city if telemetry else None,
            state=telemetry.state if telemetry else None,
            country=telemetry.country if telemetry else None,
            postal_code=telemetry.postal_code if telemetry else None,
            time_zone=telemetry.time_zone if telemetry else None,
        )
        self.db.add(history)
        await self.db.commit()

        if device.status not in ["active", "pending_approval"]:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Device is not active")
        return device

    async def login(self, login_data: LoginRequest) -> TokenResponse:
        user = await self.authenticate_user(login_data)
        device = await self.verify_device(login_data.device_uid, user.property_id, login_data.telemetry, user.id)
        
        access_token = create_access_token(
            user_id=str(user.id),
            tenant_id=str(user.property_id) if user.property_id else "",
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
