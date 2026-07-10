from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from uuid import UUID
from datetime import datetime

class UserLogin(BaseModel):
    email: EmailStr
    password: str
    device_id: str
    device_name: str
    device_fingerprint: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    
class OfflineLicense(BaseModel):
    property_id: UUID
    device_id: UUID
    valid_until: datetime
    features: list[str]
    signature: str

class DeviceRegistrationRequest(BaseModel):
    device_fingerprint: str
    device_name: str
    android_version: Optional[str] = None
    app_version: Optional[str] = None

class DeviceResponse(BaseModel):
    id: UUID
    name: str
    is_trusted: bool
    last_active: Optional[str] = None
