"""
Housekeeping Room Status — Repository Layer

Data access for the housekeeping_room_status table.
All raw SQL queries are isolated here; service layer stays clean.
"""
import uuid
from datetime import datetime
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from fastapi import HTTPException, status

from app.infra.models import HousekeepingRoomStatus, Room, RoomCategory


async def get_rooms_by_property(
    db: AsyncSession, property_id: uuid.UUID
) -> List[HousekeepingRoomStatus]:
    """Return all housekeeping room status records for a property."""
    query = (
        select(HousekeepingRoomStatus)
        .where(HousekeepingRoomStatus.property_id == property_id)
        .order_by(HousekeepingRoomStatus.room_number)
    )
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_room_status_by_room_id(
    db: AsyncSession, room_id: uuid.UUID
) -> Optional[HousekeepingRoomStatus]:
    """Return single housekeeping room status by room_id."""
    query = select(HousekeepingRoomStatus).where(
        HousekeepingRoomStatus.room_id == room_id
    )
    result = await db.execute(query)
    return result.scalar_one_or_none()


async def get_room_status_or_404(
    db: AsyncSession, room_id: uuid.UUID
) -> HousekeepingRoomStatus:
    """Return single housekeeping room status or raise 404."""
    record = await get_room_status_by_room_id(db, room_id)
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Housekeeping room status not found for this room",
        )
    return record


async def update_clean_status(
    db: AsyncSession,
    room_id: uuid.UUID,
    clean_status: str,
    updated_by: uuid.UUID,
) -> HousekeepingRoomStatus:
    """Update clean_status field for a room."""
    record = await get_room_status_or_404(db, room_id)
    record.clean_status = clean_status
    record.updated_by = updated_by
    if clean_status == "clean":
        record.last_cleaned_at = datetime.utcnow()
        record.estimated_cleaning_time = None
    return record


async def update_image_urls(
    db: AsyncSession,
    room_id: uuid.UUID,
    image_urls: List[str],
    updated_by: uuid.UUID,
) -> HousekeepingRoomStatus:
    """Replace image URLs for a room (deletes old, stores new)."""
    record = await get_room_status_or_404(db, room_id)
    record.image_urls = image_urls
    record.updated_by = updated_by
    return record


async def set_estimated_cleaning_time(
    db: AsyncSession,
    room_id: uuid.UUID,
    estimated_time: datetime,
    updated_by: uuid.UUID,
) -> HousekeepingRoomStatus:
    """Set estimated cleaning time and mark as scheduled."""
    record = await get_room_status_or_404(db, room_id)
    record.estimated_cleaning_time = estimated_time
    record.clean_status = "scheduled"
    record.updated_by = updated_by
    return record


async def upsert_room_status(
    db: AsyncSession,
    property_id: uuid.UUID,
    room_id: uuid.UUID,
    room_number: str,
    room_type: Optional[str] = None,
    floor: Optional[str] = None,
    description: Optional[str] = None,
    occupancy_status: str = "vacant",
    clean_status: str = "clean",
    priority: Optional[str] = None,
    created_by: Optional[uuid.UUID] = None,
) -> HousekeepingRoomStatus:
    """Create or update a housekeeping room status record."""
    existing = await get_room_status_by_room_id(db, room_id)
    if existing:
        existing.room_number = room_number
        existing.room_type = room_type
        existing.floor = floor
        existing.description = description
        existing.occupancy_status = occupancy_status
        # Don't overwrite clean_status on sync unless explicitly set
        if created_by:
            existing.updated_by = created_by
        return existing

    record = HousekeepingRoomStatus(
        property_id=property_id,
        room_id=room_id,
        room_number=room_number,
        room_type=room_type,
        floor=floor,
        description=description,
        occupancy_status=occupancy_status,
        clean_status=clean_status,
        priority=priority,
        created_by=created_by,
        updated_by=created_by,
    )
    db.add(record)
    return record


async def sync_rooms_for_property(
    db: AsyncSession, property_id: uuid.UUID, created_by: Optional[uuid.UUID] = None
) -> int:
    """
    Populate/sync housekeeping_room_status from existing rooms table.
    Returns count of upserted records.
    """
    rooms_query = (
        select(Room, RoomCategory)
        .join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id)
        .where(Room.property_id == property_id)
    )
    result = await db.execute(rooms_query)
    rows = result.all()
    count = 0
    for room, category in rows:
        await upsert_room_status(
            db=db,
            property_id=property_id,
            room_id=room.room_id,
            room_number=room.room_number,
            room_type=category.room_name,
            floor=room.floor,
            description=category.description,
            occupancy_status=room.occupancy_status or "vacant",
            created_by=created_by,
        )
        count += 1
    await db.flush()
    return count
