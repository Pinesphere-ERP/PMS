import uuid
from datetime import date, datetime
from typing import List, Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, desc
from fastapi import HTTPException, status

from app.infra.models import Booking, Guest, Room, RoomCategory, Property
from app.modules.audit.logger import AuditLogger
from app.core.notifications import whatsapp
from app.modules.pricing.engine import evaluate_price
from app.modules.bookings.schemas import (
    GuestCreateRequest, GuestResponse,
    BookingCreateRequest, BookingUpdateRequest, BookingResponse,
    BookingListResponse, CheckInRequest, CheckInResponse,
)


async def create_guest(db: AsyncSession, req: GuestCreateRequest) -> GuestResponse:
    if req.mobile:
        dup_stmt = select(Guest).where(
            Guest.mobile == req.mobile, Guest.property_id == req.property_id
        )
        dup_res = await db.execute(dup_stmt)
        existing_guest = dup_res.scalars().first()
        if existing_guest:
            # F-10 fix: surface the collision rather than silently merging records.
            # If the name matches exactly, treat as a returning guest (safe to reuse).
            # If the name differs, the receptionist fat-fingered a number belonging
            # to a different guest — raise a conflict rather than attach the new
            # booking to the wrong identity (which would also misroute the OTP).
            if existing_guest.full_name.strip().lower() == req.full_name.strip().lower():
                # Returning guest with same name — safe to reuse the record.
                return GuestResponse.model_validate(existing_guest)
            else:
                raise HTTPException(
                    status_code=409,
                    detail=(
                        f"The mobile number {req.mobile} is already registered to a different guest "
                        f"'{existing_guest.full_name}' at this property. "
                        "Please verify the number before proceeding, or use a different mobile number."
                    ),
                )

    prop_stmt = select(Property).where(Property.property_id == req.property_id)
    prop_res = await db.execute(prop_stmt)
    if not prop_res.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Property not found")

    guest = Guest(
        property_id=req.property_id,
        full_name=req.full_name,
        mobile=req.mobile,
        email=req.email,
    )
    db.add(guest)
    await db.flush()
    await db.refresh(guest)
    return GuestResponse.model_validate(guest)


async def get_guests(
    db: AsyncSession,
    property_id: Optional[uuid.UUID] = None,
    search: Optional[str] = None,
) -> List[GuestResponse]:
    stmt = select(Guest).where(Guest.is_deleted == False)
    if property_id:
        stmt = stmt.where(Guest.property_id == property_id)
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(
            or_(
                Guest.full_name.ilike(pattern),
                Guest.mobile.ilike(pattern),
                Guest.email.ilike(pattern),
            )
        )
    stmt = stmt.order_by(desc(Guest.created_at))
    res = await db.execute(stmt)
    guests = res.scalars().all()
    return [GuestResponse.model_validate(g) for g in guests]


