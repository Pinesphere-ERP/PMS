from pydantic import BaseModel
from typing import Optional
import uuid

class LoginRequest(BaseModel):
    email: Optional[str] = None
    login_id: Optional[str] = None
    mobile_number: Optional[str] = None
    password: str
    property_id: Optional[uuid.UUID] = None
    device_uid: Optional[str] = None

class AccessibleProperty(BaseModel):
    property_id: str
    role_id: str
    is_primary: bool

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role_code: str
    properties: list[AccessibleProperty] = []

class OfflineBootstrapRequest(BaseModel):
    device_uid: str
    user_id: uuid.UUID

class RefreshRequest(BaseModel):
    refresh_token: str
    device_uid: str
