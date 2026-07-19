from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.database import get_db
from app.infra.models import User, Invoice, Payment
from app.core.dependencies import get_current_user, require_permission

router = APIRouter()

@router.get("/dashboard")
async def accountant_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("ACCOUNTANT", "VIEW")),
):
    """Accountant Dashboard stub."""
    return {"message": "Accountant dashboard data"}

@router.get("/pending-dues")
async def pending_dues(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("ACCOUNTANT", "VIEW")),
):
    """Pending dues stub."""
    return []

@router.get("/cash-register")
async def cash_register(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission("ACCOUNTANT", "VIEW")),
):
    """Cash register stub."""
    return []
