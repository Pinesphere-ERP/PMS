from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from datetime import date
from ...infra.database import get_db
from ...infra.models import Booking, Room, Payment, User
from app.core.responses import success_response, StandardResponse

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("/", response_model=StandardResponse)
async def get_dashboard_metrics(property_id: str = None, db: AsyncSession = Depends(get_db)):
    today = date.today()
    
    # Base queries
    bookings_query = select(func.count()).select_from(Booking)
    rooms_query = select(func.count()).select_from(Room)
    
    if property_id:
        bookings_query = bookings_query.filter(Booking.property_id == property_id)
        rooms_query = rooms_query.filter(Room.property_id == property_id)

    # 1. Arrivals today
    arrivals_q = bookings_query.filter(
        func.date(Booking.check_in_date) == today,
        Booking.booking_status != 'Cancelled'
    )
    arrivals = (await db.execute(arrivals_q)).scalar() or 0

    # 2. Departures today
    departures_q = bookings_query.filter(
        func.date(Booking.check_out_date) == today,
        Booking.booking_status != 'Cancelled'
    )
    departures = (await db.execute(departures_q)).scalar() or 0

    # 3. Occupied and Vacant Rooms
    occupied_q = rooms_query.filter(func.lower(Room.occupancy_status) == 'occupied')
    occupied = (await db.execute(occupied_q)).scalar() or 0
    
    vacant_q = rooms_query.filter(func.lower(Room.occupancy_status) == 'vacant')
    vacant = (await db.execute(vacant_q)).scalar() or 0
    
    housekeeping_q = rooms_query.filter(
        Room.housekeeping_status.ilike('cleaning') | Room.housekeeping_status.ilike('maintenance')
    )
    housekeeping = (await db.execute(housekeeping_q)).scalar() or 0

    # 4. Pending Checkouts (Active bookings where checkout is today or earlier)
    pending_checkouts_q = bookings_query.filter(
        Booking.booking_status == 'Active',
        func.date(Booking.check_out_date) <= today
    )
    pending_checkouts = (await db.execute(pending_checkouts_q)).scalar() or 0

    # 5. Pending Payments (Bookings where payment status is pending or partial)
    pending_payments_q = bookings_query.filter(
        Booking.payment_status.in_(['Pending', 'Partial']),
        Booking.booking_status != 'Cancelled'
    )
    pending_payments = (await db.execute(pending_payments_q)).scalar() or 0

    # 6. Revenue Today (Sum of payments made today)
    payments_query = select(func.coalesce(func.sum(Payment.amount), 0.0)).select_from(Payment)
    if property_id:
        payments_query = payments_query.join(Booking).filter(Booking.property_id == property_id)
    
    revenue_q = payments_query.filter(
        func.date(Payment.created_at) == today,
        func.lower(Payment.status) == 'completed'
    )
    revenue_today = (await db.execute(revenue_q)).scalar() or 0.0

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
