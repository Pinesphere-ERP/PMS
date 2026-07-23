import uuid
from datetime import date, datetime, timezone
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc, func
from fastapi import HTTPException

from app.infra.models import (
    CheckOut, CheckIn, Booking, Room, RoomCategory, Guest,
    Invoice, InvoiceItem, User, Property, HousekeepingRoomStatus,
)
from app.core.notifications import whatsapp
from app.core.config import settings
from app.modules.housekeeping.service import _notify_housekeepers
from app.modules.audit.logger import AuditLogger
from app.modules.checkout.schemas import (
    CheckOutRequest, CheckOutResponse,
    PendingCheckoutItem, CheckoutBillingDetail,
)


async def perform_checkout(
    db: AsyncSession,
    req: CheckOutRequest,
    property_id: uuid.UUID,
    current_user_id: Optional[uuid.UUID] = None,
) -> CheckOutResponse:
    ci_stmt = select(CheckIn).where(CheckIn.checkin_id == req.checkin_id, CheckIn.property_id == property_id)
    ci_res = await db.execute(ci_stmt)
    checkin = ci_res.scalar_one_or_none()
    if not checkin:
        raise HTTPException(status_code=404, detail="Check-in record not found")
    if checkin.status != "active":
        raise HTTPException(
            status_code=400,
            detail=f"Cannot check out. Check-in status is '{checkin.status}', expected 'active'",
        )

    bk_stmt = select(Booking).where(Booking.booking_id == checkin.booking_id, Booking.property_id == property_id)
    bk_res = await db.execute(bk_stmt)
    booking = bk_res.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Associated booking not found")

    rm_stmt = select(Room).where(Room.room_id == checkin.room_id)
    rm_res = await db.execute(rm_stmt)
    room = rm_res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Associated room not found")

    now = datetime.now(timezone.utc)

    checkin_date = checkin.checked_in_at.date() if checkin.checked_in_at else booking.check_in_date
    checkout_date = now.date()
    nights_stayed = (checkout_date - checkin_date).days
    if nights_stayed < 1:
        nights_stayed = 1

    room_rent_per_night = float(booking.room_rent) if booking.room_rent else 0
    calculated_room_charges = room_rent_per_night * nights_stayed
    room_charges = req.room_charges if req.room_charges is not None else calculated_room_charges

    total_charges = (
        room_charges
        + req.restaurant_charges
        + req.laundry_charges
        + req.minibar_charges
        + req.damage_charges
        + req.miscellaneous_charges
    )
    after_discount = total_charges - req.discount
    if after_discount < 0:
        after_discount = 0
    total_amount = after_discount + req.gst

    advance_paid = float(checkin.advance_paid) if checkin.advance_paid else 0
    remaining_balance = total_amount - advance_paid
    refund_amount = 0.0
    if remaining_balance < 0:
        refund_amount = abs(remaining_balance)
        remaining_balance = 0.0

    if remaining_balance <= 0:
        payment_status = "paid"
    else:
        payment_status = "pending"

    checkout = CheckOut(
        checkin_id=checkin.checkin_id,
        booking_id=booking.booking_id,
        room_id=room.room_id,
        property_id=checkin.property_id,
        staff_id=req.staff_id or current_user_id,
        checkout_time=now,
        room_charges=room_charges,
        restaurant_charges=req.restaurant_charges,
        laundry_charges=req.laundry_charges,
        minibar_charges=req.minibar_charges,
        damage_charges=req.damage_charges,
        miscellaneous_charges=req.miscellaneous_charges,
        discount=req.discount,
        gst=req.gst,
        total_amount=total_amount,
        advance_paid=advance_paid,
        remaining_balance=remaining_balance,
        refund_amount=refund_amount,
        payment_status=payment_status,
        key_returned=req.key_returned,
        id_returned=req.id_returned,
        feedback_submitted=False,
        remarks=req.remarks,
        checkout_status="completed",
    )
    db.add(checkout)
    await db.flush()

    inv_stmt = select(Invoice).where(
        Invoice.booking_id == booking.booking_id,
        Invoice.property_id == checkin.property_id,
    )
    inv_res = await db.execute(inv_stmt)
    invoice = inv_res.scalar_one_or_none()

    if not invoice:
        invoice_number = f"INV-{booking.booking_id.hex[:8].upper()}-{now.strftime('%Y%m%d%H%M%S')}"
        invoice = Invoice(
            booking_id=booking.booking_id,
            property_id=checkin.property_id,
            guest_id=booking.guest_id,
            invoice_number=invoice_number,
            grand_total=total_amount,
            total_paid=advance_paid,
            balance_due=remaining_balance,
            status="final",
            generated_at=now,
        )
        db.add(invoice)
        await db.flush()
    else:
        invoice.grand_total = total_amount
        invoice.total_paid = advance_paid
        invoice.balance_due = remaining_balance
        invoice.status = "final"
        invoice.generated_at = now
        await db.flush()

    charge_items = [
        ("Room Charges", "room", room_charges),
        ("Restaurant Charges", "restaurant", req.restaurant_charges),
        ("Laundry Charges", "laundry", req.laundry_charges),
        ("Minibar Charges", "minibar", req.minibar_charges),
        ("Damage Charges", "damage", req.damage_charges),
        ("Miscellaneous Charges", "miscellaneous", req.miscellaneous_charges),
        ("Discount", "discount", -req.discount if req.discount > 0 else 0),
        ("GST", "tax", req.gst),
    ]

    for description, category, amount in charge_items:
        if category == "discount" and req.discount <= 0:
            continue
        if category != "discount" and amount <= 0:
            continue
        item = InvoiceItem(
            invoice_id=invoice.invoice_id,
            description=description,
            category=category,
            quantity=1,
            unit_price=amount,
            total_price=amount,
        )
        db.add(item)

    checkin.status = "completed"
    await db.flush()

    room.occupancy_status = "vacant"
    room.housekeeping_status = "dirty"
    
    # Update new housekeeping_room_status table
    hk_stmt = select(HousekeepingRoomStatus).where(HousekeepingRoomStatus.room_id == room.room_id)
    hk_res = await db.execute(hk_stmt)
    hk_status = hk_res.scalar_one_or_none()
    if hk_status:
        hk_status.clean_status = "not_cleaned"
        if current_user_id:
            hk_status.updated_by = current_user_id
        await _notify_housekeepers(db, hk_status)

    # Auto-generate Housekeeping Task
    from app.modules.housekeeping.schemas import HousekeepingTaskCreate
    from app.modules.housekeeping.service import create_task
    try:
        task_req = HousekeepingTaskCreate(
            room_id=room.room_id,
            property_id=room.property_id,
            priority="medium",
            remarks="Auto-generated upon checkout"
        )
        await create_task(db, task_req, current_user_id)
    except Exception as e:
        print(f"Failed to auto-generate housekeeping task on checkout: {e}")

    await db.flush()

    booking.booking_status = "completed"
    if remaining_balance <= 0:
        booking.payment_status = "paid"
    else:
        booking.payment_status = "partial"
    await db.flush()

    staff_user_name = "System"
    if current_user_id:
        usr_stmt = select(User).where(User.id == current_user_id)
        usr_res = await db.execute(usr_stmt)
        usr = usr_res.scalar_one_or_none()
        if usr:
            staff_user_name = usr.name

    await AuditLogger.log(
        db,
        property_id=checkin.property_id,
        user_id=current_user_id,
        module_name="checkout",
        action_type="check_out",
        target_entity="check_out",
        target_record_id=checkout.checkout_id,
        new_value={
            "checkin_id": str(checkin.checkin_id),
            "booking_id": str(booking.booking_id),
            "room_number": room.room_number,
            "total_amount": total_amount,
            "advance_paid": advance_paid,
            "remaining_balance": remaining_balance,
            "refund_amount": refund_amount,
            "payment_status": payment_status,
            "key_returned": req.key_returned,
            "id_returned": req.id_returned,
            "staff": staff_user_name,
        },
    )
    await db.commit()
    await db.refresh(checkout)

    # Automate WhatsApp Thank You & Financial Summary message on checkout
    try:
        guest_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
        guest_res = await db.execute(guest_stmt)
        guest_record = guest_res.scalar_one_or_none()

        if guest_record and guest_record.mobile:
            prop_stmt = select(Property).where(Property.property_id == checkin.property_id)
            prop_res = await db.execute(prop_stmt)
            prop_record = prop_res.scalar_one_or_none()
            property_name = prop_record.property_name if prop_record else "Resort"
            portal_url = getattr(settings, "FRONTEND_URL", "http://localhost:3000")
            inv_id = str(invoice.invoice_id) if invoice else str(booking.booking_id)
            invoice_url = f"{portal_url}/invoice/{inv_id}"

            await whatsapp.send_checkout_thankyou_message(
                phone_number=guest_record.mobile,
                guest_name=guest_record.full_name,
                property_name=property_name,
                room_number=room.room_number,
                room_charges=float(room_charges),
                restaurant_charges=float(req.restaurant_charges),
                other_charges=float(req.laundry_charges + req.minibar_charges + req.damage_charges + req.miscellaneous_charges),
                taxes=float(req.gst),
                total_amount=float(total_amount),
                total_paid=float(advance_paid),
                invoice_url=invoice_url,
            )
    except Exception as err:
        print(f"[WhatsApp Checkout Trigger Warning]: {err}")

    return await _enrich_checkout_response(db, checkout)


