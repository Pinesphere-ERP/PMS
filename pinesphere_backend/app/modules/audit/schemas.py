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

class AuditLogListResponse(BaseModel):
    items: List[AuditLogResponse]
    total: int
    page: int
    size: int
