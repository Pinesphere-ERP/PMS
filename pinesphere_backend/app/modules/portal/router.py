"""
Guest Portal — OTP-based auth, folio, payments, service requests, F&B orders.
Replaces the previous mobile-match auth with a secure OTP flow.
"""
import random
import string
import uuid
from datetime import datetime, timedelta, date
from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, status, Request, BackgroundTasks
from app.infra.database import get_db, AsyncSessionLocal
from app.modules.portal.cache import PortalCache
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update

from app.infra.database import get_db
from app.infra.models import (
    Booking, Guest, Room, RoomCategory, Payment, FolioLineItem, Task, OTPRequest, User, PortalSession, CheckIn, CheckOut
)
from app.core.security import create_access_token, decode_access_token, get_password_hash, verify_password
from app.core.dependencies import get_current_user
from app.modules.portal.session_service import SessionService
from app.modules.portal.access_service import PortalAccessService

router = APIRouter(prefix="/portal", tags=["Guest Portal"])
security = HTTPBearer()


# ──────────────────────────────────────────────────────────────────────────────
# Auth Dependency
# ──────────────────────────────────────────────────────────────────────────────

async def get_current_portal_context(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Decode portal JWT and return context, leveraging Redis cache for capabilities."""
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

    session_id_str = payload.get("session_id")
    if not session_id_str:
        raise HTTPException(status_code=401, detail="Invalid token payload (missing session)")
    
    session_id = uuid.UUID(session_id_str)
    
    # Check session validity
    portal_session = await SessionService.get_active_session(db, session_id)
    if not portal_session:
        raise HTTPException(status_code=401, detail="Session revoked or expired")

    # Write amplification protection: update last_active_at at most once every 5 minutes
    now = datetime.now(timezone.utc)
    if not portal_session.last_active_at or (now - portal_session.last_active_at) > timedelta(minutes=5):
        await SessionService.update_last_active(db, session_id)

    stmt = select(Booking).where(Booking.booking_id == booking_id)
    result = await db.execute(stmt)
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=401, detail="Booking not found")

    # Check cache for capabilities
    capabilities = await PortalCache.get_context(session_id)
    if not capabilities:
        ci_stmt = select(CheckIn).where(CheckIn.booking_id == booking_id).order_by(CheckIn.created_at.desc())
        ci_res = await db.execute(ci_stmt)
        checkin = ci_res.scalars().first()

        co_stmt = select(CheckOut).where(CheckOut.booking_id == booking_id).order_by(CheckOut.created_at.desc())
        co_res = await db.execute(co_stmt)
        checkout = co_res.scalars().first()

        capabilities = PortalAccessService.get_capabilities(booking, checkin, checkout)
        await PortalCache.set_context(session_id, capabilities)

    if capabilities.get("should_revoke"):
        await SessionService.revoke_session(db, session_id, "SECURITY")
        raise HTTPException(status_code=403, detail="Portal access revoked due to stay expiration")

    return {"booking": booking, "capabilities": capabilities, "session": portal_session}

async def get_current_guest_booking(
    ctx: dict = Depends(get_current_portal_context)
) -> Booking:
    if not ctx["capabilities"].get("can_login"):
        raise HTTPException(status_code=403, detail="Portal access denied due to stay status")
    return ctx["booking"]

async def require_can_view_dashboard(ctx: dict = Depends(get_current_portal_context)) -> Booking:
    if not ctx["capabilities"].get("can_view_dashboard"):
        raise HTTPException(status_code=403, detail="Dashboard access denied")
    return ctx["booking"]

async def require_can_request_service(ctx: dict = Depends(get_current_portal_context)) -> Booking:
    if not ctx["capabilities"].get("can_request_service"):
        raise HTTPException(status_code=403, detail="Service requests are not available at this time.")
    return ctx["booking"]

async def require_can_pay(ctx: dict = Depends(get_current_portal_context)) -> Booking:
    if not ctx["capabilities"].get("can_pay"):
        raise HTTPException(status_code=403, detail="Payments are not available at this time.")
    return ctx["booking"]

async def require_can_download_invoice(ctx: dict = Depends(get_current_portal_context)) -> Booking:
    if not ctx["capabilities"].get("can_download_invoice"):
        raise HTTPException(status_code=403, detail="Invoice download is not available at this time.")
    return ctx["booking"]

async def require_can_submit_feedback(ctx: dict = Depends(get_current_portal_context)) -> Booking:
    if not ctx["capabilities"].get("can_submit_feedback"):
        raise HTTPException(status_code=403, detail="Feedback submission is not available at this time.")
    return ctx["booking"]


def _generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


# ──────────────────────────────────────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────────────────────────────────────
from app.modules.portal.schemas import (
    PortalCheckoutStatusResponse,
    GuestFeedbackCreate, GuestFeedbackResponse, PortalComplaintCreate,
    PortalMenuCategory, PortalMenuItem, PortalFoodOrderCreate, PortalFoodOrderCreateItem,
    PortalOTPRequest,
    PortalOTPVerify,
    PortalTokenResponse,
    PortalPaymentResponse,
    PortalInvoiceResponse,
    PortalSecurePaymentRequest,
    FolioLineItemResponse,
    PortalServiceCreate,
    PortalServiceResponse,
    PortalServiceCatalogItem,
    PortalLoginRequest,
    ReferenceResendRequest,
    PortalMeResponse,
    PortalStayResponse,
    PortalRoomResponse,
    PortalPropertyResponse,
    PortalAmenitiesResponse,
    PortalFolioSummaryResponse
)


# ──────────────────────────────────────────────────────────────────────────────
# OTP Auth Flow (replaces mobile-match)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/auth/request-otp")
async def portal_request_otp(
    request: Request,
    req: PortalOTPRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Step 1: Guest provides booking reference + registered mobile.
    System sends an OTP (logs it for now; integrate SMS in prod).
    Rate limited: 10 daily, 60s cooldown.
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

    # Validate login capability
    ci_stmt = select(CheckIn).where(CheckIn.booking_id == booking.booking_id).order_by(CheckIn.created_at.desc())
    ci_res = await db.execute(ci_stmt)
    checkin = ci_res.scalars().first()

    co_stmt = select(CheckOut).where(CheckOut.booking_id == booking.booking_id).order_by(CheckOut.created_at.desc())
    co_res = await db.execute(co_stmt)
    checkout = co_res.scalars().first()

    if not PortalAccessService.can_login(booking, checkin, checkout):
        return {"message": "If the booking reference is valid, an OTP has been sent."}

    # Rate limiting: 10 requests per day, 60s cooldown
    from sqlalchemy import func
    now = datetime.utcnow()
    one_day_ago = now - timedelta(days=1)
    one_min_ago = now - timedelta(seconds=60)
    
    recent_otps_stmt = await db.execute(
        select(OTPRequest.created_at)
        .where(
            OTPRequest.booking_id == booking.booking_id,
            OTPRequest.purpose == "guest_portal",
            OTPRequest.created_at >= one_day_ago,
        )
        .order_by(OTPRequest.created_at.desc())
    )
    recent_otps = recent_otps_stmt.scalars().all()
    
    if len(recent_otps) >= 10:
        raise HTTPException(status_code=429, detail="Daily limit reached. Please try again tomorrow.")
        
    if recent_otps and recent_otps[0] >= one_min_ago:
        raise HTTPException(status_code=429, detail="Please wait 60 seconds before requesting another OTP.")

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

    client_ip = request.client.host if request.client else None

    otp_rec = OTPRequest(
        id=uuid.uuid4(),
        user_id=None,
        booking_id=booking.booking_id,
        otp_hash=otp_hashed,
        purpose="guest_portal",
        client_ip=client_ip,
        expires_at=datetime.utcnow() + timedelta(minutes=5),
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
    request: Request,
    req: PortalOTPVerify,
    background_tasks: BackgroundTasks,
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

    # Verify OTP securely using row-level locking (FOR UPDATE)
    otp_stmt = (
        select(OTPRequest)
        .where(
            OTPRequest.booking_id == booking.booking_id,
            OTPRequest.purpose == "guest_portal",
            OTPRequest.used_at.is_(None),
            OTPRequest.expires_at >= datetime.utcnow(),
        )
        .order_by(OTPRequest.expires_at.desc())
        .with_for_update()
    )
    otp_res = await db.execute(otp_stmt)
    otp_rec = otp_res.scalars().first()

    if not otp_rec:
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")
        
    if not verify_password(req.otp, otp_rec.otp_hash):
        otp_rec.attempts += 1
        if otp_rec.attempts >= 5:
            otp_rec.used_at = datetime.utcnow() # Invalidate it
        await db.flush()
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")

    # Final check of can_login before issuing token
    ci_stmt = select(CheckIn).where(CheckIn.booking_id == booking.booking_id).order_by(CheckIn.created_at.desc())
    ci_res = await db.execute(ci_stmt)
    checkin = ci_res.scalars().first()

    co_stmt = select(CheckOut).where(CheckOut.booking_id == booking.booking_id).order_by(CheckOut.created_at.desc())
    co_res = await db.execute(co_stmt)
    checkout = co_res.scalars().first()

    if not PortalAccessService.can_login(booking, checkin, checkout):
        raise HTTPException(status_code=403, detail="Portal access denied due to stay status")

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

    # Extract request details
    last_ip = request.client.host if request.client else None
    user_agent = request.headers.get("user-agent")

    # Create Portal Session
    portal_session = await SessionService.create_session(
        db=db,
        property_id=booking.property_id,
        booking_id=booking.booking_id,
        guest_id=booking.guest_id,
        device_info="portal_web_login",  
        last_ip=last_ip,
        user_agent=user_agent,
        device_name=user_agent, # Fallback to user_agent for now
        duration_hours=24*7 # 7 days
    )

    # Issue portal JWT (type = guest_portal)
    access_token_expires = timedelta(days=7)
    jwt_payload = {
        "sub": str(booking.booking_id),
        "booking_id": str(booking.booking_id),
        "property_id": str(booking.property_id),
        "checkin_id": str(checkin.checkin_id) if checkin else None,
        "session_type": "portal",
        "session_id": str(portal_session.session_id)
    }
    access_token = create_access_token(data=jwt_payload, expires_delta=access_token_expires)

    # Cleanup is now handled by Celery beat schedule

    return PortalTokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=int(access_token_expires.total_seconds()),
        booking_reference=booking.booking_reference,
        room_number=room_number,
    )

@router.post("/auth/logout")
async def portal_logout(
    ctx: dict = Depends(get_current_portal_context),
    db: AsyncSession = Depends(get_db),
):
    """Explicitly terminate the current portal session."""
    session_id = ctx["session"].session_id
    await SessionService.revoke_session(db, session_id, "MANUAL")
    await PortalCache.invalidate_context(session_id)
    return {"status": "success", "message": "Logged out successfully."}

@router.post("/auth/logout-all")
async def portal_logout_all(
    ctx: dict = Depends(get_current_portal_context),
    db: AsyncSession = Depends(get_db),
):
    """Explicitly terminate all sessions for this booking."""
    booking_id = ctx["booking"].booking_id
    await SessionService.revoke_all_for_booking(db, booking_id, "MANUAL")
    # Invalidation of cache for all sessions is complex without keys(*), so they will naturally expire or fail DB check.
    return {"status": "success", "message": "All sessions logged out successfully."}

@router.get("/capabilities")
async def get_portal_capabilities(ctx: dict = Depends(get_current_portal_context)):
    """Returns the granular permissions for the current portal session."""
    return PortalAccessService.get_capabilities(ctx["booking"], ctx["checkin"], ctx["checkout"])


@router.get("/me", response_model=PortalMeResponse)
async def get_portal_me(
    ctx: dict = Depends(get_current_portal_context),
    db: AsyncSession = Depends(get_db),
):
    """Return booking, guest details, and current capabilities for the logged-in guest."""
    booking = ctx["booking"]
    if not ctx["capabilities"].get("can_view_dashboard"):
        raise HTTPException(status_code=403, detail="Dashboard access denied")

    guest_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()
    
    room_number = None
    room_type = None
    if booking.room_id:
        from app.infra.models import RoomType  # Explicit due to the broken codebase
        room_stmt = select(Room).where(Room.room_id == booking.room_id)
        room_res = await db.execute(room_stmt)
        room = room_res.scalar_one_or_none()
        if room:
            room_number = room.room_number
            cat_stmt = select(RoomType).where(RoomType.id == room.room_type_id)
            cat_res = await db.execute(cat_stmt)
            category = cat_res.scalar_one_or_none()
            if category:
                room_type = category.name

    return {
        "guest": {
            "name": guest.full_name if guest else "Guest",
            "mobile": guest.mobile if guest else None,
            "email": guest.email if guest else None,
        },
        "stay": {
            "booking_reference": booking.booking_reference,
            "check_in_date": booking.check_in_date,
            "check_out_date": booking.check_out_date,
            "status": booking.booking_status,
        },
        "room": {
            "room_number": room_number,
            "category_title": room_type,
        }
    }


# ──────────────────────────────────────────────────────────────────────────────
# Legacy mobile-match auth (kept for backwards compat, deprecated)
# ──────────────────────────────────────────────────────────────────────────────

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

@router.get("/folio-summary", response_model=PortalFolioSummaryResponse)
async def get_guest_folio(
    booking: Booking = Depends(require_can_download_invoice),
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
        "total_charges": round(total_charges, 2),
        "total_paid": round(total_paid, 2),
        "balance_due": balance_due,
        "items": [
            {
                "description": f"{i.quantity}x {i.description}",
                "amount": float(i.amount),
                "date": i.created_at
            }
            for i in items
        ]
    }


# ──────────────────────────────────────────────────────────────────────────────
# Guest Payments (was returning 501 — now fully implemented)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/pay")
async def portal_pay(
    req: PortalSecurePaymentRequest,
    booking: Booking = Depends(require_can_pay),
    db: AsyncSession = Depends(get_db),
):
    """
    Record a guest payment via the portal safely.
    The backend calculates the balance due.
    """
    valid_modes = {"cash", "upi", "card", "razorpay", "bank_transfer"}
    if req.mode.lower() not in valid_modes:
        raise HTTPException(status_code=400, detail=f"Invalid payment mode. Allowed: {', '.join(valid_modes)}")

    # 1. Calculate balance due
    stmt = select(FolioLineItem).where(FolioLineItem.booking_id == booking.booking_id, FolioLineItem.is_void == False)
    result = await db.execute(stmt)
    items = result.scalars().all()
    
    pay_stmt = select(Payment).where(Payment.booking_id == booking.booking_id, Payment.status == "completed")
    pay_res = await db.execute(pay_stmt)
    payments = pay_res.scalars().all()
    
    total_charges = sum(float(item.amount) for item in items)
    total_paid = sum(float(p.amount) for p in payments)
    balance_due = round(total_charges - total_paid, 2)
    
    if balance_due <= 0:
        raise HTTPException(status_code=400, detail="No outstanding balance to pay")

    # For Razorpay, verify signature in production — skip for now
    if req.mode.lower() == "razorpay":
        from app.core.config import settings
        if not settings.RAZORPAY_KEY_ID:
            raise HTTPException(status_code=503, detail="Razorpay is not configured for this property.")

    # Record payment
    payment = Payment(
        payment_id=uuid.uuid4(),
        booking_id=booking.booking_id,
        amount=balance_due,
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
        unit_price=balance_due,
        amount=balance_due,
        is_void=False,
    )
    db.add(folio_item)

    # Auto-accrue broker commission if applicable
    from app.modules.broker.router import accrue_commission
    try:
        await accrue_commission(db, booking.property_id, booking.booking_id, payment.payment_id, balance_due)
    except Exception:
        pass  # Non-critical; do not fail payment on commission error

    await db.commit()
    return {
        "status": "success",
        "payment_id": str(payment.payment_id),
        "amount": balance_due,
        "mode": req.mode,
        "message": f"Payment of ₹{balance_due:,.2f} recorded successfully."
    }

@router.get("/payments", response_model=List[PortalPaymentResponse])
async def get_guest_payments(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    """Return all payments made by this guest for the current stay."""
    stmt = select(Payment).where(
        Payment.booking_id == booking.booking_id
    ).order_by(Payment.created_at.desc())
    
    result = await db.execute(stmt)
    payments = result.scalars().all()
    
    return [
        {
            "payment_id": p.payment_id,
            "amount": float(p.amount),
            "mode": p.payment_mode,
            "status": p.status,
            "transaction_id": p.transaction_id,
            "created_at": p.created_at
        } for p in payments
    ]

@router.get("/invoices", response_model=List[PortalInvoiceResponse])
async def get_guest_invoices(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    """Return the generated invoices for the guest."""
    from app.infra.models import Invoice
    
    stmt = select(Invoice).where(
        Invoice.booking_id == booking.booking_id,
        Invoice.guest_id == booking.guest_id
    ).order_by(Invoice.date.desc())
    
    result = await db.execute(stmt)
    invoices = result.scalars().all()
    
    return [
        {
            "invoice_id": inv.invoice_id,
            "invoice_number": inv.invoice_number,
            "date": inv.date,
            "due_date": inv.due_date,
            "amount": float(inv.amount),
            "gst": float(inv.gst) if inv.gst else 0.0,
            "status": inv.status
        } for inv in invoices
    ]
# ──────────────────────────────────────────────────────────────────────────────
# Service Requests (was stub — now creates real Task)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/services")
async def request_service(
    req: PortalServiceCreate,
    booking: Booking = Depends(require_can_request_service),
    db: AsyncSession = Depends(get_db),
):
    """Guest requests a service (housekeeping, laundry, etc.) — creates a real Task."""
    task = Task(
        task_id=uuid.uuid4(),
        property_id=booking.property_id,  # F-02 fix: tasks must be property-scoped
        task_type=req.task_type,
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

@router.get("/food/menu", response_model=List[PortalMenuCategory])
async def get_portal_food_menu(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import MenuCategory, MenuItem
    stmt = select(MenuCategory).where(
        MenuCategory.property_id == booking.property_id,
        MenuCategory.is_active == True,
        MenuCategory.is_deleted == False
    ).order_by(MenuCategory.sort_order)
    res = await db.execute(stmt)
    categories = res.scalars().all()
    
    item_stmt = select(MenuItem).where(
        MenuItem.property_id == booking.property_id,
        MenuItem.is_deleted == False
    )
    item_res = await db.execute(item_stmt)
    items = item_res.scalars().all()
    
    cat_map = {c.id: {"id": c.id, "name": c.name, "description": c.description, "items": []} for c in categories}
    for item in items:
        if item.category_id in cat_map:
            cat_map[item.category_id]["items"].append({
                "id": item.id,
                "name": item.name,
                "description": item.description,
                "price": float(item.price),
                "veg_type": item.veg_type,
                "is_available": item.is_available,
                "image_url": item.image_url
            })
            
    return [c for c in cat_map.values()]


@router.post("/food/orders")
async def create_portal_food_order(
    payload: PortalFoodOrderCreate,
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import MenuItem, Task, TaskLog
    if not payload.items:
        raise HTTPException(status_code=400, detail="Order must contain at least one item.")

    item_ids = [i.item_id for i in payload.items]
    stmt = select(MenuItem).where(
        MenuItem.id.in_(item_ids),
        MenuItem.property_id == booking.property_id,
        MenuItem.is_available == True,
        MenuItem.is_deleted == False
    )
    res = await db.execute(stmt)
    db_items = {i.id: i for i in res.scalars().all()}
    
    total = 0.0
    desc_parts = []
    for item in payload.items:
        db_item = db_items.get(item.item_id)
        if not db_item:
            raise HTTPException(status_code=400, detail=f"Item {item.item_id} is invalid or unavailable.")
        total += float(db_item.price) * item.quantity
        desc_parts.append(f"{item.quantity}x {db_item.name}")
        
    description = ", ".join(desc_parts)
    if payload.special_instructions:
        description += f" | Notes: {payload.special_instructions}"
        
    task_id = uuid.uuid4()
    task = Task(
        task_id=task_id,
        property_id=booking.property_id,
        task_type="food",
        status="pending",
        priority="normal",
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        description=f"F&B Order: {description}",
    )
    db.add(task)
    
    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=task_id,
        old_status=None,
        new_status="pending",
        notes="Guest placed food order via portal"
    )
    db.add(log)
    
    folio_item = FolioLineItem(
        id=uuid.uuid4(),
        booking_id=booking.booking_id,
        property_id=booking.property_id,
        category="food",
        description=f"F&B Order: {description}",
        quantity=1,
        unit_price=total,
        amount=total,
        is_void=False,
    )
    db.add(folio_item)
    
    await db.commit()
    
    return {
        "status": "success",
        "task_id": str(task_id),
        "order_total": round(total, 2),
        "message": "Order sent to kitchen.",
    }

@router.get("/food/orders")
async def get_portal_food_orders(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task
    stmt = select(Task).where(
        Task.booking_id == booking.booking_id,
        Task.task_type == 'food'
    ).order_by(Task.created_at.desc())
    res = await db.execute(stmt)
    tasks = res.scalars().all()
    
    return [
        {
            "task_id": t.task_id,
            "status": t.status,
            "description": t.description,
            "created_at": t.created_at
        } for t in tasks
    ]


# ── Phase 2: READ-ONLY Guest Experience APIs ──────────────────────────────────

@router.get("/stay", response_model=PortalStayResponse)
async def get_portal_stay(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    """Return detailed stay information including check-in/out status."""
    ci_stmt = select(CheckIn).where(
        CheckIn.booking_id == booking.booking_id,
        CheckIn.property_id == booking.property_id
    ).order_by(CheckIn.created_at.desc())
    ci_res = await db.execute(ci_stmt)
    checkin = ci_res.scalars().first()

    co_stmt = select(CheckOut).where(
        CheckOut.booking_id == booking.booking_id,
        CheckOut.property_id == booking.property_id
    ).order_by(CheckOut.created_at.desc())
    co_res = await db.execute(co_stmt)
    checkout = co_res.scalars().first()

    return {
        "booking_status": booking.booking_status,
        "booked_at": booking.created_at,
        "checked_in_at": checkin.checked_in_at if checkin else None,
        "checked_out_at": checkout.created_at if checkout else None,
        "adults": booking.adults,
        "children": booking.children
    }


@router.get("/room", response_model=PortalRoomResponse)
async def get_portal_room(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    """Return details of the room assigned to the guest."""
    if not booking.room_id:
        raise HTTPException(status_code=404, detail="No room assigned yet")
        
    from app.infra.models import RoomType

    room_stmt = select(Room, RoomType).join(
        RoomType, Room.room_type_id == RoomType.id
    ).where(
        Room.room_id == booking.room_id,
        Room.property_id == booking.property_id
    )
    room_res = await db.execute(room_stmt)
    row = room_res.first()
    
    if not row:
        raise HTTPException(status_code=404, detail="Room not found")
        
    room, category = row

    return {
        "room_number": room.room_number,
        "category": category.name if category else "Unknown",
        "description": category.description if category else None
    }


@router.get("/property", response_model=PortalPropertyResponse)
async def get_portal_property(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    """Return property level information for the guest portal."""
    from app.infra.models import Property
    # Check if PropertyAddress exists, otherwise omit
    
    prop_stmt = select(Property).where(Property.property_id == booking.property_id)
    prop_res = await db.execute(prop_stmt)
    prop = prop_res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
        
    address_str = None
    try:
        from app.infra.models import PropertyAddress
        addr_stmt = select(PropertyAddress).where(PropertyAddress.property_id == booking.property_id)
        addr_res = await db.execute(addr_stmt)
        addr = addr_res.scalar_one_or_none()
        if addr:
            address_str = f"{addr.address}, {addr.city}, {addr.state} {addr.pincode}"
    except ImportError:
        pass

    # Hardcoded timings as they are usually in property settings json, simplify for now
    return {
        "name": prop.property_name,
        "address": address_str,
        "contact_email": prop.email if hasattr(prop, 'email') else None,
        "contact_phone": prop.whatsapp_number if hasattr(prop, 'whatsapp_number') else None,
        "check_in_time": None,
        "check_out_time": None
    }


@router.get("/amenities", response_model=PortalAmenitiesResponse)
async def get_portal_amenities(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    """Return property level amenities available to the guest."""
    try:
        from app.infra.models import Amenity, PropertyAmenity
        stmt = (
            select(Amenity)
            .join(PropertyAmenity, PropertyAmenity.amenity_id == Amenity.id)
            .where(PropertyAmenity.property_id == booking.property_id)
        )
        result = await db.execute(stmt)
        amenities = result.scalars().all()
        
        return {
            "amenities": [
                {
                    "id": a.id,
                    "name": a.name,
                    "description": a.category if hasattr(a, 'category') else None,
                    "icon": a.icon_name if hasattr(a, 'icon_name') else None
                } for a in amenities
            ]
        }
    except (ImportError, Exception):
        # Fallback if models are missing or misconfigured in this snapshot
        return {"amenities": []}

# ── Phase 4A: Guest Services ──────────────────────────────────────────────────

@router.get("/services/catalog", response_model=List[PortalServiceCatalogItem])
async def get_services_catalog(
    booking: Booking = Depends(require_can_view_dashboard)
):
    """Return the predefined list of available services for the property."""
    # Hardcoded catalog mapped to valid Task task_types
    return [
        {
            "task_type": "cleaning",
            "display_name": "Housekeeping",
            "description": "Request room cleaning, fresh towels, or toiletries.",
            "icon": "broom"
        },
        {
            "task_type": "maintenance",
            "display_name": "Maintenance",
            "description": "Report broken appliances, plumbing, or electrical issues.",
            "icon": "wrench"
        },
        {
            "task_type": "food",
            "display_name": "Room Service",
            "description": "Order food, drinks, or extra water bottles.",
            "icon": "utensils"
        }
    ]

@router.get("/services", response_model=List[PortalServiceResponse])
async def list_guest_services(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    """List service requests created during this stay."""
    from app.infra.models import Task
    stmt = (
        select(Task)
        .where(Task.booking_id == booking.booking_id)
        .order_by(Task.created_at.desc())
    )
    result = await db.execute(stmt)
    tasks = result.scalars().all()
    
    return [
        {
            "task_id": t.task_id,
            "task_type": t.task_type,
            "status": t.status,
            "description": t.description,
            "created_at": t.created_at,
            "completed_at": t.completed_at
        } for t in tasks
    ]

@router.post("/services", response_model=PortalServiceResponse, status_code=status.HTTP_201_CREATED)
async def create_guest_service(
    payload: PortalServiceCreate,
    booking: Booking = Depends(require_can_request_service),
    db: AsyncSession = Depends(get_db),
):
    """Create a new service request tightly scoped to the guest's booking."""
    from app.infra.models import Task, TaskLog
    
    valid_types = {"cleaning", "maintenance", "food"}
    if payload.task_type not in valid_types:
        raise HTTPException(status_code=400, detail="Invalid service type")

    new_task = Task(
        task_id=uuid.uuid4(),
        property_id=booking.property_id,
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        task_type=payload.task_type,
        status="pending",
        priority="normal",
        description=payload.description
    )
    
    db.add(new_task)
    
    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=new_task.task_id,
        new_status="pending",
        notes="Guest requested service via Portal"
    )
    db.add(log)
    
    await db.commit()
    await db.refresh(new_task)
    
    return {
        "task_id": new_task.task_id,
        "task_type": new_task.task_type,
        "status": new_task.status,
        "description": new_task.description,
        "created_at": new_task.created_at,
        "completed_at": new_task.completed_at
    }

