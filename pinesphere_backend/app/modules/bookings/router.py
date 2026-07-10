import uuid
from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.modules.bookings.schemas import (
    GuestCreateRequest, GuestResponse,
    BookingCreateRequest, BookingUpdateRequest, BookingResponse,
    BookingListResponse,
)
from app.modules.bookings import service

router = APIRouter()


@router.post("/guests", response_model=GuestResponse, status_code=status.HTTP_201_CREATED)
async def create_guest(
    req: GuestCreateRequest,
    db: AsyncSession = Depends(get_db),
):
    """Create a new guest record."""
    return await service.create_guest(db, req)


@router.get("/guests", response_model=List[GuestResponse])
async def list_guests(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property"),
    search: Optional[str] = Query(None, description="Search by name, mobile, or email"),
    db: AsyncSession = Depends(get_db),
):
    """List guests with optional property scope and search."""
    return await service.get_guests(db, property_id=property_id, search=search)


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking(
    req: BookingCreateRequest,
    db: AsyncSession = Depends(get_db),
):
    """Create a new booking with room availability check."""
    return await service.create_booking(db, req)


@router.get("", response_model=BookingListResponse)
async def list_bookings(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property"),
    status: Optional[str] = Query(None, description="Filter by booking status (confirmed, cancelled, checked_in, checked_out)"),
    date: Optional[date] = Query(None, description="Filter bookings active on this date"),
    db: AsyncSession = Depends(get_db),
):
    """List bookings with optional filters."""
    return await service.get_bookings(db, property_id=property_id, status_filter=status, date_filter=date)


@router.get("/{booking_id}", response_model=BookingResponse)
async def get_booking(
    booking_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get detailed booking information including guest and room."""
    return await service.get_booking_detail(db, booking_id)


@router.patch("/{booking_id}", response_model=BookingResponse)
async def update_booking(
    booking_id: uuid.UUID,
    req: BookingUpdateRequest,
    db: AsyncSession = Depends(get_db),
):
    """Update booking fields. Recalculates totals if room_rent changes."""
    return await service.update_booking(db, booking_id, req)


@router.post("/{booking_id}/cancel", response_model=BookingResponse)
async def cancel_booking(
    booking_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Cancel a booking and release the room."""
    return await service.cancel_booking(db, booking_id)
