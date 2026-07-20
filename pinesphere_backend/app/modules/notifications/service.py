import logging
import uuid
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.infra.models import Notification

logger = logging.getLogger(__name__)

class NotificationDispatchService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def dispatch(
        self,
        recipient_id: uuid.UUID,
        title: str,
        message: str,
        channel: str = "in_app",
        priority: str = "normal",
        payload: Optional[dict] = None
    ) -> Notification:
        """
        Dispatches a notification to the specified recipient.
        Handles multi-channel routing (in_app, whatsapp, push, sms).
        """
        notification = Notification(
            recipient_id=recipient_id,
            title=title,
            message=message,
            channel=channel,
            priority=priority,
            payload=payload,
            status="unread"
        )
        self.db.add(notification)
        await self.db.flush()

        if channel == "whatsapp":
            await self._dispatch_whatsapp(recipient_id, title, message)
        elif channel == "push":
            await self._dispatch_push(recipient_id, title, message)
        elif channel == "sms":
            await self._dispatch_sms(recipient_id, title, message)

        # in_app notifications are handled via ObjectBox sync pulling
        
        return notification

    async def _dispatch_whatsapp(self, recipient_id: uuid.UUID, title: str, message: str):
        # Mock integration with WhatsApp Business API
        logger.info(f"[WhatsApp] Sending to {recipient_id}: {title} - {message}")

    async def _dispatch_push(self, recipient_id: uuid.UUID, title: str, message: str):
        # Mock integration with FCM / APNS
        logger.info(f"[Push] Sending to {recipient_id}: {title} - {message}")

    async def _dispatch_sms(self, recipient_id: uuid.UUID, title: str, message: str):
        # Mock integration with Twilio / AWS SNS / MSG91
        logger.info(f"[SMS] Sending to {recipient_id}: {title} - {message}")
