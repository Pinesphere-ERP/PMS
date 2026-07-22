import uuid
from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, and_
from datetime import date
from ...infra.database import get_db
from ...infra.models import Booking, Room, Payment, User
from app.core.responses import success_response, StandardResponse

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("", response_model=StandardResponse)
@router.get("/", response_model=StandardResponse)
async def get_dashboard_metrics(property_id: Optional[str] = None, db: AsyncSession = Depends(get_db)):
    today = date.today()
    prop_uuid = None
    if property_id:
        try:
            prop_uuid = uuid.UUID(property_id)
        except ValueError:
            pass
    
    # 1. Arrivals today
    arrivals_stmt = select(func.count()).select_from(Booking).where(
        func.date(Booking.check_in_date) == today,
        Booking.booking_status != 'Cancelled',
        Booking.is_deleted == False
    )
    if prop_uuid:
        arrivals_stmt = arrivals_stmt.where(Booking.property_id == prop_uuid)
    arrivals = (await db.execute(arrivals_stmt)).scalar() or 0

    # 2. Departures today
    departures_stmt = select(func.count()).select_from(Booking).where(
        func.date(Booking.check_out_date) == today,
        Booking.booking_status != 'Cancelled',
        Booking.is_deleted == False
    )
    if prop_uuid:
        departures_stmt = departures_stmt.where(Booking.property_id == prop_uuid)
    departures = (await db.execute(departures_stmt)).scalar() or 0

    # 3. Occupied, Vacant, and Housekeeping Rooms
    occ_stmt = select(func.count()).select_from(Room).where(func.lower(Room.occupancy_status) == 'occupied', Room.is_deleted == False)
    vac_stmt = select(func.count()).select_from(Room).where(func.lower(Room.occupancy_status) == 'vacant', Room.is_deleted == False)
    hk_stmt = select(func.count()).select_from(Room).where(
        or_(Room.housekeeping_status.ilike('cleaning'), Room.housekeeping_status.ilike('maintenance')),
        Room.is_deleted == False
    )
    if prop_uuid:
        occ_stmt = occ_stmt.where(Room.property_id == prop_uuid)
        vac_stmt = vac_stmt.where(Room.property_id == prop_uuid)
        hk_stmt = hk_stmt.where(Room.property_id == prop_uuid)

    occupied = (await db.execute(occ_stmt)).scalar() or 0
    vacant = (await db.execute(vac_stmt)).scalar() or 0
    housekeeping = (await db.execute(hk_stmt)).scalar() or 0

    # 4. Pending Checkouts (Active or checked_in bookings where checkout is today or earlier)
    pending_co_stmt = select(func.count()).select_from(Booking).where(
        Booking.booking_status.in_(['Active', 'checked_in']),
        func.date(Booking.check_out_date) <= today,
        Booking.is_deleted == False
    )
    if prop_uuid:
        pending_co_stmt = pending_co_stmt.where(Booking.property_id == prop_uuid)
    pending_checkouts = (await db.execute(pending_co_stmt)).scalar() or 0

    # 5. Pending Payments
    pending_pay_stmt = select(func.count()).select_from(Booking).where(
        Booking.payment_status.in_(['Pending', 'Partial', 'pending']),
        Booking.booking_status != 'Cancelled',
        Booking.is_deleted == False
    )
    if prop_uuid:
        pending_pay_stmt = pending_pay_stmt.where(Booking.property_id == prop_uuid)
    pending_payments = (await db.execute(pending_pay_stmt)).scalar() or 0

    # 6. Revenue Today
    revenue_stmt = select(func.coalesce(func.sum(Payment.amount), 0.0)).select_from(Payment).join(Booking, Payment.booking_id == Booking.booking_id).where(
        func.date(Payment.created_at) == today,
        func.lower(Payment.status) == 'completed'
    )
    if prop_uuid:
        revenue_stmt = revenue_stmt.where(Booking.property_id == prop_uuid)
    revenue_today = (await db.execute(revenue_stmt)).scalar() or 0.0

    return success_response(data={
        "todays_arrivals": arrivals,
        "todays_departures": departures,
        "occupied_rooms": occupied,
        "vacant_rooms": vacant,
        "pending_checkouts": pending_checkouts,
        "housekeeping_count": housekeeping,
        "pending_payments_count": pending_payments,
        "revenue_today": float(revenue_today)
    })
