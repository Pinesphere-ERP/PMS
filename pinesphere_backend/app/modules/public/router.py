from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy import or_, and_, func
from pydantic import BaseModel
from typing import List, Optional

from app.infra.database import get_db
from app.infra.models import (
    Property, PropertyAddress, PropertyImage,
    RoomCategory, RoomInventory, RoomPricing, RoomAmenity, Amenity, Room
)

router = APIRouter()

class PublicPropertyResponse(BaseModel):
    property_name: str
    property_type: Optional[str]
    description: Optional[str]
    cover_image: Optional[str]
    whatsapp_number: Optional[str]
    address: Optional[dict]
    gallery: List[dict]

class PublicRoomTypeResponse(BaseModel):
    room_name: str
    description: Optional[str]
    max_capacity: int
    base_price: float
    weekend_price: Optional[float]
    seasonal_price: Optional[float]
    holiday_price: Optional[float]
    extra_adult: Optional[float]
    extra_child: Optional[float]
    amenities: List[str]
    images: List[str]

@router.get("/properties/{slug}", response_model=PublicPropertyResponse)
async def get_public_property(slug: str, response: Response, db: AsyncSession = Depends(get_db)):
    stmt = (
        select(Property)
        .where(Property.slug == slug)
    )
    result = await db.execute(stmt)
    prop = result.scalar_one_or_none()

    if not prop or prop.onboarding_status != "completed":
        raise HTTPException(status_code=404, detail="Property not found or not active")

    # Fetch address
    addr_stmt = select(PropertyAddress).where(PropertyAddress.property_id == prop.property_id)
    addr_result = await db.execute(addr_stmt)
    addr = addr_result.scalar_one_or_none()
    
    # Fetch gallery
    gallery_stmt = select(PropertyImage).where(PropertyImage.property_id == prop.property_id)
    gallery_result = await db.execute(gallery_stmt)
    gallery_images = gallery_result.scalars().all()
    
    address_data = None
    if addr:
        address_data = {
            "address": addr.address,
            "city": addr.city,
            "state": addr.state,
            "pincode": addr.pincode,
            "google_maps_url": addr.google_maps_url,
        }
        
    response.headers["Cache-Control"] = "public, max-age=300"
    
    return {
        "property_name": prop.property_name,
        "property_type": prop.property_type,
        "description": prop.description,
        "cover_image": prop.cover_image,
        "whatsapp_number": prop.whatsapp_number,
        "address": address_data,
        "gallery": [{"type": img.image_type, "url": img.image_url} for img in gallery_images]
    }

@router.get("/properties/{slug}/rooms", response_model=List[PublicRoomTypeResponse])
async def get_public_property_rooms(slug: str, response: Response, db: AsyncSession = Depends(get_db)):
    # First find property
    prop_stmt = select(Property.property_id, Property.onboarding_status).where(Property.slug == slug)
    prop_res = await db.execute(prop_stmt)
    prop = prop_res.first()
    
    if not prop or prop.onboarding_status != "completed":
        raise HTTPException(status_code=404, detail="Property not found or not active")
        
    property_id = prop.property_id
    
    # Fetch room categories
    categories_stmt = select(RoomCategory).where(RoomCategory.property_id == property_id)
    categories_res = await db.execute(categories_stmt)
    categories = categories_res.scalars().all()
    
    if not categories:
        return []
        
    category_ids = [c.room_category_id for c in categories]
    
    # Fetch Pricing
    pricing_stmt = select(RoomPricing).where(RoomPricing.room_type_id.in_(category_ids))
    pricing_res = await db.execute(pricing_stmt)
    pricing_map = {p.room_type_id: p for p in pricing_res.scalars().all()}
    
    # Fetch Amenities
    amenity_stmt = (
        select(RoomAmenity.room_type_id, Amenity.name)
        .join(Amenity, RoomAmenity.amenity_id == Amenity.id)
        .where(RoomAmenity.room_type_id.in_(category_ids))
    )
    amenity_res = await db.execute(amenity_stmt)
    amenities_map = {}
    for r_tid, a_name in amenity_res:
        if r_tid not in amenities_map:
            amenities_map[r_tid] = []
        amenities_map[r_tid].append(a_name)
        
    # Fetch Rooms (to aggregate images)
    rooms_stmt = select(Room.room_category_id, Room.image_url).where(
        and_(Room.property_id == property_id, Room.image_url != None)
    )
    rooms_res = await db.execute(rooms_stmt)
    images_map = {}
    for r_cid, url_str in rooms_res:
        if not url_str:
            continue
        if r_cid not in images_map:
            images_map[r_cid] = []
        # URL string could be comma-separated
        urls = [u.strip() for u in url_str.split(",") if u.strip()]
        for u in urls:
            if u not in images_map[r_cid]:
                images_map[r_cid].append(u)
                
    results = []
    for cat in categories:
        pricing = pricing_map.get(cat.room_category_id)
        if not pricing:
            continue
            
        base_price = float(pricing.base_price) if pricing.base_price else 0.0
        weekend_price = float(pricing.weekend_price) if pricing.weekend_price else None
        seasonal_price = float(pricing.seasonal_price) if pricing.seasonal_price else None
        holiday_price = float(pricing.holiday_price) if pricing.holiday_price else None
        extra_adult = float(pricing.extra_adult) if pricing.extra_adult else None
        extra_child = float(pricing.extra_child) if pricing.extra_child else None
        
        results.append({
            "room_name": cat.room_name or "Standard Room",
            "description": cat.description,
            "max_capacity": cat.max_capacity or 2,
            "base_price": base_price,
            "weekend_price": weekend_price,
            "seasonal_price": seasonal_price,
            "holiday_price": holiday_price,
            "extra_adult": extra_adult,
            "extra_child": extra_child,
            "amenities": amenities_map.get(cat.room_category_id, []),
            "images": images_map.get(cat.room_category_id, [])
        })
        
    response.headers["Cache-Control"] = "public, max-age=300"
    return results
