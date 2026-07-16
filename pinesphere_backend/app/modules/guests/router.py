import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_, desc

from app.infra.database import get_db
from app.infra.models import Guest
from app.modules.guests.schemas import GuestCreateInput, GuestResponse, GuestUpdateInput

router = APIRouter()

@router.post("", response_model=GuestResponse, status_code=status.HTTP_201_CREATED)
async def create_guest(
    payload: GuestCreateInput,
    db: AsyncSession = Depends(get_db)
):
    # Check if guest exists by mobile or email
    stmt = select(Guest).where(Guest.mobile_number == payload.mobile_number)
    res = await db.execute(stmt)
    if res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Guest with this mobile number already exists")

    new_guest = Guest(
        guest_id=uuid.uuid4(),
        first_name=payload.first_name,
        last_name=payload.last_name,
        mobile_number=payload.mobile_number,
        email=payload.email,
        gender=payload.gender,
        dob=payload.dob,
        nationality=payload.nationality,
        address=payload.address,
        id_type=payload.id_type,
        id_number=payload.id_number,
        gst_number=payload.gst_number,
        company_name=payload.company_name,
        total_stays=0,
        is_vip=False,
        is_blacklisted=False,
    )
    
    db.add(new_guest)
    await db.commit()
    await db.refresh(new_guest)
    return new_guest

@router.get("", response_model=List[GuestResponse])
async def list_guests(
    search: Optional[str] = Query(None, description="Search by name or phone"),
    vip_only: Optional[bool] = Query(False),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Guest)
    
    if search:
        search_term = f"%{search}%"
        stmt = stmt.where(or_(
            Guest.first_name.ilike(search_term),
            Guest.last_name.ilike(search_term),
            Guest.mobile_number.ilike(search_term)
        ))
        
    if vip_only:
        stmt = stmt.where(Guest.is_vip == True)
        
    stmt = stmt.order_by(desc(Guest.created_at))
    
    result = await db.execute(stmt)
    return result.scalars().all()

@router.get("/{guest_id}", response_model=GuestResponse)
async def get_guest(
    guest_id: uuid.UUID,
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Guest).where(Guest.guest_id == guest_id)
    result = await db.execute(stmt)
    guest = result.scalar_one_or_none()
    
    if not guest:
        raise HTTPException(status_code=404, detail="Guest not found")
        
    return guest

@router.patch("/{guest_id}", response_model=GuestResponse)
async def update_guest(
    guest_id: uuid.UUID,
    payload: GuestUpdateInput,
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Guest).where(Guest.guest_id == guest_id)
    result = await db.execute(stmt)
    guest = result.scalar_one_or_none()
    
    if not guest:
        raise HTTPException(status_code=404, detail="Guest not found")
        
    update_data = payload.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(guest, key, value)
        
    db.add(guest)
    await db.commit()
    await db.refresh(guest)
    return guest