async def get_pending_checkouts(
    db: AsyncSession,
    property_id: Optional[uuid.UUID] = None,
) -> List[PendingCheckoutItem]:
    today = date.today()
    stmt = (
        select(CheckIn)
        .where(CheckIn.status == "active")
        .order_by(desc(CheckIn.checked_in_at))
    )
    if property_id:
        stmt = stmt.where(CheckIn.property_id == property_id)

    res = await db.execute(stmt)
    checkins = res.scalars().all()

    items: List[PendingCheckoutItem] = []
    for ci in checkins:
        bk_stmt = select(Booking).where(Booking.booking_id == ci.booking_id)
        bk_res = await db.execute(bk_stmt)
        booking = bk_res.scalar_one_or_none()
        if not booking:
            continue

        rm_stmt = select(Room).where(Room.room_id == ci.room_id)
        rm_res = await db.execute(rm_stmt)
        room = rm_res.scalar_one_or_none()

        gt_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
        gt_res = await db.execute(gt_stmt)
        guest = gt_res.scalar_one_or_none()

        guest_name = guest.full_name if guest else "Unknown Guest"
        room_number = room.room_number if room else "N/A"
        room_type = None
        if room:
            rc_stmt2 = select(RoomCategory).where(RoomCategory.room_category_id == room.room_category_id)
            rc_res2 = await db.execute(rc_stmt2)
            rc2 = rc_res2.scalar_one_or_none()
            room_type = rc2.room_name if rc2 else None

        checkin_dt = ci.checked_in_at.date() if ci.checked_in_at else today
        days_since = (today - checkin_dt).days
        is_overdue = today > booking.check_out_date

        room_rent = float(booking.room_rent) if booking.room_rent else 0
        nights_expected = (booking.check_out_date - booking.check_in_date).days
        if nights_expected < 1:
            nights_expected = 1
        estimated_total = room_rent * nights_expected

        items.append(PendingCheckoutItem(
            checkin_id=ci.checkin_id,
            booking_id=booking.booking_id,
            room_id=ci.room_id,
            property_id=ci.property_id,
            guest_id=booking.guest_id,
            guest_name=guest_name,
            room_number=room_number,
            room_type=room_type,
            check_in_date=booking.check_in_date,
            check_out_date=booking.check_out_date,
            checked_in_at=ci.checked_in_at,
            adults=booking.adults,
            children=booking.children,
            room_rent=room_rent,
            advance_paid=float(booking.advance_paid) if booking.advance_paid else 0,
            estimated_total=estimated_total,
            is_overdue=is_overdue,
            days_since_checkin=days_since,
        ))

    return items


