from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class OwnerRegistrationRequest(BaseModel):
    # Owner Details
    owner_name: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    mobile_number: str = Field(..., min_length=10, max_length=15)
    password: str = Field(..., min_length=8)

    # Business/Property Details
    business_name: str = Field(..., min_length=2, max_length=150)
    property_name: str = Field(..., min_length=2, max_length=150)
    property_type: str = Field(default="HOTEL")
    star_category: int = Field(default=3)

class OwnerRegistrationResponse(BaseModel):
    success: bool
    message: str
    owner_id: str
    property_id: str
    user_id: str
