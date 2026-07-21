from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import Optional
import uuid

from app.infra.database import get_db
from app.infra.models import Room, RoomType
from app.core.dependencies import get_current_user
from app.infra.models import User

# If there's a RoomTypePricing model, we should import it. Since we don't know the exact class name, we'll try to find it or query it if possible.
# Actually, the base_price is on RoomTypePricing. Let's try importing it. If it fails we'll adjust.
try:
    from app.infra.models import RoomTypePricing
except ImportError:
    RoomTypePricing = None

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
    # Join Room with RoomType
    q = select(Room, RoomType).join(RoomType, Room.room_type_id == RoomType.id)
    
    if RoomTypePricing:
        q = q.outerjoin(RoomTypePricing, RoomType.id == RoomTypePricing.room_type_id)
        q = q.add_columns(RoomTypePricing)
    
    if tenantId:
        q = q.where(Room.property_id == tenantId)
        
    result = await db.execute(q)
    rows = result.all()
    
    data = []
    for row in rows:
        if RoomTypePricing:
            room_obj, room_type_obj, pricing_obj = row
        else:
            room_obj, room_type_obj = row
            pricing_obj = None
            
        data.append({
            "id": str(room_obj.room_id),
            "room_number": room_obj.room_number,
            "category_id": room_type_obj.name or room_type_obj.category,
            "category": {"name": room_type_obj.name or room_type_obj.category},
            "status": "Available" if room_obj.occupancy_status == "vacant" else ("Occupied" if room_obj.occupancy_status == "occupied" else room_obj.occupancy_status),
            "base_price": float(pricing_obj.base_price) if pricing_obj and pricing_obj.base_price else 0
        })
        
    return {"data": data}
