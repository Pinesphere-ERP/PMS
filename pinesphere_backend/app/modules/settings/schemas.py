from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid


# ── System Configuration ───────────────────────────────────────

class SystemConfigCreateRequest(BaseModel):
    config_key: str = Field(..., max_length=100)
    config_value: str
    description: Optional[str] = None

class SystemConfigUpdateRequest(BaseModel):
    config_value: str
    description: Optional[str] = None

class SystemConfigResponse(BaseModel):
    id: uuid.UUID
    config_key: str
    config_value: str
    description: Optional[str] = None
    updated_by: Optional[uuid.UUID] = None
    updated_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class SystemConfigListResponse(BaseModel):
    items: list[SystemConfigResponse]
    total: int


# ── Property Setting ───────────────────────────────────────────

class PropertySettingCreateRequest(BaseModel):
    setting_key: str = Field(..., max_length=100)
    setting_value: str
    value_type: str = Field("string", pattern="^(string|number|boolean|json)$")
    description: Optional[str] = None

class PropertySettingUpdateRequest(BaseModel):
    setting_value: str
    value_type: Optional[str] = Field(None, pattern="^(string|number|boolean|json)$")
    description: Optional[str] = None

class PropertySettingResponse(BaseModel):
    id: uuid.UUID
    property_id: uuid.UUID
    setting_key: str
    setting_value: str
    value_type: str
    description: Optional[str] = None
    updated_by: Optional[uuid.UUID] = None
    version: int
    updated_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class PropertySettingListResponse(BaseModel):
    items: list[PropertySettingResponse]
    total: int

class PropertySettingBulkUpdateRequest(BaseModel):
    settings: list[PropertySettingCreateRequest]
