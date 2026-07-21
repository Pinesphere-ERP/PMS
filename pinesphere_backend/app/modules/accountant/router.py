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
    # Mock data for now, since we need to show these specific KPIs on the dashboard
    return {
        "accounting": 150000.0,
        "income": 120000.0,
        "expenses": 30000.0,
        "profit": 90000.0,
        "gst": 21600.0,
        "invoices": 45,
        "reports": 12,
        "recent_guests": [
            {
                "id": "b1",
                "guest_name": "John Doe",
                "room_number": "101",
                "amount_due": 5000.0,
                "status": "Checked-In"
            },
            {
                "id": "b2",
                "guest_name": "Jane Smith",
                "room_number": "102",
                "amount_due": 0.0,
                "status": "Checked-Out"
            }
        ]
    }

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
