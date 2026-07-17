import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel

class TaskCreate(BaseModel):
    task_type: str
    priority: str = "normal"
    room_id: Optional[str] = None
    booking_id: Optional[str] = None
    description: Optional[str] = None
    due_at: Optional[datetime] = None

class TaskResponse(BaseModel):
    task_id: uuid.UUID
    task_type: str
    status: str
    priority: str
    room_id: Optional[uuid.UUID]
    booking_id: Optional[uuid.UUID]
    assigned_to: Optional[uuid.UUID]
    description: Optional[str]
    due_at: Optional[datetime]
    completed_at: Optional[datetime]
    photos: Optional[str]
    remarks: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class TaskStatusUpdate(BaseModel):
    status: str
    notes: Optional[str] = None
    photos: Optional[str] = None
    remarks: Optional[str] = None
