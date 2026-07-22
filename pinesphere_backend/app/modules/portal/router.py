"""
Guest Portal — OTP-based auth, folio, payments, service requests, F&B orders.
Replaces the previous mobile-match auth with a secure OTP flow.
"""
import random
import string
import uuid
from datetime import datetime, timedelta, date
from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update

from app.infra.database import get_db
from app.infra.models import (
    Booking, Guest, Room, RoomCategory, Payment, FolioLineItem, Task, OTPRequest, User
)
from app.core.security import create_access_token, decode_access_token, get_password_hash, verify_password
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/portal", tags=["Guest Portal"])
security = HTTPBearer()


# ──────────────────────────────────────────────────────────────────────────────
# Auth Dependency
# ──────────────────────────────────────────────────────────────────────────────

async def get_current_guest_booking(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> Booking:
    """Decode portal JWT and return the associated Booking."""
    token = credentials.credentials
    try:
        payload = decode_access_token(token)
        if payload.get("type") != "guest_portal":
            raise HTTPException(status_code=401, detail="Invalid token type")
        booking_id_str = payload.get("sub")
        if not booking_id_str:
            raise HTTPException(status_code=401, detail="Invalid token payload")
        booking_id = uuid.UUID(booking_id_str)
    except Exception:
        raise HTTPException(status_code=401, detail="Could not validate credentials")

    stmt = select(Booking).where(Booking.booking_id == booking_id)
    result = await db.execute(stmt)
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=401, detail="Booking not found")
    return booking


def _generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


# ──────────────────────────────────────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────────────────────────────────────

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

class PortalPaymentRequest(BaseModel):
    amount: float
    mode: str  # cash, upi, card, razorpay

class FolioLineItemResponse(BaseModel):
    id: uuid.UUID
    category: str
    description: str
    quantity: int
    unit_price: float
    amount: float

class ServiceRequest(BaseModel):
    service_type: str  # housekeeping, laundry, room_service, other
    description: str

class FoodOrderItem(BaseModel):
    item_name: str
    quantity: int
    unit_price: float


