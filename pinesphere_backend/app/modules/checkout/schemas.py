from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
import uuid


class CheckOutRequest(BaseModel):
    checkin_id: uuid.UUID = Field(..., description="Active check-in ID to check out")
    room_charges: Optional[float] = Field(None, ge=0, description="Room charges override (auto-calculated if omitted)")
    restaurant_charges: float = Field(0, ge=0)
    laundry_charges: float = Field(0, ge=0)
    minibar_charges: float = Field(0, ge=0)
    damage_charges: float = Field(0, ge=0)
    miscellaneous_charges: float = Field(0, ge=0)
    discount: float = Field(0, ge=0)
    gst: float = Field(0, ge=0)
    key_returned: bool = Field(False)
    id_returned: bool = Field(False)
    remarks: Optional[str] = Field(None, max_length=1000)
    staff_id: Optional[uuid.UUID] = Field(None, description="Staff member performing check-out")


class CheckOutResponse(BaseModel):
    checkout_id: uuid.UUID
    checkin_id: uuid.UUID
    booking_id: uuid.UUID
    room_id: uuid.UUID
    property_id: uuid.UUID
    staff_id: Optional[uuid.UUID] = None
    checkout_time: Optional[datetime] = None
    room_charges: float = 0
    restaurant_charges: float = 0
    laundry_charges: float = 0
    minibar_charges: float = 0
    damage_charges: float = 0
    miscellaneous_charges: float = 0
    discount: float = 0
    gst: float = 0
    total_amount: float = 0
    advance_paid: float = 0
    remaining_balance: float = 0
    refund_amount: float = 0
    payment_status: str = "pending"
    key_returned: bool = False
    id_returned: bool = False
    feedback_submitted: bool = False
    remarks: Optional[str] = None
    checkout_status: str = "pending"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    guest_name: Optional[str] = None
    room_number: Optional[str] = None
    booking_reference: Optional[str] = None

    class Config:
        from_attributes = True


class PendingCheckoutItem(BaseModel):
    checkin_id: uuid.UUID
    booking_id: uuid.UUID
    room_id: uuid.UUID
    property_id: uuid.UUID
    guest_id: uuid.UUID
    guest_name: str
    room_number: str
    room_type: Optional[str] = None
    check_in_date: date
    check_out_date: date
    checked_in_at: Optional[datetime] = None
    adults: int = 1
    children: int = 0
    room_rent: Optional[float] = None
    advance_paid: float = 0
    estimated_total: float = 0
    is_overdue: bool = False
    days_since_checkin: int = 0

    class Config:
        from_attributes = True


class CheckoutBillingDetail(BaseModel):
    checkin_id: uuid.UUID
    booking_id: uuid.UUID
    guest_name: str
    room_number: str
    room_type: Optional[str] = None
    check_in_date: date
    check_out_date: date
    checked_in_at: Optional[datetime] = None
    checkout_date_today: date
    nights_stayed: int
    room_rent_per_night: float
    room_charges: float
    restaurant_charges: float = 0
    laundry_charges: float = 0
    minibar_charges: float = 0
    damage_charges: float = 0
    miscellaneous_charges: float = 0
    subtotal: float
    discount: float = 0
    gst: float = 0
    grand_total: float
    advance_paid: float = 0
    remaining_balance: float = 0
    deposit: float = 0
    is_overdue: bool = False
    overdue_days: int = 0

    class Config:
        from_attributes = True
