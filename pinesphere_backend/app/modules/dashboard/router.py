from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date
from ...infra.database import get_db
from ...infra.models import Booking, Room, Payment, User
from app.core.responses import success_response, StandardResponse

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("/", response_model=StandardResponse)
def get_dashboard_metrics(property_id: str = None, db: Session = Depends(get_db)):
    today = date.today()
    
    # Base queries
    bookings_query = db.query(Booking)
    rooms_query = db.query(Room)
    payments_query = db.query(Payment)
    
    if property_id:
        bookings_query = bookings_query.filter(Booking.property_id == property_id)
        rooms_query = rooms_query.filter(Room.property_id == property_id)
        payments_query = payments_query.join(Booking).filter(Booking.property_id == property_id)

    # 1. Arrivals today
    arrivals = bookings_query.filter(
        func.date(Booking.check_in_date) == today,
        Booking.booking_status != 'Cancelled'
    ).count()

    # 2. Departures today
    departures = bookings_query.filter(
        func.date(Booking.check_out_date) == today,
        Booking.booking_status != 'Cancelled'
    ).count()

    # 3. Occupied and Vacant Rooms
    occupied = rooms_query.filter(func.lower(Room.occupancy_status) == 'occupied').count()
    vacant = rooms_query.filter(func.lower(Room.occupancy_status) == 'vacant').count()
    housekeeping = rooms_query.filter(
        Room.housekeeping_status.ilike('cleaning') | Room.housekeeping_status.ilike('maintenance')
    ).count()

    # 4. Pending Checkouts (Active bookings where checkout is today or earlier)
    pending_checkouts = bookings_query.filter(
        Booking.booking_status == 'Active',
        func.date(Booking.check_out_date) <= today
    ).count()

    # 5. Pending Payments (Bookings where payment status is pending or partial)
    pending_payments = bookings_query.filter(
        Booking.payment_status.in_(['Pending', 'Partial']),
        Booking.booking_status != 'Cancelled'
    ).count()

    # 6. Revenue Today (Sum of payments made today)
    revenue_today = payments_query.filter(
        func.date(Payment.created_at) == today,
        func.lower(Payment.status) == 'completed'
    ).with_entities(func.coalesce(func.sum(Payment.amount), 0.0)).scalar()

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
