from pydantic import BaseModel, EmailStr
from typing import Optional

class PropertyCreateInput(BaseModel):
    # Owner Details
    owner_name: str
    owner_designation: Optional[str] = None
    owner_mobile: str
    owner_email: str
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
    
    # Location Details
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    pincode: Optional[str] = None
