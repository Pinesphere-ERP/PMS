import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, desc

from app.infra.models import PortalNotification

class PortalNotificationService:
    @staticmethod
    async def create_notification(
        db: AsyncSession,
        property_id: uuid.UUID,
        booking_id: uuid.UUID,
        category: str,
        title: str,
        message: str
    ) -> PortalNotification:
        notification = PortalNotification(
            property_id=property_id,
            booking_id=booking_id,
            category=category,
            title=title,
            message=message,
            is_read=False,
            created_at=datetime.now(timezone.utc)
        )
        db.add(notification)
        await db.flush()
        await db.refresh(notification)
        return notification

    @staticmethod
    async def get_notifications_for_booking(
        db: AsyncSession,
        property_id: uuid.UUID,
        booking_id: uuid.UUID,
        limit: int = 50,
        offset: int = 0
    ) -> List[PortalNotification]:
        stmt = (
            select(PortalNotification)
            .where(
                PortalNotification.booking_id == booking_id,
                PortalNotification.property_id == property_id
            )
            .order_by(desc(PortalNotification.created_at))
            .limit(limit)
            .offset(offset)
        )
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def mark_as_read(
        db: AsyncSession,
        notification_id: uuid.UUID,
        property_id: uuid.UUID,
        booking_id: uuid.UUID
    ) -> None:
        stmt = (
            update(PortalNotification)
            .where(
                PortalNotification.notification_id == notification_id,
                PortalNotification.booking_id == booking_id,
                PortalNotification.property_id == property_id
            )
            .values(is_read=True)
        )
        await db.execute(stmt)

    @staticmethod
    async def mark_all_as_read(
        db: AsyncSession,
        property_id: uuid.UUID,
        booking_id: uuid.UUID
    ) -> None:
        stmt = (
            update(PortalNotification)
            .where(
                PortalNotification.booking_id == booking_id,
                PortalNotification.property_id == property_id,
                PortalNotification.is_read == False
            )
            .values(is_read=True)
        )
        await db.execute(stmt)
