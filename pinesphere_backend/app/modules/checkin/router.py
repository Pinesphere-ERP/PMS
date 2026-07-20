import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.core.dependencies import assert_property_access, assert_resource_property_access, get_current_user, require_resource_property_access
from app.infra.models import Booking, CheckIn, Room, User
from app.modules.checkin.schemas import (
    CheckInRequest, CheckInResponse, CheckInSearchResult,
    WalkInCheckInRequest,
)
from app.modules.checkin import service
from app.modules.reports.service import update_daily_kpi_snapshot
from datetime import date

router = APIRouter()


@router.post("", response_model=CheckInResponse, status_code=status.HTTP_201_CREATED)
async def perform_checkin(
    req: CheckInRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Perform a check-in for an existing confirmed booking."""
    booking = await assert_resource_property_access(Booking, Booking.booking_id, req.booking_id, current_user, db)
    res = await service.perform_checkin(db, req, booking.property_id, current_user.id)
    await update_daily_kpi_snapshot(db, booking.property_id, date.today())
    return res


@router.post("/walkin", response_model=CheckInResponse, status_code=status.HTTP_201_CREATED)
async def walkin_checkin(
    req: WalkInCheckInRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Walk-in guest: creates guest, booking, and check-in in a single call."""
    await assert_property_access(req.property_id, current_user, db)
    await assert_resource_property_access(Room, Room.room_id, req.room_id, current_user, db)
    res = await service.perform_walkin_checkin(db, req)
    await update_daily_kpi_snapshot(db, req.property_id, date.today())
    return res


@router.get("/today", response_model=List[CheckInResponse])
async def get_todays_checkins(
    property_id: uuid.UUID = Query(..., description="Property ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all check-ins performed today for a given property."""
    await assert_property_access(property_id, current_user, db)
    return await service.get_todays_checkins(db, property_id)


@router.get("/active", response_model=List[CheckInResponse])
async def get_active_checkins(
    property_id: uuid.UUID = Query(..., description="Property ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all currently active (checked-in) guests for a property."""
    await assert_property_access(property_id, current_user, db)
    return await service.get_active_checkins(db, property_id)


@router.get("/{checkin_id}", dependencies=[Depends(require_resource_property_access(CheckIn, CheckIn.checkin_id, "checkin_id"))])
async def get_checkin_detail(
    checkin_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Full check-in detail including guest, room, booking, and invoice."""
    checkin = await assert_resource_property_access(CheckIn, CheckIn.checkin_id, checkin_id, current_user, db)
    return await service.get_checkin_detail(db, checkin_id, checkin.property_id)


@router.post("/{checkin_id}/cancel", response_model=CheckInResponse, dependencies=[Depends(require_resource_property_access(CheckIn, CheckIn.checkin_id, "checkin_id"))])
async def cancel_checkin(
    checkin_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Cancel an active check-in, release room, and revert booking status."""
    checkin = await assert_resource_property_access(CheckIn, CheckIn.checkin_id, checkin_id, current_user, db)
    return await service.cancel_checkin(db, checkin_id, checkin.property_id)
