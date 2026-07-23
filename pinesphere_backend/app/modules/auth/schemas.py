from pydantic import BaseModel
from typing import Optional
import uuid

class DeviceTelemetry(BaseModel):
    manufacturer: Optional[str] = None
    device_type: Optional[str] = None
    platform: Optional[str] = None
    os_version: Optional[str] = None
    browser_name: Optional[str] = None
    browser_version: Optional[str] = None
    app_version: Optional[str] = None
    build_number: Optional[str] = None
    public_ip: Optional[str] = None
    network_type: Optional[str] = None
    isp: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None
    time_zone: Optional[str] = None

class LoginRequest(BaseModel):
    email: Optional[str] = None
    login_id: Optional[str] = None
    mobile_number: Optional[str] = None
    password: str
    property_id: Optional[uuid.UUID] = None
    device_uid: Optional[str] = None
    telemetry: Optional[DeviceTelemetry] = None

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
