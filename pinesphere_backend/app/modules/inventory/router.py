from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import Optional
import uuid

from app.infra.database import get_db
from app.infra.models import Room, RoomCategory
from app.core.dependencies import get_current_user
from app.infra.models import User

router = APIRouter()

@router.get("/rooms")
async def get_inventory_rooms(
    tenantId: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    """
    Get rooms inventory data. Cross-property view based on role matrix.
    If tenantId is provided, filter by property_id.
    """
    q = select(Room, RoomCategory).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id)
    
    if tenantId:
        q = q.where(Room.property_id == tenantId)
        
    result = await db.execute(q)
    rows = result.all()
    
    data = []
    for room_obj, cat_obj in rows:
        data.append({
            "id": str(room_obj.room_id),
            "room_number": room_obj.room_number,
            "category_id": str(cat_obj.room_category_id),
            "category": {"name": cat_obj.room_name},
            "status": "Available" if room_obj.occupancy_status == "vacant" else ("Occupied" if room_obj.occupancy_status == "occupied" else room_obj.occupancy_status),
            "base_price": float(cat_obj.base_price) if cat_obj.base_price else 0
        })
        
    return {"data": data}
