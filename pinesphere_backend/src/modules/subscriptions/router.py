from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.database.database import get_db

router = APIRouter()

@router.get("/plans")
async def get_plans(db: AsyncSession = Depends(get_db)):
    """Get all subscription plans"""
    return {"message": "Get plans - Not yet implemented"}

@router.get("/active")
async def get_active_subscriptions(db: AsyncSession = Depends(get_db)):
    """Get active subscriptions"""
    return {"message": "Get active subscriptions - Not yet implemented"}

@router.get("/renewals")
async def get_renewals(db: AsyncSession = Depends(get_db)):
    """Get renewals dashboard metrics"""
    return {"message": "Get renewals - Not yet implemented"}