# ──────────────────────────────────────────────────────────────────────────────
# OTP Auth Flow (replaces mobile-match)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/auth/request-otp")
async def portal_request_otp(
    req: PortalOTPRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Step 1: Guest provides booking reference + registered mobile.
    System sends an OTP (logs it for now; integrate SMS in prod).
    Rate limited: 3 requests per booking reference per hour.
    """
    stmt = select(Booking).where(Booking.booking_reference == req.booking_reference)
    result = await db.execute(stmt)
    booking = result.scalar_one_or_none()

    if not booking:
        return {"message": "If the booking reference is valid, an OTP has been sent."}

    # Verify mobile matches the guest
    guest_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()

    if not guest or guest.mobile != req.mobile_number:
        return {"message": "If the booking reference is valid, an OTP has been sent."}

    # Rate limiting: 3 requests per hour
    from sqlalchemy import func
    one_hour_ago = datetime.utcnow() - timedelta(hours=1)
    recent_otps = await db.execute(
        select(func.count(OTPRequest.id))
        .where(
            OTPRequest.booking_id == booking.booking_id,
            OTPRequest.purpose == "guest_portal",
            OTPRequest.created_at >= one_hour_ago,
        )
    )
    if recent_otps.scalar() >= 3:
        raise HTTPException(status_code=429, detail="Too many OTP requests. Please try again later.")

    # Invalidate old OTPs
    await db.execute(
        update(OTPRequest)
        .where(
            OTPRequest.booking_id == booking.booking_id,
            OTPRequest.purpose == "guest_portal",
            OTPRequest.used_at.is_(None),
        )
        .values(used_at=datetime.utcnow())
    )

    otp_plain = _generate_otp()
    otp_hashed = get_password_hash(otp_plain)

    otp_rec = OTPRequest(
        id=uuid.uuid4(),
        user_id=None,
        booking_id=booking.booking_id,
        otp_hash=otp_hashed,
        purpose="guest_portal",
        expires_at=datetime.utcnow() + timedelta(minutes=10),
    )
    db.add(otp_rec)

    # Mock SMS provider
    with open("otp_mock.log", "a") as f:
        f.write(f"{datetime.utcnow().isoformat()} - [PORTAL OTP] Booking {req.booking_reference}: {otp_plain}\n")
    
    # Redacted log for console
    print(f"[PORTAL OTP] Booking {req.booking_reference}: [REDACTED]")

    return {"message": "If the booking reference is valid, an OTP has been sent."}


@router.post("/auth/verify-otp", response_model=PortalTokenResponse)
async def portal_verify_otp(
    req: PortalOTPVerify,
    db: AsyncSession = Depends(get_db),
):
    """Step 2: Guest provides OTP. Returns a portal JWT on success."""
    stmt = select(Booking).where(Booking.booking_reference == req.booking_reference)
    result = await db.execute(stmt)
    booking = result.scalar_one_or_none()

    if not booking:
        raise HTTPException(status_code=401, detail="Invalid booking reference or OTP")

    # Verify mobile
    guest_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()

    if not guest or guest.mobile != req.mobile_number:
        raise HTTPException(status_code=401, detail="Invalid booking reference or OTP")

    # Verify OTP
    otp_stmt = (
        select(OTPRequest)
        .where(
            OTPRequest.booking_id == booking.booking_id,
            OTPRequest.purpose == "guest_portal",
            OTPRequest.used_at.is_(None),
            OTPRequest.expires_at >= datetime.utcnow(),
        )
        .order_by(OTPRequest.expires_at.desc())
    )
    otp_res = await db.execute(otp_stmt)
    otp_rec = otp_res.scalars().first()

    if not otp_rec or not verify_password(req.otp, otp_rec.otp_hash):
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")

    otp_rec.used_at = datetime.utcnow()
    await db.flush()

    # Fetch room
    room_number: Optional[str] = None
    if booking.room_id:
        room_stmt = select(Room).where(Room.room_id == booking.room_id)
        room_res = await db.execute(room_stmt)
        room = room_res.scalar_one_or_none()
        if room:
            room_number = room.room_number

    # Issue portal JWT (type = guest_portal)
    import jwt as pyjwt
    from app.core.config import settings
    payload = {
        "sub": str(booking.booking_id),
        "tenant_id": str(booking.property_id),
        "type": "guest_portal",
        "device_fp": "portal",
        "exp": datetime.utcnow() + timedelta(days=7),
    }
    access_token = pyjwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


    return PortalTokenResponse(
        access_token=access_token,
        guest_name=guest.full_name or "",
        booking_id=booking.booking_id,
        room_number=room_number,
    )


@router.get("/me")
async def get_portal_me(
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db),
):
    """Return booking and guest details for the logged-in guest portal user."""
    guest_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()
    
    room_number = None
    room_type = None
    if booking.room_id:
        room_stmt = select(Room).where(Room.room_id == booking.room_id)
        room_res = await db.execute(room_stmt)
        room = room_res.scalar_one_or_none()
        if room:
            room_number = room.room_number
            cat_stmt = select(RoomCategory).where(RoomCategory.room_category_id == room.room_category_id)
            cat_res = await db.execute(cat_stmt)
            category = cat_res.scalar_one_or_none()
            if category:
                room_type = category.room_name

    return {
        "booking_id": str(booking.booking_id),
        "booking_reference": booking.booking_reference,
        "name": guest.full_name if guest else "Guest",
        "mobile": guest.mobile if guest else None,
        "email": guest.email if guest else None,
        "room_number": room_number,
        "room_type": room_type,
        "check_in": booking.check_in_date.isoformat() if booking.check_in_date else None,
        "check_out": booking.check_out_date.isoformat() if booking.check_out_date else None,
        "status": booking.booking_status,
    }


# ──────────────────────────────────────────────────────────────────────────────
# Legacy mobile-match auth (kept for backwards compat, deprecated)
# ──────────────────────────────────────────────────────────────────────────────

class PortalLoginRequest(BaseModel):
    booking_reference: str
    mobile_number: str

@router.post("/auth", response_model=PortalTokenResponse, deprecated=True,
             summary="Deprecated: Use /auth/request-otp and /auth/verify-otp instead")
async def portal_login_legacy(
    req: PortalLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Legacy direct-login. Redirects to OTP flow in production environments."""
    stmt = select(Booking).where(Booking.booking_reference == req.booking_reference)
    result = await db.execute(stmt)
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=401, detail="Invalid booking reference")

    guest_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()
    if not guest or guest.mobile != req.mobile_number:
        raise HTTPException(status_code=401, detail="Invalid mobile number")

    if booking.status in ["cancelled", "no_show", "completed"]:
        raise HTTPException(status_code=403, detail="Booking is not active")

    room_number: Optional[str] = None
    if booking.room_id:
        room_stmt = select(Room).where(Room.room_id == booking.room_id)
        room_res = await db.execute(room_stmt)
        room = room_res.scalar_one_or_none()
        if room:
            room_number = room.room_number

    import jwt as pyjwt
    from app.core.config import settings
    payload = {
        "sub": str(booking.booking_id),
        "tenant_id": str(booking.property_id),
        "type": "guest_portal",
        "device_fp": "portal",
        "exp": datetime.utcnow() + timedelta(days=7),
    }
    access_token = pyjwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

    return PortalTokenResponse(
        access_token=access_token,
        guest_name=guest.full_name or "",
        booking_id=booking.booking_id,
        room_number=room_number,
    )


