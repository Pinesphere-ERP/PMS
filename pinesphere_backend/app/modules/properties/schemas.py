from pydantic import BaseModel, EmailStr
from typing import Optional

class PropertyCreateInput(BaseModel):
    # Owner Reference — can pass existing owner_id OR provide inline owner details
    # If owner_id is provided, the existing Owner entity will be linked directly
    owner_id: Optional[str] = None          # UUID of existing Owner (preferred)
    owner_user_id: Optional[str] = None     # UUID of existing User with OWNER role (backwards compat)
    owner_name: Optional[str] = None
    owner_designation: Optional[str] = None
    owner_mobile: Optional[str] = None
    owner_email: Optional[str] = None
    owner_pan: Optional[str] = None
    
    # Business Details
    business_type: Optional[str] = None
    business_name: str
    business_reg_number: Optional[str] = None
    business_gst: Optional[str] = None
    business_pan: Optional[str] = None
    
    # Property Details
    property_name: str
    property_type: Optional[str] = None
    star_category: Optional[int] = None
    year_established: Optional[int] = None
    total_floors: Optional[int] = None
    total_rooms: Optional[int] = None
    description: Optional[str] = None
    cover_image: Optional[str] = None
    
    # Location Details
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    pincode: Optional[str] = None

    # Dynamic Rooms configuration
    rooms: Optional[list] = None
