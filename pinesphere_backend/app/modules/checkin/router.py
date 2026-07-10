import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.modules.checkin.schemas import (
    CheckInRequest, CheckInResponse, CheckInSearchResult,
    WalkInCheckInRequest,
)
from app.modules.checkin import service

router = APIRouter()


@router.post("", response_model=CheckInResponse, status_code=status.HTTP_201_CREATED)
async def perform_checkin(
    req: CheckInRequest,
    db: AsyncSession = Depends(get_db),
):
    """Perform a check-in for an existing confirmed booking."""
    return await service.perform_checkin(db, req)


@router.post("/walkin", response_model=CheckInResponse, status_code=status.HTTP_201_CREATED)
async def walkin_checkin(
    req: WalkInCheckInRequest,
    db: AsyncSession = Depends(get_db),
):
    """Walk-in guest: creates guest, booking, and check-in in a single call."""
    return await service.perform_walkin_checkin(db, req)


@router.get("/today", response_model=List[CheckInResponse])
async def get_todays_checkins(
    property_id: uuid.UUID = Query(..., description="Property ID"),
    db: AsyncSession = Depends(get_db),
):
    """List all check-ins performed today for a given property."""
    return await service.get_todays_checkins(db, property_id)


@router.get("/active", response_model=List[CheckInResponse])
async def get_active_checkins(
    property_id: uuid.UUID = Query(..., description="Property ID"),
    db: AsyncSession = Depends(get_db),
):
    """List all currently active (checked-in) guests for a property."""
    return await service.get_active_checkins(db, property_id)


@router.get("/{checkin_id}")
async def get_checkin_detail(
    checkin_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Full check-in detail including guest, room, booking, and invoice."""
    return await service.get_checkin_detail(db, checkin_id)


@router.post("/{checkin_id}/cancel", response_model=CheckInResponse)
async def cancel_checkin(
    checkin_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Cancel an active check-in, release room, and revert booking status."""
    return await service.cancel_checkin(db, checkin_id)