async def get_checkout_detail(
    db: AsyncSession,
    checkout_id: uuid.UUID,
) -> CheckOutResponse:
    stmt = select(CheckOut).where(CheckOut.checkout_id == checkout_id)
    res = await db.execute(stmt)
    checkout = res.scalar_one_or_none()
    if not checkout:
        raise HTTPException(status_code=404, detail="Check-out record not found")
    return await _enrich_checkout_response(db, checkout)


async def get_checkout_billing(
    db: AsyncSession,
    checkin_id: uuid.UUID,
) -> CheckoutBillingDetail:
    ci_stmt = select(CheckIn).where(CheckIn.checkin_id == checkin_id)
    ci_res = await db.execute(ci_stmt)
    checkin = ci_res.scalar_one_or_none()
    if not checkin:
        raise HTTPException(status_code=404, detail="Check-in record not found")

    bk_stmt = select(Booking).where(Booking.booking_id == checkin.booking_id)
    bk_res = await db.execute(bk_stmt)
    booking = bk_res.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Associated booking not found")

    rm_stmt = select(Room).where(Room.room_id == checkin.room_id)
    rm_res = await db.execute(rm_stmt)
    room = rm_res.scalar_one_or_none()

    rc = None
    if room:
        rc_stmt = select(RoomCategory).where(RoomCategory.room_category_id == room.room_category_id)
        rc_res = await db.execute(rc_stmt)
        rc = rc_res.scalar_one_or_none()

    gt_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
    gt_res = await db.execute(gt_stmt)
    guest = gt_res.scalar_one_or_none()

    today = date.today()
    checkin_date = checkin.checked_in_at.date() if checkin.checked_in_at else booking.check_in_date
    nights_stayed = (today - checkin_date).days
    if nights_stayed < 1:
        nights_stayed = 1

    room_rent = float(booking.room_rent) if booking.room_rent else 0
    room_charges = room_rent * nights_stayed

    subtotal = room_charges
    grand_total = subtotal
    advance_paid = float(checkin.advance_paid) if checkin.advance_paid else 0
    remaining_balance = grand_total - advance_paid
    if remaining_balance < 0:
        remaining_balance = 0

    is_overdue = today > booking.check_out_date
    overdue_days = (today - booking.check_out_date).days if is_overdue else 0

    return CheckoutBillingDetail(
        checkin_id=checkin.checkin_id,
        booking_id=booking.booking_id,
        guest_name=guest.full_name if guest else "Unknown Guest",
        room_number=room.room_number if room else "N/A",
        room_type=rc.room_name if rc else None,
        check_in_date=booking.check_in_date,
        check_out_date=booking.check_out_date,
        checked_in_at=checkin.checked_in_at,
        checkout_date_today=today,
        nights_stayed=nights_stayed,
        room_rent_per_night=room_rent,
        room_charges=room_charges,
        restaurant_charges=0,
        laundry_charges=0,
        minibar_charges=0,
        damage_charges=0,
        miscellaneous_charges=0,
        subtotal=subtotal,
        discount=0,
        gst=0,
        grand_total=grand_total,
        advance_paid=advance_paid,
        remaining_balance=remaining_balance,
        deposit=float(checkin.deposit) if checkin.deposit else 0,
        is_overdue=is_overdue,
        overdue_days=overdue_days,
    )


