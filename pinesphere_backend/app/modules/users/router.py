import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.database import get_db
from app.infra.models import User, Role
from app.core.dependencies import get_current_user
from app.core.security import get_password_hash
from app.modules.users.schemas import UserCreateRequest, UserResponse, UserUpdateRequest

router = APIRouter()

@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: UserCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Only Owner or Admin can create users for the property
    # In a real app, check permissions thoroughly
    
    # Check if user exists
    stmt = select(User).where(User.email == payload.email)
    res = await db.execute(stmt)
    if res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")
        
    new_user = User(
        id=uuid.uuid4(),
        name=payload.name,
        email=payload.email,
        mobile_number=payload.mobile_number,
        password_hash=get_password_hash(payload.password),
        role_id=payload.role_id,
        property_id=current_user.property_id,
        status="ACTIVE"
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.get("", response_model=List[UserResponse])
async def list_users(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User).where(User.property_id == current_user.property_id)
    result = await db.execute(stmt)
    return result.scalars().all()

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: uuid.UUID,
    payload: UserUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User).where(User.id == user_id, User.property_id == current_user.property_id)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if payload.name: user.name = payload.name
    if payload.email: user.email = payload.email
    if payload.mobile_number: user.mobile_number = payload.mobile_number
    if payload.status: user.status = payload.status
    if payload.role_id: user.role_id = payload.role_id
    
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
