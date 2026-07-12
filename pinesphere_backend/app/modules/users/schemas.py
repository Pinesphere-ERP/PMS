import uuid
from typing import Optional
from pydantic import BaseModel, Field

class RoleResponse(BaseModel):
    id: uuid.UUID
    role_code: str
    role_name: str
    description: Optional[str] = None
    level: int

    class Config:
        from_attributes = True

class UserCreate(BaseModel):
    name: str = Field(..., max_length=120)
    mobile_number: str = Field(..., max_length=15)
    role_id: uuid.UUID
    email: Optional[str] = Field(None, max_length=120)
    username: Optional[str] = Field(None, max_length=60)
    password: Optional[str] = None
    pin: Optional[str] = None

class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=120)
    email: Optional[str] = Field(None, max_length=120)
    role_id: Optional[uuid.UUID] = None
    status: Optional[str] = None # ACTIVE, INACTIVE, LOCKED, SUSPENDED

class UserResponse(BaseModel):
    id: uuid.UUID
    property_id: Optional[uuid.UUID] = None
    role_id: uuid.UUID
    name: str
    mobile_number: Optional[str] = None
    email: Optional[str] = None
    username: Optional[str] = None
    is_primary_owner: bool
    status: str
    is_pending_sync: bool

    class Config:
        from_attributes = True