async def create_booking(db: AsyncSession, req: BookingCreateRequest) -> BookingResponse:
    prop_stmt = select(Property).where(Property.property_id == req.property_id)
    prop_res = await db.execute(prop_stmt)
    if not prop_res.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Property not found")

    room_stmt = select(Room).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id).where(Room.room_id == req.room_id, RoomCategory.property_id == req.property_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    guest_stmt = select(Guest).where(Guest.guest_id == req.guest_id, Guest.property_id == req.property_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()
    if not guest:
        raise HTTPException(status_code=404, detail="Guest not found")


    if req.check_in_date >= req.check_out_date:
        raise HTTPException(status_code=400, detail="Check-out date must be after check-in date")

    overlap_stmt = select(Booking).where(
        Booking.room_id == req.room_id,
        Booking.booking_status.in_(["upcoming", "confirmed", "checked_in"]),
        Booking.is_deleted == False,
        and_(
            Booking.check_in_date < req.check_out_date,
            Booking.check_out_date > req.check_in_date,
        ),
    )
    overlap_res = await db.execute(overlap_stmt)
    if overlap_res.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Room is not available for the selected dates")

    nights = (req.check_out_date - req.check_in_date).days
    if req.room_rent:
        room_rent = req.room_rent
    else:
        rc_stmt = select(RoomCategory).where(RoomCategory.room_category_id == room.room_category_id)
        rc_res = await db.execute(rc_stmt)
        rc = rc_res.scalar_one_or_none()
        base_price = float(rc.base_price) if rc and rc.base_price else 0
        
        price_data = await evaluate_price(db, req.property_id, req.check_in_date, req.check_out_date, base_price)
        room_rent = price_data["final_price"]
        
    total_rent = room_rent * nights if room_rent else 0
    tax_amount = req.taxes if req.taxes is not None else total_rent * 0.12
    deposit = req.deposit or 0
    discount = req.discount or 0
    total_payable = total_rent + tax_amount + deposit - discount
    if total_payable < 0:
        total_payable = 0
    advance_paid = req.advance_paid or 0
    pending_amount = total_payable - advance_paid
    if pending_amount < 0:
        pending_amount = 0

    booking = Booking(
        property_id=req.property_id,
        room_id=req.room_id,
        guest_id=req.guest_id,
        booking_type=req.booking_type or "online",
        booking_source=req.booking_source,
        broker_user_id=req.broker_user_id if hasattr(req, 'broker_user_id') else None,
        check_in_date=req.check_in_date,
        check_out_date=req.check_out_date,
        adults=req.adults,
        children=req.children,
        room_rent=room_rent,
        deposit=deposit,
        discount=discount,
        taxes=tax_amount,
        total_payable=total_payable,
        advance_paid=advance_paid,
        pending_amount=pending_amount,
        notes=req.notes,
        booking_status=getattr(req, "booking_status", None) or "upcoming",
        payment_status="partially_paid" if advance_paid > 0 else "pending",
    )
    db.add(booking)
    await db.flush()
    # F-05: generate a unique, human-readable booking reference after the
    # booking_id UUID is available.  Format: BK-{first 8 hex chars of UUID}.
    booking.booking_reference = f"BK-{booking.booking_id.hex[:8].upper()}"
    await db.flush()
    await db.refresh(booking)

    await AuditLogger.log(
        db,
        module_name="bookings",
        action_type="create_booking",
        target_entity="booking",
        target_record_id=booking.booking_id,
        property_id=req.property_id,
        new_value={
            "booking_id": str(booking.booking_id),
            "room_id": str(req.room_id),
            "guest_id": str(req.guest_id),
            "check_in_date": str(req.check_in_date),
            "check_out_date": str(req.check_out_date),
            "total_payable": float(total_payable),
        },
    )

    # WhatsApp Integration: Send Booking Confirmation
    if guest.mobile:
        try:
            # Handle sync/async differences in datetime depending on how check_in_date is passed
            if isinstance(booking.check_in_date, date) and not isinstance(booking.check_in_date, datetime):
                dt = datetime.combine(booking.check_in_date, datetime.min.time())
            else:
                dt = booking.check_in_date
            await whatsapp.send_booking_confirmation(
                phone_number=guest.mobile,
                booking_ref=f"BKG-{str(booking.booking_id)[:8].upper()}",
                guest_name=guest.full_name,
                check_in_date=dt
            )
        except Exception as e:
            print(f"Failed to send WhatsApp message: {e}")

    return await enrich_booking_response(db, booking)


async def get_bookings(
    db: AsyncSession,
    property_id: Optional[uuid.UUID] = None,
    status_filter: Optional[str] = None,
    date_filter: Optional[date] = None,
) -> BookingListResponse:
    stmt = select(Booking).where(Booking.is_deleted == False)
    if property_id:
        stmt = stmt.where(Booking.property_id == property_id)
    if status_filter:
        stmt = stmt.where(Booking.booking_status == status_filter)
    if date_filter:
        stmt = stmt.where(
            and_(
                Booking.check_in_date <= date_filter,
                Booking.check_out_date > date_filter,
            )
        )
    count_stmt = select(func.count()).select_from(stmt.subquery())
    cnt_res = await db.execute(count_stmt)
    total = cnt_res.scalar() or 0

    stmt = stmt.order_by(desc(Booking.created_at))
    res = await db.execute(stmt)
    bookings = res.scalars().all()

    items = []
    for b in bookings:
        items.append(await enrich_booking_response(db, b))

    return BookingListResponse(total=total, items=items)


async def get_booking_detail(db: AsyncSession, booking_id: uuid.UUID, property_id: uuid.UUID) -> BookingResponse:
    stmt = select(Booking).where(
        Booking.booking_id == booking_id,
        Booking.property_id == property_id,
        Booking.is_deleted == False,
    )
    res = await db.execute(stmt)
    booking = res.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return await enrich_booking_response(db, booking)


async def update_booking(db: AsyncSession, booking_id: uuid.UUID, req: BookingUpdateRequest, property_id: uuid.UUID) -> BookingResponse:
    stmt = select(Booking).where(
        Booking.booking_id == booking_id,
        Booking.property_id == property_id,
        Booking.is_deleted == False,
    )
    res = await db.execute(stmt)
    booking = res.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.booking_status == "cancelled":
        raise HTTPException(status_code=400, detail="Cannot update a cancelled booking")

    update_data = req.model_dump(exclude_unset=True)

    target_room_id = update_data.get("room_id", booking.room_id)
    target_check_in = update_data.get("check_in_date", booking.check_in_date)
    target_check_out = update_data.get("check_out_date", booking.check_out_date)

    if target_check_in >= target_check_out:
        raise HTTPException(status_code=400, detail="Check-out date must be after check-in date")

    if "room_id" in update_data or "check_in_date" in update_data or "check_out_date" in update_data:
        if "room_id" in update_data and update_data["room_id"] != booking.room_id:
            room_stmt = select(Room).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id).where(Room.room_id == update_data["room_id"], RoomCategory.property_id == property_id)
            room_res = await db.execute(room_stmt)
            if not room_res.scalar_one_or_none():
                raise HTTPException(status_code=404, detail="New room not found")

        overlap_stmt = select(Booking).where(
            Booking.room_id == target_room_id,
            Booking.booking_status.in_(["upcoming", "confirmed", "checked_in"]),
            Booking.is_deleted == False,
            Booking.booking_id != booking_id,
            and_(
                Booking.check_in_date < target_check_out,
                Booking.check_out_date > target_check_in,
            ),
        )
        overlap_res = await db.execute(overlap_stmt)
        if overlap_res.scalar_one_or_none():
            raise HTTPException(status_code=409, detail="Room is not available for the selected dates")

    for field, value in update_data.items():
        setattr(booking, field, value)

    check_in = booking.check_in_date
    check_out = booking.check_out_date
    if check_in >= check_out:
        raise HTTPException(status_code=400, detail="Check-out date must be after check-in date")

    if booking.room_rent is not None:
        nights = (check_out - check_in).days
        total_rent = booking.room_rent * nights
        tax_amount = booking.taxes if booking.taxes is not None else total_rent * 0.12
        deposit = booking.deposit or 0
        discount = booking.discount or 0
        booking.total_payable = total_rent + tax_amount + deposit - discount
        if booking.total_payable < 0:
            booking.total_payable = 0
        booking.pending_amount = booking.total_payable - (booking.advance_paid or 0)
        if booking.pending_amount < 0:
            booking.pending_amount = 0

    await db.flush()
    await db.refresh(booking)

    await AuditLogger.log(
        db,
        module_name="bookings",
        action_type="update_booking",
        target_entity="booking",
        target_record_id=booking.booking_id,
        property_id=booking.property_id,
        new_value={"updated_fields": list(update_data.keys())},
    )

    return await enrich_booking_response(db, booking)


async def cancel_booking(db: AsyncSession, booking_id: uuid.UUID, property_id: uuid.UUID) -> BookingResponse:
    stmt = select(Booking).where(
        Booking.booking_id == booking_id,
        Booking.property_id == property_id,
        Booking.is_deleted == False,
    )
    res = await db.execute(stmt)
    booking = res.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.booking_status == "cancelled":
        raise HTTPException(status_code=400, detail="Booking is already cancelled")

    if booking.booking_status == "checked_out":
        raise HTTPException(status_code=400, detail="Cannot cancel a checked-out booking")

    booking.booking_status = "cancelled"
    await db.flush()
    await db.refresh(booking)

    await AuditLogger.log(
        db,
        module_name="bookings",
        action_type="cancel_booking",
        target_entity="booking",
        target_record_id=booking.booking_id,
        property_id=booking.property_id,
        old_value={"booking_status": "confirmed"},
        new_value={"booking_status": "cancelled"},
    )

    return await enrich_booking_response(db, booking)


async def enrich_booking_response(db: AsyncSession, booking: Booking) -> BookingResponse:
    guest_name = None
    guest_mobile = None
    room_number = None

    if booking.guest_id:
        g_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
        g_res = await db.execute(g_stmt)
        g = g_res.scalar_one_or_none()
        if g:
            guest_name = g.full_name
            guest_mobile = g.mobile

    if booking.room_id:
        r_stmt = select(Room).where(Room.room_id == booking.room_id)
        r_res = await db.execute(r_stmt)
        r = r_res.scalar_one_or_none()
        if r:
            room_number = r.room_number

    resp = BookingResponse.model_validate(booking)
    resp.guest_name = guest_name
    resp.guest_mobile = guest_mobile
    resp.room_number = room_number
    return resp


async def check_in_booking(db: AsyncSession, booking_id: uuid.UUID, property_id: uuid.UUID) -> BookingResponse:
    stmt = select(Booking).where(Booking.booking_id == booking_id, Booking.property_id == property_id, Booking.is_deleted == False)
    res = await db.execute(stmt)
    booking = res.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.booking_status not in ["upcoming", "confirmed"]:
        raise HTTPException(
            status_code=400,
            detail=f"Booking cannot be checked in. Current status is '{booking.booking_status}'. Must be 'upcoming' or 'confirmed'."
        )
        
    booking.booking_status = "checked_in"
    
    room_stmt = select(Room).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id).where(Room.room_id == booking.room_id, RoomCategory.property_id == property_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room.occupancy_status = "occupied"
        db.add(room)
        
    db.add(booking)
    await db.flush()
    await db.refresh(booking)
    return await enrich_booking_response(db, booking)


async def check_out_booking(db: AsyncSession, booking_id: uuid.UUID, property_id: uuid.UUID, damage_bill: float = 0, laundry_bill: float = 0, minibar_bill: float = 0, restaurant_bill: float = 0) -> BookingResponse:
    stmt = select(Booking).where(Booking.booking_id == booking_id, Booking.property_id == property_id, Booking.is_deleted == False)
    res = await db.execute(stmt)
    booking = res.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    booking.booking_status = "checked_out"
    booking.payment_status = "paid"
    
    # We can add these bills to total payable or record them
    extra_charges = damage_bill + laundry_bill + minibar_bill + restaurant_bill
    if booking.total_payable is not None:
        booking.total_payable = float(booking.total_payable) + extra_charges
    booking.pending_amount = 0.0
    
    room_stmt = select(Room).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id).where(Room.room_id == booking.room_id, RoomCategory.property_id == property_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room.occupancy_status = "vacant"
        room.housekeeping_status = "cleaning"
        db.add(room)
        
    db.add(booking)
    await db.flush()
    await db.refresh(booking)
    return await enrich_booking_response(db, booking)

