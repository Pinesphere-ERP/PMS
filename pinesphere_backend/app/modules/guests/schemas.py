import uuid
from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr

class GuestCreateInput(BaseModel):
    first_name: str
    last_name: str
    mobile_number: str
    email: Optional[EmailStr] = None
    gender: Optional[str] = None
    dob: Optional[date] = None
    nationality: Optional[str] = "Indian"
    address: Optional[str] = None
    id_type: Optional[str] = None
    id_number: Optional[str] = None
    gst_number: Optional[str] = None
    company_name: Optional[str] = None

class GuestResponse(BaseModel):
    guest_id: uuid.UUID
    first_name: str
    last_name: str
    mobile_number: str
    email: Optional[str]
    gender: Optional[str]
    dob: Optional[date]
    nationality: Optional[str]
    address: Optional[str]
    id_type: Optional[str]
    id_number: Optional[str]
    is_vip: bool
    is_blacklisted: bool
    notes: Optional[str]
    gst_number: Optional[str]
    company_name: Optional[str]
    total_stays: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class GuestUpdateInput(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    mobile_number: Optional[str] = None
    email: Optional[EmailStr] = None
    address: Optional[str] = None
    id_type: Optional[str] = None
    id_number: Optional[str] = None
    is_vip: Optional[bool] = None
    is_blacklisted: Optional[bool] = None
    notes: Optional[str] = None
