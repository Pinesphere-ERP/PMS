from pydantic import BaseModel
from typing import Optional, List, Dict
from datetime import datetime, date
import uuid

# ── Auth & Session ────────────────────────────────────────────────────────────

class PortalOTPRequest(BaseModel):
    booking_reference: str
    mobile_number: str

class PortalOTPVerify(BaseModel):
    booking_reference: str
    mobile_number: str
    otp: str

class PortalTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    guest_name: str
    booking_id: uuid.UUID
    room_number: Optional[str] = None
    expires_in: Optional[int] = None
    booking_reference: Optional[str] = None

class PortalLoginRequest(BaseModel):
    booking_reference: str
    mobile_number: str

class ReferenceResendRequest(BaseModel):
    mobile_number: str

# ── Phase 2: Guest Portal GET APIs ────────────────────────────────────────────

class PortalGuestInfo(BaseModel):
    name: str
    mobile: Optional[str]
    email: Optional[str]

class PortalStayInfo(BaseModel):
    booking_reference: str
    check_in_date: Optional[date]
    check_out_date: Optional[date]
    status: str

class PortalRoomInfo(BaseModel):
    room_number: Optional[str]
    category_title: Optional[str]

class PortalMeResponse(BaseModel):
    guest: PortalGuestInfo
    stay: PortalStayInfo
    room: PortalRoomInfo

class PortalStayResponse(BaseModel):
    booking_status: str
    booked_at: datetime
    checked_in_at: Optional[datetime]
    checked_out_at: Optional[datetime]
    adults: int
    children: int

class PortalRoomResponse(BaseModel):
    room_number: str
    category: str
    description: Optional[str]

class PortalPropertyResponse(BaseModel):
    name: str
    address: Optional[str]
    contact_email: Optional[str]
    contact_phone: Optional[str]
    check_in_time: Optional[str]
    check_out_time: Optional[str]

class AmenityItem(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str]
    icon: Optional[str]

class PortalAmenitiesResponse(BaseModel):
    amenities: List[AmenityItem]

class FolioLineItemResponse(BaseModel):
    description: str
    amount: float
    date: datetime

class PortalFolioSummaryResponse(BaseModel):
    total_charges: float
    total_paid: float
    balance_due: float
    items: List[FolioLineItemResponse]

# ── POST Request APIs ─────────────────────────────────────────────────────────

class PortalSecurePaymentRequest(BaseModel):
    mode: str
    razorpay_payment_id: Optional[str] = None
    razorpay_order_id: Optional[str] = None
    razorpay_signature: Optional[str] = None

class PortalPaymentResponse(BaseModel):
    payment_id: uuid.UUID
    amount: float
    mode: str
    status: str
    transaction_id: str
    created_at: datetime

class PortalInvoiceResponse(BaseModel):
    invoice_id: uuid.UUID
    invoice_number: str
    date: date
    due_date: date
    amount: float
    gst: float
    status: str

# ── Phase 4A: Guest Services ──────────────────────────────────────────────────

class PortalServiceCatalogItem(BaseModel):
    task_type: str
    display_name: str
    description: str
    icon: str

class PortalServiceCreate(BaseModel):
    task_type: str
    description: str

class PortalServiceResponse(BaseModel):
    task_id: uuid.UUID
    task_type: str
    status: str
    description: Optional[str]
    created_at: datetime
    completed_at: Optional[datetime]

class PortalMenuItem(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str]
    price: float
    veg_type: str
    is_available: bool
    image_url: Optional[str]

class PortalMenuCategory(BaseModel):
    id: uuid.UUID
    name: str
    description: Optional[str]
    items: List[PortalMenuItem] = []

class PortalFoodOrderCreateItem(BaseModel):
    item_id: uuid.UUID
    quantity: int

class PortalFoodOrderCreate(BaseModel):
    items: List[PortalFoodOrderCreateItem]
    special_instructions: Optional[str] = None

# ── Phase 4D: Feedback & Ratings ──────────────────────────────────────────────

class PortalComplaintCreate(BaseModel):
    description: str

class GuestFeedbackCreate(BaseModel):
    task_id: Optional[uuid.UUID] = None
    overall_rating: Optional[int] = None
    food_rating: Optional[int] = None
    service_rating: Optional[int] = None
    staff_rating: Optional[int] = None
    comments: Optional[str] = None
    is_anonymous: bool = False

class GuestFeedbackResponse(BaseModel):
    id: uuid.UUID
    task_id: Optional[uuid.UUID]
    overall_rating: Optional[int]
    food_rating: Optional[int]
    service_rating: Optional[int]
    staff_rating: Optional[int]
    comments: Optional[str]
    is_anonymous: bool
    created_at: datetime
    updated_at: datetime

# ── Phase 5: Checkout Lifecycle ───────────────────────────────────────────────

class PortalCheckoutStatusResponse(BaseModel):
    state: str # ACTIVE, REQUESTED, COMPLETED, REVOKED
    balance: float
    checkout_task_id: Optional[uuid.UUID] = None
    grace_period_ends_at: Optional[datetime] = None