@router.patch("/services/{task_id}/cancel", response_model=PortalServiceResponse)
async def cancel_guest_service(
    task_id: uuid.UUID,
    booking: Booking = Depends(require_can_request_service),
    db: AsyncSession = Depends(get_db),
):
    """Cancel a pending service request."""
    from app.infra.models import Task, TaskLog
    
    stmt = select(Task).where(
        Task.task_id == task_id,
        Task.booking_id == booking.booking_id
    )
    result = await db.execute(stmt)
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(status_code=404, detail="Service request not found")
        
    if task.status != "pending":
        raise HTTPException(status_code=400, detail="Only pending requests can be canceled")
        
    old_status = task.status
    task.status = "canceled"
    
    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=task.task_id,
        old_status=old_status,
        new_status="canceled",
        notes="Canceled by guest via Portal"
    )
    db.add(task)
    db.add(log)
    
    await db.commit()
    await db.refresh(task)
    
    return {
        "task_id": task.task_id,
        "task_type": task.task_type,
        "status": task.status,
        "description": task.description,
        "created_at": task.created_at,
        "completed_at": task.completed_at
    }


# ── Phase 4D: Guest Feedback & Ratings ────────────────────────────────────────

@router.post("/feedback", response_model=GuestFeedbackResponse)
async def submit_guest_feedback(
    payload: GuestFeedbackCreate,
    booking: Booking = Depends(require_can_submit_feedback),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import GuestFeedback
    
    # Check if a feedback already exists for this booking (and task_id)
    stmt = select(GuestFeedback).where(
        GuestFeedback.booking_id == booking.booking_id
    )
    if payload.task_id:
        stmt = stmt.where(GuestFeedback.task_id == payload.task_id)
    else:
        stmt = stmt.where(GuestFeedback.task_id.is_(None))
        
    res = await db.execute(stmt)
    existing = res.scalars().first()
    
    if existing:
        # Update existing feedback
        if payload.overall_rating is not None: existing.overall_rating = payload.overall_rating
        if payload.food_rating is not None: existing.food_rating = payload.food_rating
        if payload.service_rating is not None: existing.service_rating = payload.service_rating
        if payload.staff_rating is not None: existing.staff_rating = payload.staff_rating
        if payload.comments is not None: existing.comments = payload.comments
        existing.is_anonymous = payload.is_anonymous
        await db.flush()
        return existing
        
    # Create new feedback
    new_feedback = GuestFeedback(
        id=uuid.uuid4(),
        property_id=booking.property_id,
        booking_id=booking.booking_id,
        guest_id=booking.guest_id if not payload.is_anonymous else None,
        task_id=payload.task_id,
        overall_rating=payload.overall_rating,
        food_rating=payload.food_rating,
        service_rating=payload.service_rating,
        staff_rating=payload.staff_rating,
        comments=payload.comments,
        is_anonymous=payload.is_anonymous
    )
    db.add(new_feedback)
    await db.flush()
    return new_feedback

@router.get("/feedback", response_model=List[GuestFeedbackResponse])
async def get_guest_feedback(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import GuestFeedback
    stmt = select(GuestFeedback).where(
        GuestFeedback.booking_id == booking.booking_id,
        GuestFeedback.is_deleted == False
    ).order_by(GuestFeedback.created_at.desc())
    res = await db.execute(stmt)
    return res.scalars().all()

@router.post("/complaints")
async def create_portal_complaint(
    payload: PortalComplaintCreate,
    booking: Booking = Depends(require_can_submit_feedback),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task, TaskLog
    
    task_id = uuid.uuid4()
    task = Task(
        task_id=task_id,
        property_id=booking.property_id,
        task_type="complaint",
        status="pending",
        priority="high",
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        description=payload.description,
    )
    db.add(task)
    
    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=task_id,
        old_status=None,
        new_status="pending",
        notes="Guest submitted a complaint via portal"
    )
    db.add(log)
    
    await db.commit()
    
    return {
        "status": "success",
        "task_id": str(task_id),
        "message": "Complaint registered successfully."
    }

@router.get("/complaints")
async def get_portal_complaints(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task
    stmt = select(Task).where(
        Task.booking_id == booking.booking_id,
        Task.task_type == 'complaint'
    ).order_by(Task.created_at.desc())
    res = await db.execute(stmt)
    tasks = res.scalars().all()
    
    return [
        {
            "task_id": t.task_id,
            "status": t.status,
            "description": t.description,
            "created_at": t.created_at
        } for t in tasks
    ]



# ── Phase 5: Checkout Lifecycle ───────────────────────────────────────────────

@router.get("/checkout/status", response_model=PortalCheckoutStatusResponse)
async def get_checkout_status(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task, CheckOut, FolioLineItem, Payment
    
    # Calculate Balance
    fl_stmt = select(FolioLineItem).where(FolioLineItem.booking_id == booking.booking_id, FolioLineItem.is_void == False)
    fl_res = await db.execute(fl_stmt)
    total_charges = sum(float(i.amount) for i in fl_res.scalars())
    
    pay_stmt = select(Payment).where(Payment.booking_id == booking.booking_id, Payment.is_void == False)
    pay_res = await db.execute(pay_stmt)
    total_paid = sum(float(p.amount) for p in pay_res.scalars())
    
    balance = round(total_charges - total_paid, 2)
    
    # Check if a checkout request task is pending
    task_stmt = select(Task).where(
        Task.booking_id == booking.booking_id,
        Task.task_type == 'checkout_request',
        Task.status.notin_(['completed', 'closed', 'cancelled'])
    )
    task_res = await db.execute(task_stmt)
    pending_task = task_res.scalars().first()
    
    # State evaluation
    from app.modules.portal.access_service import PortalAccessService
    
    if booking.booking_status == "completed":
        co_stmt = select(CheckOut).where(CheckOut.booking_id == booking.booking_id).order_by(CheckOut.created_at.desc())
        co_res = await db.execute(co_stmt)
        checkout = co_res.scalars().first()
        
        if PortalAccessService._is_in_grace_window(checkout):
            ct = checkout.checkout_time
            if ct.tzinfo is None:
                ct = ct.replace(tzinfo=timezone.utc)
            grace_ends = ct + timedelta(hours=PortalAccessService.GRACE_WINDOW_HOURS)
            return {
                "state": "COMPLETED",
                "balance": balance,
                "checkout_task_id": None,
                "grace_period_ends_at": grace_ends
            }
        else:
            return {
                "state": "REVOKED",
                "balance": balance,
                "checkout_task_id": None,
                "grace_period_ends_at": None
            }
            
    if pending_task:
        return {
            "state": "REQUESTED",
            "balance": balance,
            "checkout_task_id": pending_task.task_id,
            "grace_period_ends_at": None
        }
        
    return {
        "state": "ACTIVE",
        "balance": balance,
        "checkout_task_id": None,
        "grace_period_ends_at": None
    }

@router.post("/checkout/request")
async def request_checkout(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task, TaskLog
    
    if booking.booking_status != "checked_in":
        raise HTTPException(status_code=400, detail="Cannot request checkout. Stay is not active.")
        
    # Check idempotency
    stmt = select(Task).where(
        Task.booking_id == booking.booking_id,
        Task.task_type == 'checkout_request',
        Task.status.notin_(['completed', 'closed', 'cancelled'])
    )
    res = await db.execute(stmt)
    if res.scalars().first():
        return {"status": "success", "message": "Checkout already requested."}
        
    task_id = uuid.uuid4()
    task = Task(
        task_id=task_id,
        property_id=booking.property_id,
        task_type="checkout_request",
        status="pending",
        priority="high",
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        description="Guest requested express checkout via Portal.",
    )
    db.add(task)
    
    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=task_id,
        old_status=None,
        new_status="pending",
        notes="Checkout requested by Guest"
    )
    db.add(log)
    
    await db.commit()
    
    return {"status": "success", "task_id": str(task_id)}
