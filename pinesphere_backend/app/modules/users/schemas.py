from pydantic import BaseModel, EmailStr, Field
from typing import Optional
import uuid
from datetime import datetime

class UserCreateRequest(BaseModel):
    name: str
    email: Optional[EmailStr] = None
    mobile_number: str
    password: str = Field(..., min_length=6)
    username: Optional[str] = None
    role_id: Optional[uuid.UUID] = None
    role_code: Optional[str] = None
    property_id: Optional[uuid.UUID] = None

class UserResponse(BaseModel):
    id: uuid.UUID
    name: str
    email: Optional[str]
    mobile_number: Optional[str]
    username: Optional[str]
    status: str
    role_id: uuid.UUID
    property_id: Optional[uuid.UUID]
    is_primary_owner: bool = False
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    mobile_number: Optional[str] = None
    status: Optional[str] = None
    role_id: Optional[uuid.UUID] = None

class RoleResponse(BaseModel):
    id: uuid.UUID
    property_id: Optional[uuid.UUID]
    role_code: str
    role_name: str
    is_system_role: bool
    description: Optional[str]
    
    class Config:
        from_attributes = True

