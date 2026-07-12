from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
import uuid
from datetime import datetime

class SyncPayload(BaseModel):
    entity_type: str
    entity_id: str
    operation: str # CREATE, UPDATE, DELETE
    payload: Dict[str, Any]
    updated_at: datetime
    device_timestamp: datetime

class SyncPushRequest(BaseModel):
    device_uid: str
    property_id: uuid.UUID
    records: List[SyncPayload]

class SyncPushResponse(BaseModel):
    accepted_ids: List[str]
    conflicts: List[Dict[str, Any]]
    failed_ids: List[str]

class SyncPullRequest(BaseModel):
    device_uid: str
    property_id: uuid.UUID
    last_sync_timestamp: datetime

class SyncPullResponse(BaseModel):
    records: List[SyncPayload]
    server_timestamp: datetime
