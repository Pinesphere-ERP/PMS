import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.core.dependencies import get_current_user
from app.infra.models import User
from app.infra.database import get_db
from app.infra.models import Notification
from app.modules.notifications.schemas import NotificationResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("/", response_model=List[NotificationResponse])
async def get_my_notifications(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Fetch all unread notifications for the currently logged in user.
    """
    query = select(Notification).filter(
        Notification.recipient_id == current_user.user_id,
        Notification.status == 'unread'
    ).order_by(Notification.created_at.desc())
    
    result = await db.execute(query)
    notifications = result.scalars().all()
    return notifications

@router.post("/{notification_id}/read", status_code=status.HTTP_200_OK)
async def mark_notification_read(
    notification_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Mark a notification as read.
    """
    query = select(Notification).filter(
        Notification.notification_id == notification_id,
        Notification.recipient_id == current_user.user_id
    )
    result = await db.execute(query)
    notification = result.scalars().first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
        
    notification.status = 'read'
    return {"status": "success"}

@router.post("/{notification_id}/dismiss", status_code=status.HTTP_200_OK)
async def dismiss_notification(
    notification_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Dismiss a notification without necessarily reading it.
    """
    query = select(Notification).filter(
        Notification.notification_id == notification_id,
        Notification.recipient_id == current_user.user_id
    )
    result = await db.execute(query)
    notification = result.scalars().first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
        
    notification.status = 'dismissed'
    return {"status": "success"}
