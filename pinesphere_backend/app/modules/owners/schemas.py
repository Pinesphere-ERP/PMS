from pydantic import BaseModel, EmailStr
from typing import Optional
import uuid


class OwnerCreateRequest(BaseModel):
    full_name: str
    mobile_number: str
    email: str
    designation: Optional[str] = None
    pan_number: Optional[str] = None
    aadhaar_number: Optional[str] = None
    alternate_contact: Optional[str] = None


class OwnerUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    mobile_number: Optional[str] = None
    email: Optional[str] = None
    designation: Optional[str] = None
    pan_number: Optional[str] = None
    aadhaar_number: Optional[str] = None
    alternate_contact: Optional[str] = None


class OwnerResponse(BaseModel):
    owner_id: uuid.UUID
    full_name: str
    mobile_number: str
    email: str
    designation: Optional[str] = None
    pan_number: Optional[str] = None
    aadhaar_number: Optional[str] = None
    alternate_contact: Optional[str] = None
    property_count: int = 0

    class Config:
        from_attributes = True