async def get_todays_checkouts(
    db: AsyncSession,
    property_id: Optional[uuid.UUID] = None,
) -> List[CheckOutResponse]:
    today = date.today()
    start_of_day = datetime.combine(today, datetime.min.time).replace(tzinfo=timezone.utc)
    end_of_day = datetime.combine(today, datetime.max.time).replace(tzinfo=timezone.utc)

    stmt = (
        select(CheckOut)
        .where(
            and_(
                CheckOut.checkout_time >= start_of_day,
                CheckOut.checkout_time <= end_of_day,
                CheckOut.checkout_status == "completed",
            )
        )
        .order_by(desc(CheckOut.checkout_time))
    )
    if property_id:
        stmt = stmt.where(CheckOut.property_id == property_id)

    res = await db.execute(stmt)
    checkouts = res.scalars().all()

    return [await _enrich_checkout_response(db, co) for co in checkouts]


async def _enrich_checkout_response(
    db: AsyncSession,
    checkout: CheckOut,
) -> CheckOutResponse:
    guest_name = None
    room_number = None
    booking_reference = None

    if checkout.booking_id:
        bk_stmt = select(Booking).where(Booking.booking_id == checkout.booking_id)
        bk_res = await db.execute(bk_stmt)
        booking = bk_res.scalar_one_or_none()
        if booking:
            booking_reference = f"BK-{booking.booking_id.hex[:8].upper()}"

            if booking.guest_id:
                gt_stmt = select(Guest).where(Guest.guest_id == booking.guest_id)
                gt_res = await db.execute(gt_stmt)
                guest = gt_res.scalar_one_or_none()
                if guest:
                    guest_name = guest.full_name

    if checkout.room_id:
        rm_stmt = select(Room).where(Room.room_id == checkout.room_id)
        rm_res = await db.execute(rm_stmt)
        room = rm_res.scalar_one_or_none()
        if room:
            room_number = room.room_number

    return CheckOutResponse(
        checkout_id=checkout.checkout_id,
        checkin_id=checkout.checkin_id,
        booking_id=checkout.booking_id,
        room_id=checkout.room_id,
        property_id=checkout.property_id,
        staff_id=checkout.staff_id,
        checkout_time=checkout.checkout_time,
        room_charges=float(checkout.room_charges) if checkout.room_charges else 0,
        restaurant_charges=float(checkout.restaurant_charges) if checkout.restaurant_charges else 0,
        laundry_charges=float(checkout.laundry_charges) if checkout.laundry_charges else 0,
        minibar_charges=float(checkout.minibar_charges) if checkout.minibar_charges else 0,
        damage_charges=float(checkout.damage_charges) if checkout.damage_charges else 0,
        miscellaneous_charges=float(checkout.miscellaneous_charges) if checkout.miscellaneous_charges else 0,
        discount=float(checkout.discount) if checkout.discount else 0,
        gst=float(checkout.gst) if checkout.gst else 0,
        total_amount=float(checkout.total_amount) if checkout.total_amount else 0,
        advance_paid=float(checkout.advance_paid) if checkout.advance_paid else 0,
        remaining_balance=float(checkout.remaining_balance) if checkout.remaining_balance else 0,
        refund_amount=float(checkout.refund_amount) if checkout.refund_amount else 0,
        payment_status=checkout.payment_status,
        key_returned=checkout.key_returned,
        id_returned=checkout.id_returned,
        feedback_submitted=checkout.feedback_submitted,
        remarks=checkout.remarks,
        checkout_status=checkout.checkout_status,
        created_at=checkout.created_at,
        updated_at=checkout.updated_at,
        guest_name=guest_name,
        room_number=room_number,
        booking_reference=booking_reference,
    )
