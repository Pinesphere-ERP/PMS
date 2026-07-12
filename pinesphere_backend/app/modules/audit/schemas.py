from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime
import uuid

class AuditLogResponse(BaseModel):
    id: uuid.UUID
    property_id: Optional[uuid.UUID]
    user_id: Optional[uuid.UUID]
    device_id: Optional[uuid.UUID]
    timestamp: datetime
    module_name: str
    action_type: str
    target_entity: str
    target_record_id: Optional[uuid.UUID]
    old_value_snapshot: Optional[Dict[str, Any]]
    new_value_snapshot: Optional[Dict[str, Any]]
    ip_address: Optional[str]
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import uuid


class AuditLogResponse(BaseModel):
    log_id: uuid.UUID
    property_id: Optional[uuid.UUID] = None
    user_id: Optional[uuid.UUID] = None
    device_id: Optional[str] = None
    timestamp: datetime
    module_name: Optional[str] = None
    action_type: Optional[str] = None
    target_entity: Optional[str] = None
    target_record_id: Optional[uuid.UUID] = None
    old_value_snapshot: Optional[dict] = None
    new_value_snapshot: Optional[dict] = None
    ip_address: Optional[str] = None
    previous_log_hash: Optional[str] = None
    entry_hash: Optional[str] = None

    class Config:
        from_attributes = True


class AuditLogListResponse(BaseModel):
    items: List[AuditLogResponse]
    total: int
    page: int
    size: int


class ChainVerificationResult(BaseModel):
    valid: bool
    total_entries: int
    verified_entries: int
    first_break_log_id: Optional[uuid.UUID] = None
    first_break_timestamp: Optional[datetime] = None
    message: str