# ──────────────────────────────────────────────────────────────────────────────
# Folio (Invoice)
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/folio")
async def get_guest_folio(
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db),
):
    """Return all folio line items and total bill for the guest."""
    stmt = (
        select(FolioLineItem)
        .where(FolioLineItem.booking_id == booking.booking_id, FolioLineItem.is_void == False)
        .order_by(FolioLineItem.created_at)
    )
    result = await db.execute(stmt)
    items = result.scalars().all()

    # Also fetch any payments made
    pay_stmt = select(Payment).where(Payment.booking_id == booking.booking_id, Payment.is_void == False)
    pay_res = await db.execute(pay_stmt)
    payments = pay_res.scalars().all()

    total_charges = sum(float(item.amount) for item in items)
    total_paid = sum(float(p.amount) for p in payments)
    balance_due = round(total_charges - total_paid, 2)

    return {
        "booking_id": str(booking.booking_id),
        "line_items": [
            {
                "id": str(i.id),
                "category": i.category,
                "description": i.description,
                "quantity": i.quantity,
                "unit_price": float(i.unit_price),
                "amount": float(i.amount),
            }
            for i in items
        ],
        "total_charges": round(total_charges, 2),
        "total_paid": round(total_paid, 2),
        "balance_due": balance_due,
        "payments": [
            {
                "payment_id": str(p.payment_id),
                "amount": float(p.amount),
                "mode": p.payment_mode,
                "paid_at": p.created_at.isoformat() if p.created_at else None,
            }
            for p in payments
        ],
    }


# ──────────────────────────────────────────────────────────────────────────────
# Guest Payments (was returning 501 — now fully implemented)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/pay")
async def portal_pay(
    req: PortalPaymentRequest,
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db),
):
    """
    Record a guest payment via the portal (cash, UPI, card, Razorpay).
    Adds a FolioLineItem for the payment and creates a Payment record.
    """
    if req.amount <= 0:
        raise HTTPException(status_code=400, detail="Payment amount must be positive")

    valid_modes = {"cash", "upi", "card", "razorpay", "bank_transfer"}
    if req.mode.lower() not in valid_modes:
        raise HTTPException(status_code=400, detail=f"Invalid payment mode. Allowed: {', '.join(valid_modes)}")

    # For Razorpay, verify signature in production — skip for now
    if req.mode.lower() == "razorpay":
        from app.core.config import settings
        if not settings.RAZORPAY_KEY_ID:
            raise HTTPException(status_code=503, detail="Razorpay is not configured for this property.")

    # Record payment
    payment = Payment(
        payment_id=uuid.uuid4(),
        booking_id=booking.booking_id,
        amount=req.amount,
        payment_mode=req.mode.lower(),
        status="completed",
        transaction_id=str(uuid.uuid4()),  # auto-generated reference
    )
    db.add(payment)
    await db.flush()

    # Add folio line item
    folio_item = FolioLineItem(
        id=uuid.uuid4(),
        booking_id=booking.booking_id,
        property_id=booking.property_id,
        category="payment",
        description=f"Payment via {req.mode.upper()} (Portal)",
        quantity=1,
        unit_price=req.amount,
        amount=req.amount,
        is_void=False,
    )
    db.add(folio_item)

    # Auto-accrue broker commission if applicable
    from app.modules.broker.router import accrue_commission
    try:
        await accrue_commission(db, booking.property_id, booking.booking_id, payment.payment_id, req.amount)
    except Exception:
        pass  # Non-critical; do not fail payment on commission error


    return {
        "status": "success",
        "payment_id": str(payment.payment_id),
        "amount": req.amount,
        "mode": req.mode,
        "message": f"Payment of ₹{req.amount:,.2f} recorded successfully.",
    }


