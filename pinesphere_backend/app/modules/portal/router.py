from datetime import timedelta
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.database import get_db
from app.infra.models import Booking, Guest, Room
from app.modules.portal.schemas import PortalLoginRequest, PortalTokenResponse
from app.core.config import settings
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt

router = APIRouter(prefix="/portal", tags=["Guest Portal"])
security = HTTPBearer()

async def get_current_guest_booking(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> Booking:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if payload.get("type") != "guest_portal":
            raise HTTPException(status_code=401, detail="Invalid token type")
        booking_id_str = payload.get("sub")
        if not booking_id_str:
            raise HTTPException(status_code=401, detail="Invalid token payload")
        booking_id = uuid.UUID(booking_id_str)
    except Exception:
        raise HTTPException(status_code=401, detail="Could not validate credentials")
        
    stmt = select(Booking).where(Booking.booking_id == booking_id)
    result = await db.execute(stmt)
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=401, detail="Booking not found")
        
    return booking

@router.post("/auth", response_model=PortalTokenResponse)
async def portal_login(
    req: PortalLoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Authenticate a guest using their booking reference and mobile number.
    Returns a short-lived JWT token valid only for this booking's data.
    """
    # Find the booking by reference
    stmt = select(Booking).where(Booking.booking_reference == req.booking_reference)
    result = await db.execute(stmt)
    booking = result.scalar_one_or_none()
    
    if not booking:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid booking reference")
        
    # Verify the guest mobile number
    stmt_guest = select(Guest).where(Guest.guest_id == booking.guest_id)
    guest_res = await db.execute(stmt_guest)
    guest = guest_res.scalar_one_or_none()
    
    if not guest or guest.mobile_number != req.mobile_number:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid mobile number for this booking")
        
    # Check if booking is active (checked_in)
    # Allow guests to login if they are pre-arrival or checked in.
    if booking.status in ['cancelled', 'no_show', 'completed']:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Booking is not active")
        
    # Fetch room if assigned
    room_number = None
    if booking.room_id:
        stmt_room = select(Room).where(Room.room_id == booking.room_id)
        room_res = await db.execute(stmt_room)
        room = room_res.scalar_one_or_none()
        if room:
            room_number = room.name
            
    # Create a custom JWT token for the guest
    # It stores the booking_id instead of a standard user_id
    access_token_expires = timedelta(days=7)
    from datetime import datetime, timezone
    expire = datetime.now(timezone.utc) + access_token_expires
    to_encode = {
        "sub": str(booking.booking_id),
        "type": "guest_portal",
        "property_id": str(booking.property_id),
        "exp": expire
    }
    access_token = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    
    return PortalTokenResponse(
        access_token=access_token,
        token_type="bearer",
        guest_name=f"{guest.first_name} {guest.last_name}",
        booking_id=booking.booking_id,
        room_number=room_number
    )

@router.get("/folio")
async def get_guest_folio(
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db)
):
    from app.infra.models import FolioLineItem
    stmt = select(FolioLineItem).where(FolioLineItem.booking_id == booking.booking_id).order_by(FolioLineItem.created_at)
    result = await db.execute(stmt)
    items = result.scalars().all()
    
    total = sum([item.amount for item in items])
    
    return {
        "booking_id": booking.booking_id,
        "items": items,
        "total_amount": total
    }

@router.post("/orders")
async def create_portal_order(
    item_id: uuid.UUID,
    quantity: int,
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db)
):
    # This would normally create an F&B Task for the kitchen
    # For now, just return success
    return {"status": "success", "message": "Order sent to kitchen"}

@router.post("/services")
async def request_service(
    service_type: str,
    description: str,
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db)
):
    # This would normally create a Task for Housekeeping/Maintenance
    return {"status": "success", "message": f"{service_type} requested"}

