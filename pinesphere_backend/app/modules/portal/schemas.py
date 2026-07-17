from pydantic import BaseModel
from typing import Optional
import uuid

class PortalLoginRequest(BaseModel):
    booking_reference: str
    mobile_number: str

class PortalTokenResponse(BaseModel):
    access_token: str
    token_type: str
    guest_name: str
    booking_id: uuid.UUID
    room_number: Optional[str] = None

class PortalServiceRequest(BaseModel):
    service_type: str # 'housekeeping', 'maintenance', 'concierge'
    description: str

class PortalOrderRequest(BaseModel):
    item_id: uuid.UUID
    quantity: int
    special_instructions: Optional[str] = None
