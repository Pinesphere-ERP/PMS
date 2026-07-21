from pydantic import BaseModel, Field, validator
from typing import Optional
from datetime import datetime
import uuid

class ServiceRequestBase(BaseModel):
    property_id: uuid.UUID
    booking_id: Optional[uuid.UUID] = None
    room_id: Optional[uuid.UUID] = None
    request_category: str = Field(..., max_length=30)
    title: str = Field(..., max_length=150)
    description: Optional[str] = None
    priority: str = Field(default='normal', max_length=20)
    
class ServiceRequestCreate(ServiceRequestBase):
    requested_by_guest_id: Optional[uuid.UUID] = None
    requested_by_user_id: Optional[uuid.UUID] = None
    
    @validator('requested_by_user_id', always=True)
    def check_creator(cls, v, values):
        guest_id = values.get('requested_by_guest_id')
        if not v and not guest_id:
            raise ValueError('Either requested_by_guest_id or requested_by_user_id must be provided')
        if v and guest_id:
            raise ValueError('Cannot provide both requested_by_guest_id and requested_by_user_id')
        return v

class ServiceRequestAssign(BaseModel):
    assigned_to: uuid.UUID

class ServiceRequestComplete(BaseModel):
    completion_photo_url: Optional[str] = None
    remarks: Optional[str] = None

class ServiceRequestVerify(BaseModel):
    manager_verified: bool = True
    remarks: Optional[str] = None

class ServiceRequestResponse(ServiceRequestBase):
    request_id: uuid.UUID
    requested_by_guest_id: Optional[uuid.UUID] = None
    requested_by_user_id: Optional[uuid.UUID] = None
    status: str
    assigned_to: Optional[uuid.UUID] = None
    assigned_at: Optional[datetime] = None
    completed_by: Optional[uuid.UUID] = None
    completed_at: Optional[datetime] = None
    completion_photo_url: Optional[str] = None
    manager_verified: bool
    verified_by: Optional[uuid.UUID] = None
    verified_at: Optional[datetime] = None
    remarks: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True
        from_attributes = True
