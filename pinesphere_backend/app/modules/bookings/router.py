import uuid
from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.core.dependencies import assert_property_access, assert_resource_property_access, get_current_user, require_resource_property_access
from app.infra.models import Booking, Guest, User
from app.modules.bookings.schemas import (
    GuestCreateRequest, GuestResponse,
    BookingCreateRequest, BookingUpdateRequest, BookingResponse,
    BookingListResponse, CheckOutRequest,
)
from app.modules.bookings import service

router = APIRouter()



@router.post("/guests", response_model=GuestResponse, status_code=status.HTTP_201_CREATED)
async def create_guest(
    req: GuestCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new guest record."""
    await assert_property_access(req.property_id, current_user, db)
    return await service.create_guest(db, req)


@router.get("/guests", response_model=List[GuestResponse])
async def list_guests(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property"),
    search: Optional[str] = Query(None, description="Search by name, mobile, or email"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List guests with optional property scope and search."""
    if property_id is None:
        property_id = current_user.property_id
    if property_id is None:
        # A super admin may intentionally request the unscoped operational view.
        from app.core.dependencies import get_current_role
        if (await get_current_role(current_user, db)).role_code != "SUPER_ADMIN":
            raise HTTPException(status_code=403, detail="Property scope required")
    else:
        await assert_property_access(property_id, current_user, db)
    return await service.get_guests(db, property_id=property_id, search=search)


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking(
    req: BookingCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new booking with room availability check."""
    await assert_property_access(req.property_id, current_user, db)
    return await service.create_booking(db, req)


@router.get("", response_model=BookingListResponse)
async def list_bookings(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property"),
    status: Optional[str] = Query(None, description="Filter by booking status (confirmed, cancelled, checked_in, checked_out)"),
    date: Optional[date] = Query(None, description="Filter bookings active on this date"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List bookings with optional filters."""
    if property_id is None:
        property_id = current_user.property_id
    if property_id is not None:
        await assert_property_access(property_id, current_user, db)
    return await service.get_bookings(db, property_id=property_id, status_filter=status, date_filter=date)


@router.get("/{booking_id}", response_model=BookingResponse, dependencies=[Depends(require_resource_property_access(Booking, Booking.booking_id, "booking_id"))])
async def get_booking(
    booking_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get detailed booking information including guest and room."""
    booking = await assert_resource_property_access(Booking, Booking.booking_id, booking_id, current_user, db)
    return await service.get_booking_detail(db, booking_id, booking.property_id)


@router.patch("/{booking_id}", response_model=BookingResponse, dependencies=[Depends(require_resource_property_access(Booking, Booking.booking_id, "booking_id"))])
async def update_booking(
    booking_id: uuid.UUID,
    req: BookingUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update booking fields. Recalculates totals if room_rent changes."""
    booking = await assert_resource_property_access(Booking, Booking.booking_id, booking_id, current_user, db)
    return await service.update_booking(db, booking_id, req, booking.property_id)


@router.post("/{booking_id}/cancel", response_model=BookingResponse, dependencies=[Depends(require_resource_property_access(Booking, Booking.booking_id, "booking_id"))])
async def cancel_booking(
    booking_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Cancel a booking and release the room."""
    booking = await assert_resource_property_access(Booking, Booking.booking_id, booking_id, current_user, db)
    return await service.cancel_booking(db, booking_id, booking.property_id)


@router.post("/{booking_id}/check-in", response_model=BookingResponse, dependencies=[Depends(require_resource_property_access(Booking, Booking.booking_id, "booking_id"))])
async def check_in_booking(
    booking_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Check in a booking and mark the room as occupied."""
    booking = await assert_resource_property_access(Booking, Booking.booking_id, booking_id, current_user, db)
    return await service.check_in_booking(db, booking_id, booking.property_id)


@router.post("/{booking_id}/check-out", response_model=BookingResponse, dependencies=[Depends(require_resource_property_access(Booking, Booking.booking_id, "booking_id"))])
async def check_out_booking(
    booking_id: uuid.UUID,
    req: CheckOutRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Check out a booking, clear outstanding balances, and mark the room as dirty."""
    booking = await assert_resource_property_access(Booking, Booking.booking_id, booking_id, current_user, db)
    return await service.check_out_booking(
        db, 
        booking_id,
        booking.property_id,
        damage_bill=req.damage_bill,
        laundry_bill=req.laundry_bill,
        minibar_bill=req.minibar_bill,
        restaurant_bill=req.restaurant_bill
    )

