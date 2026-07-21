from pydantic import BaseModel, EmailStr, Field
from typing import Optional, Literal

PROPERTY_TYPES = Literal[
    "HOTEL", "RESORT", "HOSTEL", "GUESTHOUSE", "MOTEL",
    "BOUTIQUE_HOTEL", "SERVICE_APARTMENT", "VILLA", "FARMHOUSE", "OTHER"
]

class OwnerRegistrationRequest(BaseModel):
    # Owner Details
    owner_name: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    mobile_number: str = Field(..., min_length=10, max_length=15)
    password: str = Field(..., min_length=8)

    # Business/Property Details
    business_name: str = Field(..., min_length=2, max_length=150)
    property_name: str = Field(..., min_length=2, max_length=150)
    property_type: PROPERTY_TYPES = Field(default="HOTEL")
    star_category: int = Field(default=3, ge=1, le=5)


class OwnerRegistrationResponse(BaseModel):
    success: bool
    message: str
    owner_id: str
    property_id: str
    user_id: str
    onboarding_status: str = "pending_approval"
    trial_days: int = 14


class AcceptInviteRequest(BaseModel):
    invitation_token: str
    password: str = Field(..., min_length=8)
    confirm_password: str = Field(..., min_length=8)
    pin: str = Field(..., min_length=4, max_length=6, pattern=r"^\d+$")


class AcceptInviteResponse(BaseModel):
    success: bool
    message: str
    user_id: str