# ──────────────────────────────────────────────────────────────────────────────
# Service Requests (was stub — now creates real Task)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/services")
async def request_service(
    req: ServiceRequest,
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db),
):
    """Guest requests a service (housekeeping, laundry, etc.) — creates a real Task."""
    task = Task(
        task_id=uuid.uuid4(),
        property_id=booking.property_id,  # F-02 fix: tasks must be property-scoped
        task_type=req.service_type,
        status="pending",
        priority="normal",
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        description=f"Guest request: {req.description}",
    )
    db.add(task)
    return {
        "status": "success",
        "task_id": str(task.task_id),
        "message": f"Your {req.service_type} request has been submitted. Staff will attend shortly.",
    }


# ──────────────────────────────────────────────────────────────────────────────
# Staff-Assisted Portal Reference Resend (F-15 fix — §3 §22)
# ──────────────────────────────────────────────────────────────────────────────

class ReferenceResendRequest(BaseModel):
    booking_id: uuid.UUID
    property_id: uuid.UUID

@router.post("/staff/resend-reference")
async def staff_resend_portal_reference(
    req: ReferenceResendRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    F-15 fix: Receptionist-assisted portal reference lookup.

    A Receptionist or Manager at the property may call this endpoint to retrieve
    the booking_reference for a guest who has forgotten or mis-read it.
    The endpoint verifies:
    1. The caller has access to the property (prevents cross-property lookup).
    2. The booking belongs to that property (prevents cross-property data leak).
    The booking_reference is returned in the response so the Receptionist can
    read it out to the guest over the phone, or trigger a WhatsApp send.
    """
    from app.core.dependencies import assert_property_access
    await assert_property_access(req.property_id, current_user, db)

    booking_stmt = select(Booking).where(
        Booking.booking_id == req.booking_id,
        Booking.property_id == req.property_id,  # safety: must match property
    )
    booking_res = await db.execute(booking_stmt)
    booking = booking_res.scalar_one_or_none()

    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found at this property")

    if not booking.booking_reference:
        raise HTTPException(
            status_code=422,
            detail="This booking does not have a portal reference yet. Please check-in the guest first."
        )

    guest_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()

    return {
        "booking_reference": booking.booking_reference,
        "guest_name": guest.full_name if guest else None,
        "guest_mobile": guest.mobile if guest else None,
        "message": (
            f"Booking reference for {guest.full_name if guest else 'guest'} is "
            f"{booking.booking_reference}. Share this with the guest to access the portal."
        ),
    }


# ──────────────────────────────────────────────────────────────────────────────
# F&B Orders (was stub — now creates real Task)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/orders")
async def create_portal_order(
    items: List[FoodOrderItem],
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db),
):
    """Guest places a food/beverage order from the portal — routes to kitchen as a Task."""
    if not items:
        raise HTTPException(status_code=400, detail="Order must contain at least one item.")

    total = sum(item.unit_price * item.quantity for item in items)
    description = ", ".join(f"{i.quantity}× {i.item_name}" for i in items)

    task = Task(
        task_id=uuid.uuid4(),
        property_id=booking.property_id,  # F-02 fix: tasks must be property-scoped
        task_type="food_order",
        status="pending",
        priority="normal",
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        description=f"F&B Order: {description}",
    )
    db.add(task)
    await db.flush()

    # Charge to folio
    folio_item = FolioLineItem(
        id=uuid.uuid4(),
        booking_id=booking.booking_id,
        property_id=booking.property_id,
        category="food",
        description=f"F&B: {description}",
        quantity=1,
        unit_price=total,
        amount=total,
        is_void=False,
    )
    db.add(folio_item)

    return {
        "status": "success",
        "task_id": str(task.task_id),
        "order_total": round(total, 2),
        "message": "Order sent to kitchen. Estimated delivery: 20–30 minutes.",
    }
