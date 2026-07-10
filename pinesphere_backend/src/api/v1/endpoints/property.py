from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from src.infra.database import get_db

router = APIRouter()

@router.get("/")
async def get_properties(db: AsyncSession = Depends(get_db)):
    """Get all properties for Super Admin"""
    return {"message": "Get all properties - Not yet implemented"}

@router.post("/")
async def create_property(db: AsyncSession = Depends(get_db)):
    """Create a new property"""
    return {"message": "Create property - Not yet implemented"}

@router.get("/verification-queue")
async def get_verification_queue(db: AsyncSession = Depends(get_db)):
    """Get property verification queue"""
    return {"message": "Get verification queue - Not yet implemented"}
