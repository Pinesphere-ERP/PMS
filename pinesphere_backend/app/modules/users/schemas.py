from pydantic import BaseModel, EmailStr, Field
from typing import Optional
import uuid
from datetime import datetime

class UserCreateRequest(BaseModel):
    name: str
    email: EmailStr
    mobile_number: str
    password: str = Field(..., min_length=8)
    role_id: uuid.UUID

class UserResponse(BaseModel):
    id: uuid.UUID
    name: str
    email: Optional[str]
    mobile_number: Optional[str]
    status: str
    role_id: uuid.UUID
    property_id: Optional[uuid.UUID]
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    mobile_number: Optional[str] = None
    status: Optional[str] = None
    role_id: Optional[uuid.UUID] = None
