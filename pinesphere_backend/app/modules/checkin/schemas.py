from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
import uuid


class CheckInRequest(BaseModel):
    booking_id: uuid.UUID = Field(..., description="Booking to check in")
    deposit: Optional[float] = Field(None, ge=0, description="Security deposit collected")
    advance_paid: Optional[float] = Field(None, ge=0, description="Advance amount paid at check-in")
    id_verified: bool = Field(False, description="Guest ID verification status")
    id_verification_notes: Optional[str] = Field(None, max_length=500)
    special_requests: Optional[str] = Field(None, max_length=1000)
    vehicle_number: Optional[str] = Field(None, max_length=20)
    parking_required: bool = Field(False)
    staff_id: Optional[uuid.UUID] = Field(None, description="Staff member performing check-in")
    offline_id: Optional[str] = Field(None, max_length=128, description="Offline-generated unique ID for sync")


class WalkInGuestInfo(BaseModel):
    full_name: str = Field(..., max_length=150)
    mobile: Optional[str] = Field(None, max_length=15)
    email: Optional[str] = Field(None, max_length=150)
    id_type: Optional[str] = Field(None, max_length=30)
    id_number: Optional[str] = Field(None, max_length=50)
    address: Optional[str] = None
    city: Optional[str] = Field(None, max_length=80)
    state: Optional[str] = Field(None, max_length=80)
    country: Optional[str] = Field(None, max_length=80)
    nationality: Optional[str] = Field(None, max_length=80)
    gender: Optional[str] = Field(None, max_length=20)


class WalkInCheckInRequest(BaseModel):
    guest: WalkInGuestInfo
    property_id: uuid.UUID
    room_id: uuid.UUID
    check_in_date: date = Field(default_factory=date.today)
    check_out_date: date
    adults: int = Field(1, ge=1)
    children: int = Field(0, ge=0)
    infants: int = Field(0, ge=0)
    room_rent: Optional[float] = Field(None, ge=0)
    deposit: Optional[float] = Field(None, ge=0)
    advance_paid: Optional[float] = Field(None, ge=0)
    id_verified: bool = False
    id_verification_notes: Optional[str] = None
    special_requests: Optional[str] = None
    vehicle_number: Optional[str] = Field(None, max_length=20)
    parking_required: bool = False
    staff_id: Optional[uuid.UUID] = None
    offline_id: Optional[str] = None


class CheckInResponse(BaseModel):
    checkin_id: uuid.UUID
    booking_id: uuid.UUID
    room_id: uuid.UUID
    guest_id: uuid.UUID
    property_id: uuid.UUID
    staff_id: Optional[uuid.UUID] = None
    deposit: Optional[float] = None
    advance_paid: Optional[float] = None
    id_verified: bool = False
    id_verification_notes: Optional[str] = None
    checked_in_at: Optional[datetime] = None
    status: str = "active"
    offline_id: Optional[str] = None
    special_requests: Optional[str] = None
    vehicle_number: Optional[str] = None
    parking_required: bool = False
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    guest_name: Optional[str] = None
    room_number: Optional[str] = None
    booking_reference: Optional[str] = None

    class Config:
        from_attributes = True


class CheckInSearchResult(BaseModel):
    booking_id: uuid.UUID
    guest_id: uuid.UUID
    room_id: uuid.UUID
    property_id: uuid.UUID
    guest_name: str
    room_number: str
    room_type: Optional[str] = None
    check_in_date: date
    check_out_date: date
    booking_status: str
    adults: int = 1
    children: int = 0
    room_rent: Optional[float] = None
    deposit: Optional[float] = None
    advance_paid: Optional[float] = None
    total_payable: Optional[float] = None

    class Config:
        from_attributes = True


class InvoiceResponse(BaseModel):
    invoice_id: uuid.UUID
    invoice_number: str
    booking_id: uuid.UUID
    property_id: uuid.UUID
    guest_id: uuid.UUID
    grand_total: float = 0
    total_paid: float = 0
    balance_due: float = 0
    status: str = "draft"
    generated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class InvoiceItemResponse(BaseModel):
    item_id: uuid.UUID
    description: str
    category: Optional[str] = None
    quantity: int = 1
    unit_price: float = 0
    total_price: float = 0

    class Config:
        from_attributes = True
