import uuid
from datetime import datetime, date, timedelta
from decimal import Decimal
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.models import (
    CheckIn, Booking, Room, RoomCategory, Guest, Invoice, InvoiceItem,
    RoomAssignment, Property
)
from app.core.notifications import whatsapp
from app.core.config import settings
from app.modules.documents.router import create_form_c_on_checkin
from app.modules.audit.logger import AuditLogger
from app.modules.checkin.schemas import (
    CheckInRequest, CheckInResponse, CheckInSearchResult,
    WalkInCheckInRequest, InvoiceResponse, InvoiceItemResponse,
)


async def _generate_invoice_number(db: AsyncSession, property_id: uuid.UUID) -> str:
    prop_stmt = select(Property).where(Property.property_id == property_id)
    prop_res = await db.execute(prop_stmt)
    prop = prop_res.scalar_one_or_none()
    prop_short = prop.property_name[:4].upper() if prop else "PROP"

    cnt_stmt = select(func.count(Invoice.invoice_id)).where(Invoice.property_id == property_id)
    cnt_res = await db.execute(cnt_stmt)
    seq = (cnt_res.scalar() or 0) + 1

    return f"INV-{prop_short}-{seq:05d}"


async def _enrich_checkin_response(db: AsyncSession, checkin: CheckIn) -> CheckInResponse:
    guest_name = None
    room_number = None
    booking_reference = None

    guest_stmt = select(Guest).where(Guest.guest_id == checkin.guest_id, Guest.property_id == checkin.property_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()
    if guest:
        guest_name = guest.full_name

    room_stmt = select(Room).where(Room.room_id == checkin.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room_number = room.room_number

    booking_stmt = select(Booking).where(Booking.booking_id == checkin.booking_id, Booking.property_id == checkin.property_id)
    booking_res = await db.execute(booking_stmt)
    booking = booking_res.scalar_one_or_none()
    if booking:
        booking_reference = f"BK-{str(booking.booking_id)[:8].upper()}"

    return CheckInResponse(
        checkin_id=checkin.checkin_id,
        booking_id=checkin.booking_id,
        room_id=checkin.room_id,
        guest_id=checkin.guest_id,
        property_id=checkin.property_id,
        staff_id=checkin.staff_id,
        deposit=float(checkin.deposit) if checkin.deposit else None,
        advance_paid=float(checkin.advance_paid) if checkin.advance_paid else None,
        id_verified=checkin.id_verified,
        id_verification_notes=checkin.id_verification_notes,
        checked_in_at=checkin.checked_in_at,
        status=checkin.status,
        offline_id=checkin.offline_id,
        special_requests=checkin.special_requests,
        vehicle_number=checkin.vehicle_number,
        parking_required=checkin.parking_required,
        created_at=checkin.created_at,
        updated_at=checkin.updated_at,
        guest_name=guest_name,
        room_number=room_number,
        booking_reference=booking_reference,
    )


async def perform_checkin(
    db: AsyncSession, req: CheckInRequest, property_id: uuid.UUID, current_user_id: Optional[uuid.UUID] = None
) -> CheckInResponse:
    booking_stmt = select(Booking).where(Booking.booking_id == req.booking_id, Booking.property_id == property_id)
    booking_res = await db.execute(booking_stmt)
    booking = booking_res.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.booking_status != "confirmed":
        raise HTTPException(
            status_code=400,
            detail=f"Booking cannot be checked in. Current status is '{booking.booking_status}'. Must be 'confirmed'."
        )

    room_stmt = select(Room).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id).where(Room.room_id == booking.room_id, RoomCategory.property_id == property_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    if room.occupancy_status != "vacant":
        raise HTTPException(
            status_code=400,
            detail=f"Room {room.room_number} is not vacant. Current status: '{room.occupancy_status}'."
        )

    now = datetime.utcnow()
    checkin = CheckIn(
        booking_id=booking.booking_id,
        room_id=booking.room_id,
        guest_id=booking.guest_id,
        property_id=booking.property_id,
        staff_id=req.staff_id or current_user_id,
        deposit=Decimal(str(req.deposit)) if req.deposit is not None else booking.deposit,
        advance_paid=Decimal(str(req.advance_paid)) if req.advance_paid is not None else booking.advance_paid,
        id_verified=req.id_verified,
        id_verification_notes=req.id_verification_notes,
        checked_in_at=now,
        status="active",
        offline_id=req.offline_id,
        special_requests=req.special_requests,
        vehicle_number=req.vehicle_number,
        parking_required=req.parking_required,
    )
    db.add(checkin)
    await db.flush()

    room.occupancy_status = "occupied"
    room.housekeeping_status = "clean"

    booking.booking_status = "checked_in"
    if req.advance_paid is not None:
        booking.advance_paid = Decimal(str(req.advance_paid))
    if req.deposit is not None:
        booking.deposit = Decimal(str(req.deposit))
    booking.vehicle_number = req.vehicle_number or booking.vehicle_number

    nights = max((booking.check_out_date - booking.check_in_date).days, 1)
    rc_stmt = select(RoomCategory).where(RoomCategory.room_category_id == room.room_category_id)
    rc_res = await db.execute(rc_stmt)
    rc = rc_res.scalar_one_or_none()
    room_rent_per_night = float(booking.room_rent / nights) if booking.room_rent else (float(rc.base_price) if rc and rc.base_price else 0)
    room_rent_total = room_rent_per_night * nights
    advance = float(req.advance_paid) if req.advance_paid is not None else float(booking.advance_paid or 0)
    total_payable = room_rent_total - float(booking.discount or 0) + float(booking.taxes or 0)
    balance_due = total_payable - advance

    invoice_number = await _generate_invoice_number(db, booking.property_id)
    invoice = Invoice(
        booking_id=booking.booking_id,
        property_id=booking.property_id,
        guest_id=booking.guest_id,
        invoice_number=invoice_number,
        grand_total=Decimal(str(total_payable)),
        total_paid=Decimal(str(advance)),
        balance_due=Decimal(str(max(balance_due, 0))),
        status="draft",
        generated_at=now,
    )
    db.add(invoice)
    await db.flush()

    invoice_item = InvoiceItem(
        invoice_id=invoice.invoice_id,
        description=f"Room {room.room_number} - {nights} nights",
        category="room_rent",
        quantity=nights,
        unit_price=Decimal(str(room_rent_per_night)),
        total_price=Decimal(str(room_rent_total)),
    )
    db.add(invoice_item)

    room_assignment = RoomAssignment(
        booking_id=booking.booking_id,
        room_id=booking.room_id,
        guest_id=booking.guest_id,
        assigned_at=now,
        is_active=True,
    )
    db.add(room_assignment)
    
    # Check-in gate for foreign nationals -> auto-generate Form C
    guest_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
    guest_res = await db.execute(guest_stmt)
    guest_record = guest_res.scalar_one_or_none()
    
    if guest_record and guest_record.nationality and guest_record.nationality.lower() not in ("indian", "india"):
        # We auto-create the Form C record with a deadline
        await create_form_c_on_checkin(
            db=db,
            guest_id=guest_record.guest_id,
            booking_id=booking.booking_id,
            property_id=property_id
        )

    await AuditLogger.log(
        db,
        property_id=booking.property_id,
        user_id=current_user_id,
        module_name="checkin",
        action_type="check_in",
        target_entity="check_in",
        target_record_id=checkin.checkin_id,
        new_value={
            "booking_id": str(booking.booking_id),
            "room_number": room.room_number,
            "guest_id": str(booking.guest_id),
            "deposit": str(checkin.deposit),
            "advance_paid": str(checkin.advance_paid),
            "id_verified": checkin.id_verified,
            "offline_id": checkin.offline_id,
        },
    )
    await db.commit()
    await db.refresh(checkin)

    # Automate WhatsApp Welcome & Check-In message to guest with portal URL
    if guest_record and guest_record.mobile:
        prop_stmt = select(Property).where(Property.property_id == booking.property_id)
        prop_res = await db.execute(prop_stmt)
        prop_record = prop_res.scalar_one_or_none()
        property_name = prop_record.property_name if prop_record else "Resort"
        portal_url = getattr(settings, "FRONTEND_URL", "http://localhost:3000")

        try:
            await whatsapp.send_checkin_welcome_message(
                phone_number=guest_record.mobile,
                guest_name=guest_record.full_name,
                room_number=room.room_number,
                property_name=property_name,
                check_in_date=str(booking.check_in_date),
                check_out_date=str(booking.check_out_date),
                portal_url=portal_url,
            )
        except Exception as err:
            print(f"[WhatsApp Trigger Warning]: {err}")

    return await _enrich_checkin_response(db, checkin)


async def perform_walkin_checkin(
    db: AsyncSession, req: WalkInCheckInRequest, current_user_id: Optional[uuid.UUID] = None
) -> CheckInResponse:
    room_stmt = select(Room).where(Room.room_id == req.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    curr_status = (room.occupancy_status or "vacant").lower()
    if curr_status not in ("vacant", "available", "clean"):
        raise HTTPException(
            status_code=400,
            detail=f"Room {room.room_number} is not vacant. Current status: '{room.occupancy_status}'."
        )

    guest = Guest(
        property_id=req.property_id,
        full_name=req.guest.full_name,
        mobile=req.guest.mobile,
        email=req.guest.email,
        id_type=req.guest.id_type,
        id_number=req.guest.id_number,
        address=req.guest.address,
        city=req.guest.city,
        state=req.guest.state,
        country=req.guest.country,
        nationality=req.guest.nationality,
        gender=req.guest.gender,
    )
    db.add(guest)
    await db.flush()

    nights = max((req.check_out_date - req.check_in_date).days, 1)
    if req.room_rent:
        room_rent_per_night = float(req.room_rent)
    else:
        rc_stmt = select(RoomCategory).where(RoomCategory.room_category_id == room.room_category_id)
        rc_res = await db.execute(rc_stmt)
        rc = rc_res.scalar_one_or_none()
        base_price = float(rc.base_price) if rc and rc.base_price else 0
        from app.modules.pricing.engine import evaluate_price
        
        # Ensure we pass date objects to evaluate_price
        c_in = req.check_in_date.date() if isinstance(req.check_in_date, datetime) else req.check_in_date
        c_out = req.check_out_date.date() if isinstance(req.check_out_date, datetime) else req.check_out_date
        
        price_data = await evaluate_price(db, req.property_id, c_in, c_out, base_price)
        room_rent_per_night = price_data["final_price"]
        
    room_rent_total = room_rent_per_night * nights
    advance = float(req.advance_paid or 0)
    deposit_val = float(req.deposit or 0)
    total_payable = room_rent_total
    balance_due = total_payable - advance

    booking = Booking(
        property_id=req.property_id,
        room_id=req.room_id,
        guest_id=guest.guest_id,
        booking_type="walkin",
        check_in_date=req.check_in_date,
        check_out_date=req.check_out_date,
        adults=req.adults,
        children=req.children,
        infants=req.infants,
        room_rent=Decimal(str(room_rent_total)),
        deposit=Decimal(str(deposit_val)),
        advance_paid=Decimal(str(advance)),
        total_payable=Decimal(str(total_payable)),
        pending_amount=Decimal(str(max(balance_due, 0))),
        vehicle_number=req.vehicle_number,
        booking_status="confirmed",
        payment_status="paid" if advance >= total_payable else "pending",
    )
    db.add(booking)
    await db.flush()

    checkin_req = CheckInRequest(
        booking_id=booking.booking_id,
        deposit=req.deposit,
        advance_paid=req.advance_paid,
        id_verified=req.id_verified,
        id_verification_notes=req.id_verification_notes,
        special_requests=req.special_requests,
        vehicle_number=req.vehicle_number,
        parking_required=req.parking_required,
        staff_id=req.staff_id,
        offline_id=req.offline_id,
    )

    return await perform_checkin(db, checkin_req, req.property_id, current_user_id)


async def get_checkin_detail(db: AsyncSession, checkin_id: uuid.UUID, property_id: uuid.UUID) -> dict:
    checkin_stmt = select(CheckIn).where(CheckIn.checkin_id == checkin_id, CheckIn.property_id == property_id)
    checkin_res = await db.execute(checkin_stmt)
    checkin = checkin_res.scalar_one_or_none()
    if not checkin:
        raise HTTPException(status_code=404, detail="Check-in record not found")

    guest_stmt = select(Guest).where(Guest.guest_id == checkin.guest_id, Guest.property_id == property_id)
    guest_res = await db.execute(guest_stmt)
    guest = guest_res.scalar_one_or_none()

    room_stmt = select(Room).where(Room.room_id == checkin.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()

    booking_stmt = select(Booking).where(Booking.booking_id == checkin.booking_id, Booking.property_id == property_id)
    booking_res = await db.execute(booking_stmt)
    booking = booking_res.scalar_one_or_none()

    invoice_stmt = select(Invoice).where(Invoice.booking_id == checkin.booking_id, Invoice.property_id == property_id)
    invoice_res = await db.execute(invoice_stmt)
    invoice = invoice_res.scalar_one_or_none()

    invoice_items: list = []
    if invoice:
        items_stmt = select(InvoiceItem).where(InvoiceItem.invoice_id == invoice.invoice_id)
        items_res = await db.execute(items_stmt)
        invoice_items = [
            InvoiceItemResponse(
                item_id=i.item_id,
                description=i.description,
                category=i.category,
                quantity=i.quantity,
                unit_price=float(i.unit_price) if i.unit_price else 0,
                total_price=float(i.total_price) if i.total_price else 0,
            )
            for i in items_res.scalars().all()
        ]

    enriched = await _enrich_checkin_response(db, checkin)

    result = enriched.model_dump()
    result["guest"] = None
    if guest:
        result["guest"] = {
            "guest_id": str(guest.guest_id),
            "full_name": guest.full_name,
            "mobile": guest.mobile,
            "email": guest.email,
            "id_type": guest.id_type,
            "id_number": guest.id_number,
            "nationality": guest.nationality,
        }
    result["room"] = None
    if room:
        rc_stmt = select(RoomCategory).where(RoomCategory.room_category_id == room.room_category_id)
        rc_res = await db.execute(rc_stmt)
        rc = rc_res.scalar_one_or_none()
        result["room"] = {
            "room_id": str(room.room_id),
            "room_number": room.room_number,
            "room_type": rc.room_name if rc else None,
            "occupancy_status": room.occupancy_status,
            "housekeeping_status": room.housekeeping_status,
        }
    result["booking"] = None
    if booking:
        result["booking"] = {
            "booking_id": str(booking.booking_id),
            "booking_status": booking.booking_status,
            "payment_status": booking.payment_status,
            "check_in_date": booking.check_in_date.isoformat() if booking.check_in_date else None,
            "check_out_date": booking.check_out_date.isoformat() if booking.check_out_date else None,
            "adults": booking.adults,
            "children": booking.children,
            "room_rent": float(booking.room_rent) if booking.room_rent else None,
            "total_payable": float(booking.total_payable) if booking.total_payable else None,
            "advance_paid": float(booking.advance_paid) if booking.advance_paid else None,
            "pending_amount": float(booking.pending_amount) if booking.pending_amount else None,
        }
    result["invoice"] = None
    if invoice:
        result["invoice"] = {
            "invoice_id": str(invoice.invoice_id),
            "invoice_number": invoice.invoice_number,
            "grand_total": float(invoice.grand_total) if invoice.grand_total else 0,
            "total_paid": float(invoice.total_paid) if invoice.total_paid else 0,
            "balance_due": float(invoice.balance_due) if invoice.balance_due else 0,
            "status": invoice.status,
            "generated_at": invoice.generated_at.isoformat() if invoice.generated_at else None,
            "items": [item.model_dump() for item in invoice_items],
        }

    return result


async def get_todays_checkins(db: AsyncSession, property_id: uuid.UUID) -> List[CheckInResponse]:
    today_start = datetime.combine(date.today(), datetime.min.time())
    today_end = datetime.combine(date.today(), datetime.max.time())

    stmt = (
        select(CheckIn)
        .where(
            CheckIn.property_id == property_id,
            CheckIn.checked_in_at >= today_start,
            CheckIn.checked_in_at <= today_end,
            CheckIn.is_deleted == False,
        )
        .order_by(CheckIn.checked_in_at.desc())
    )
    res = await db.execute(stmt)
    checkins = res.scalars().all()

    results: List[CheckInResponse] = []
    for c in checkins:
        results.append(await _enrich_checkin_response(db, c))
    return results


async def get_active_checkins(db: AsyncSession, property_id: uuid.UUID) -> List[CheckInResponse]:
    stmt = (
        select(CheckIn)
        .where(
            CheckIn.property_id == property_id,
            CheckIn.status == "active",
            CheckIn.is_deleted == False,
        )
        .order_by(CheckIn.checked_in_at.desc())
    )
    res = await db.execute(stmt)
    checkins = res.scalars().all()

    results: List[CheckInResponse] = []
    for c in checkins:
        results.append(await _enrich_checkin_response(db, c))
    return results


async def cancel_checkin(db: AsyncSession, checkin_id: uuid.UUID, property_id: uuid.UUID) -> CheckInResponse:
    checkin_stmt = select(CheckIn).where(CheckIn.checkin_id == checkin_id, CheckIn.property_id == property_id)
    checkin_res = await db.execute(checkin_stmt)
    checkin = checkin_res.scalar_one_or_none()
    if not checkin:
        raise HTTPException(status_code=404, detail="Check-in record not found")
    if checkin.status != "active":
        raise HTTPException(
            status_code=400,
            detail=f"Check-in cannot be cancelled. Current status: '{checkin.status}'."
        )

    now = datetime.utcnow()

    checkin.status = "cancelled"
    checkin.updated_at = now

    room_stmt = select(Room).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id).where(Room.room_id == checkin.room_id, RoomCategory.property_id == property_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room.occupancy_status = "vacant"
        room.housekeeping_status = "dirty"

    booking_stmt = select(Booking).where(Booking.booking_id == checkin.booking_id, Booking.property_id == property_id)
    booking_res = await db.execute(booking_stmt)
    booking = booking_res.scalar_one_or_none()
    if booking:
        booking.booking_status = "confirmed"

    assign_stmt = select(RoomAssignment).where(
        RoomAssignment.booking_id == checkin.booking_id,
        RoomAssignment.room_id == checkin.room_id,
        RoomAssignment.is_active == True,
    )
    assign_res = await db.execute(assign_stmt)
    assignment = assign_res.scalar_one_or_none()
    if assignment:
        assignment.is_active = False
        assignment.unassigned_at = now

    invoice_stmt = select(Invoice).where(Invoice.booking_id == checkin.booking_id, Invoice.property_id == property_id)
    invoice_res = await db.execute(invoice_stmt)
    invoice = invoice_res.scalar_one_or_none()
    if invoice:
        invoice.status = "cancelled"

    await AuditLogger.log(
        db,
        property_id=checkin.property_id,
        user_id=checkin.staff_id,
        module_name="checkin",
        action_type="cancel_check_in",
        target_entity="check_in",
        target_record_id=checkin.checkin_id,
        old_value={"status": "active"},
        new_value={"status": "cancelled"},
    )
    await db.commit()
    await db.refresh(checkin)
    return await _enrich_checkin_response(db, checkin)
