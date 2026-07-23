from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import uuid

class DeviceRegisterRequest(BaseModel):
    property_id: uuid.UUID = Field(..., description="Target property ID")
    activation_code: Optional[str] = Field(None, description="Onboarding / WhatsApp welcome code")
    device_uid: str = Field(..., max_length=128, description="Hashed Android ID or IMEI")
    device_name: Optional[str] = Field(None, max_length=80, description="Display label or device name")
    device_model: Optional[str] = Field(None, max_length=80, description="Hardware model e.g. Samsung M35")
    os_type: str = Field("android", max_length=20)
    os_version: Optional[str] = Field(None, max_length=20)
    app_version: Optional[str] = Field(None, max_length=20)

class DeviceActivateRequest(BaseModel):
    device_uid: str

class DeviceActivateResponse(BaseModel):
    device_id: uuid.UUID
    device_uid: str
    property_id: uuid.UUID
    status: str
    license_code: str
    expiry_date: str
    device_count_allowed: int
    digital_signature: str
    token_payload: str
    issued_at: datetime

class DeviceActionRequest(BaseModel):
    action_type: str = Field(..., description="approve, reject, lock, unlock, disable, enable, logout, rename, transfer, revoke, force-sync")
    reason: Optional[str] = None
    new_name: Optional[str] = None
    transfer_to_user_id: Optional[uuid.UUID] = None

class DeviceTransferRequest(BaseModel):
    from_user_id: Optional[uuid.UUID] = None
    to_user_id: uuid.UUID
    reason: Optional[str] = None

class DeviceSyncCheckinRequest(BaseModel):
    device_uid: str
    battery_level: Optional[int] = Field(None, ge=0, le=100)
    last_sync_at: Optional[datetime] = None
    records_pushed: int = 0
    records_pulled: int = 0
    status: str = "success"
    error_message: Optional[str] = None

class DeviceSyncCheckinResponse(BaseModel):
    status: str
    server_time: datetime
    pending_remote_command: Optional[str] = None # LOGOUT, LOCK, REVOKE_AND_ERASE, NONE
    remote_command_reason: Optional[str] = None

class DeviceResponse(BaseModel):
    id: uuid.UUID
    device_uid: str
    property_id: Optional[uuid.UUID] = None
    primary_user_id: Optional[uuid.UUID] = None
    primary_user_name: Optional[str] = None
    device_name: Optional[str] = None
    manufacturer: Optional[str] = None
    device_type: Optional[str] = None
    platform: Optional[str] = None
    os_type: Optional[str] = None
    os_version: Optional[str] = None
    browser_name: Optional[str] = None
    browser_version: Optional[str] = None
    app_version: Optional[str] = None
    build_number: Optional[str] = None
    is_trusted: bool = False
    first_login_at: Optional[datetime] = None
    last_login_at: Optional[datetime] = None
    login_count: int = 0
    status: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    # Virtual / denormalized fields from audit / tracking
    last_sync_at: Optional[datetime] = None
    sync_status: str = "synced"
    battery_level: Optional[int] = None
    approval_status: str = "pending"

    class Config:
        from_attributes = True

class DeviceDetailResponse(DeviceResponse):
    device_model: Optional[str] = None
    os_version: Optional[str] = None
    app_version: Optional[str] = None
    last_login_at: Optional[datetime] = None
    session_history_count: int = 0
    recent_sync_count: int = 0

class AuditLogEntryResponse(BaseModel):
    log_id: uuid.UUID
    property_id: Optional[uuid.UUID] = None
    user_id: Optional[uuid.UUID] = None
    timestamp: datetime
    module_name: Optional[str] = None
    action_type: Optional[str] = None
    target_entity: Optional[str] = None
    target_record_id: Optional[uuid.UUID] = None
    old_value_snapshot: Optional[Dict[str, Any]] = None
    new_value_snapshot: Optional[Dict[str, Any]] = None

    class Config:
        from_attributes = True

class SyncLogEntryResponse(BaseModel):
    log_id: uuid.UUID
    device_id: uuid.UUID
    timestamp: datetime
    sync_type: str = "full"
    status: str = "success"
    records_pushed: int = 0
    records_pulled: int = 0
    conflict_count: int = 0
    error_message: Optional[str] = None
