import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.core.dependencies import assert_property_access, assert_resource_property_access, get_current_user, require_resource_property_access
from app.infra.models import CheckIn, CheckOut, User
from app.modules.checkout.schemas import (
    CheckOutRequest, CheckOutResponse,
    PendingCheckoutItem, CheckoutBillingDetail,
)
from app.modules.checkout import service

router = APIRouter()


@router.post("", response_model=CheckOutResponse, status_code=status.HTTP_201_CREATED)
async def perform_checkout(
    req: CheckOutRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Perform guest check-out with full billing settlement."""
    checkin = await assert_resource_property_access(CheckIn, CheckIn.checkin_id, req.checkin_id, current_user, db)
    return await service.perform_checkout(db, req, checkin.property_id, current_user.id)


@router.get("/pending", response_model=List[PendingCheckoutItem])
async def get_pending_checkouts(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List active check-ins due for checkout today or overdue."""
    property_id = property_id or current_user.property_id
    if not property_id:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Property scope required")
    await assert_property_access(property_id, current_user, db)
    return await service.get_pending_checkouts(db, property_id=property_id)


@router.get("/today", response_model=List[CheckOutResponse])
async def get_todays_checkouts(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List completed check-outs for today."""
    property_id = property_id or current_user.property_id
    if not property_id:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Property scope required")
    await assert_property_access(property_id, current_user, db)
    return await service.get_todays_checkouts(db, property_id=property_id)


@router.get("/billing/{checkin_id}", response_model=CheckoutBillingDetail, dependencies=[Depends(require_resource_property_access(CheckIn, CheckIn.checkin_id, "checkin_id"))])
async def get_checkout_billing(
    checkin_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get pre-calculated billing breakdown for the checkout screen."""
    return await service.get_checkout_billing(db, checkin_id)


@router.get("/{checkout_id}", response_model=CheckOutResponse, dependencies=[Depends(require_resource_property_access(CheckOut, CheckOut.checkout_id, "checkout_id"))])
async def get_checkout_detail(
    checkout_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get full check-out detail with billing summary."""
    return await service.get_checkout_detail(db, checkout_id)
