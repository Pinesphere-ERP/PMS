from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date, datetime
import uuid


class GuestCreateRequest(BaseModel):
    property_id: uuid.UUID
    full_name: str = Field(..., max_length=150)
    mobile: Optional[str] = Field(None, max_length=15)
    email: Optional[str] = Field(None, max_length=150)
    address: Optional[str] = None
    city: Optional[str] = Field(None, max_length=80)
    state: Optional[str] = Field(None, max_length=80)
    country: Optional[str] = Field(None, max_length=80)
    nationality: Optional[str] = Field(None, max_length=80)
    dob: Optional[date] = None
    gender: Optional[str] = Field(None, max_length=20)
    id_type: Optional[str] = Field(None, max_length=30)
    id_number: Optional[str] = Field(None, max_length=50)
    id_front_url: Optional[str] = None
    id_back_url: Optional[str] = None
    passport_number: Optional[str] = Field(None, max_length=30)
    visa_number: Optional[str] = Field(None, max_length=30)
    emergency_contact_name: Optional[str] = Field(None, max_length=150)
    emergency_contact_phone: Optional[str] = Field(None, max_length=15)


class GuestResponse(BaseModel):
    guest_id: uuid.UUID
    property_id: Optional[uuid.UUID] = None
    full_name: str
    mobile: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    nationality: Optional[str] = None
    dob: Optional[date] = None
    gender: Optional[str] = None
    id_type: Optional[str] = None
    id_number: Optional[str] = None
    id_front_url: Optional[str] = None
    id_back_url: Optional[str] = None
    passport_number: Optional[str] = None
    visa_number: Optional[str] = None
    verification_status: str = "pending"
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class BookingCreateRequest(BaseModel):
    property_id: uuid.UUID
    room_id: uuid.UUID
    guest_id: uuid.UUID
    booking_type: Optional[str] = Field(None, max_length=20)
    booking_source: Optional[str] = Field(None, max_length=30)
    check_in_date: date
    check_out_date: date
    adults: int = Field(default=1, ge=0)
    children: int = Field(default=0, ge=0)
    infants: int = Field(default=0, ge=0)
    room_rent: Optional[float] = None
    deposit: Optional[float] = Field(default=0, ge=0)
    discount: Optional[float] = Field(default=0, ge=0)
    taxes: Optional[float] = Field(default=0, ge=0)
    advance_paid: Optional[float] = Field(default=0, ge=0)
    extra_bed: bool = False
    guest_preferences: Optional[str] = None
    notes: Optional[str] = None
    vehicle_number: Optional[str] = Field(None, max_length=20)


class BookingUpdateRequest(BaseModel):
    room_id: Optional[uuid.UUID] = None
    booking_type: Optional[str] = Field(None, max_length=20)
    booking_source: Optional[str] = Field(None, max_length=30)
    check_in_date: Optional[date] = None
    check_out_date: Optional[date] = None
    adults: Optional[int] = Field(None, ge=0)
    children: Optional[int] = Field(None, ge=0)
    infants: Optional[int] = Field(None, ge=0)
    room_rent: Optional[float] = None
    deposit: Optional[float] = Field(None, ge=0)
    discount: Optional[float] = Field(None, ge=0)
    taxes: Optional[float] = Field(None, ge=0)
    advance_paid: Optional[float] = Field(None, ge=0)
    extra_bed: Optional[bool] = None
    guest_preferences: Optional[str] = None
    notes: Optional[str] = None
    vehicle_number: Optional[str] = Field(None, max_length=20)


class BookingResponse(BaseModel):
    booking_id: uuid.UUID
    property_id: uuid.UUID
    room_id: uuid.UUID
    guest_id: uuid.UUID
    booking_type: Optional[str] = None
    booking_source: Optional[str] = None
    check_in_date: date
    check_out_date: date
    adults: int = 1
    children: int = 0
    infants: int = 0
    room_rent: Optional[float] = None
    deposit: Optional[float] = 0
    discount: Optional[float] = 0
    taxes: Optional[float] = 0
    total_payable: Optional[float] = None
    advance_paid: Optional[float] = 0
    pending_amount: Optional[float] = 0
    extra_bed: bool = False
    guest_preferences: Optional[str] = None
    notes: Optional[str] = None
    vehicle_number: Optional[str] = None
    booking_status: Optional[str] = "confirmed"
    payment_status: Optional[str] = "pending"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    guest_name: Optional[str] = None
    guest_mobile: Optional[str] = None
    room_number: Optional[str] = None

    class Config:
        from_attributes = True


class BookingListResponse(BaseModel):
    total: int
    items: List[BookingResponse]


class CheckInRequest(BaseModel):
    booking_id: uuid.UUID
    room_id: uuid.UUID
    deposit: Optional[float] = Field(default=0, ge=0)
    advance_paid: Optional[float] = Field(default=0, ge=0)
    id_verified: bool = False
    special_requests: Optional[str] = None
    vehicle_number: Optional[str] = Field(None, max_length=20)
    parking_required: bool = False
    staff_id: Optional[uuid.UUID] = None


class CheckInResponse(BaseModel):
    checkin_id: uuid.UUID
    booking_id: uuid.UUID
    room_id: uuid.UUID
    guest_id: uuid.UUID
    property_id: uuid.UUID
    staff_id: Optional[uuid.UUID] = None
    deposit: Optional[float] = 0
    advance_paid: Optional[float] = 0
    id_verified: bool = False
    id_verification_notes: Optional[str] = None
    checked_in_at: Optional[datetime] = None
    status: str = "active"
    special_requests: Optional[str] = None
    vehicle_number: Optional[str] = None
    parking_required: bool = False
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    guest_name: Optional[str] = None
    room_number: Optional[str] = None

    class Config:
        from_attributes = True


class CheckOutRequest(BaseModel):
    damage_bill: Optional[float] = 0.0
    laundry_bill: Optional[float] = 0.0
    minibar_bill: Optional[float] = 0.0
    restaurant_bill: Optional[float] = 0.0

