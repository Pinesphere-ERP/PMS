import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete

from app.infra.models import PortalSession, Booking, OTPRequest

class SessionService:
    @staticmethod
    async def create_session(
        db: AsyncSession, 
        property_id: uuid.UUID, 
        booking_id: uuid.UUID, 
        guest_id: uuid.UUID,
        device_info: Optional[str] = None,
        last_ip: Optional[str] = None,
        user_agent: Optional[str] = None,
        device_name: Optional[str] = None,
        duration_hours: int = 24
    ) -> PortalSession:
        session = PortalSession(
            property_id=property_id,
            booking_id=booking_id,
            guest_id=guest_id,
            device_info=device_info,
            last_ip=last_ip,
            user_agent=user_agent,
            device_name=device_name,
            expires_at=datetime.now(timezone.utc) + timedelta(hours=duration_hours),
            last_active_at=datetime.now(timezone.utc)
        )
        db.add(session)
        await db.flush()
        await db.refresh(session)
        return session

    @staticmethod
    async def get_active_session(db: AsyncSession, session_id: uuid.UUID) -> Optional[PortalSession]:
        stmt = select(PortalSession).where(
            PortalSession.session_id == session_id,
            PortalSession.revoked_at.is_(None),
            PortalSession.expires_at > datetime.now(timezone.utc)
        )
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    @staticmethod
    async def update_last_active(db: AsyncSession, session_id: uuid.UUID) -> None:
        stmt = (
            update(PortalSession)
            .where(PortalSession.session_id == session_id)
            .values(last_active_at=datetime.now(timezone.utc))
        )
        await db.execute(stmt)

    @staticmethod
    async def revoke_session(db: AsyncSession, session_id: uuid.UUID, reason: str = "MANUAL") -> None:
        stmt = (
            update(PortalSession)
            .where(PortalSession.session_id == session_id)
            .values(
                revoked_at=datetime.now(timezone.utc),
                revocation_reason=reason
            )
        )
        await db.execute(stmt)

    @staticmethod
    async def revoke_all_for_booking(db: AsyncSession, booking_id: uuid.UUID, reason: str = "SECURITY") -> None:
        """Manually revokes all active sessions for a booking."""
        stmt = (
            update(PortalSession)
            .where(
                PortalSession.booking_id == booking_id,
                PortalSession.revoked_at.is_(None)
            )
            .values(
                revoked_at=datetime.now(timezone.utc),
                revocation_reason=reason
            )
        )
        await db.execute(stmt)

    @staticmethod
    async def cleanup_expired_sessions(db: AsyncSession) -> None:
        """Deletes sessions that expired or were revoked over 30 days ago."""
        thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
        
        # Delete naturally expired sessions older than 30 days
        stmt1 = delete(PortalSession).where(
            PortalSession.expires_at < thirty_days_ago
        )
        await db.execute(stmt1)

        # Delete revoked sessions older than 30 days
        stmt2 = delete(PortalSession).where(
            PortalSession.revoked_at < thirty_days_ago
        )
        await db.execute(stmt2)

        # OTP Cleanup: delete used or expired OTPs older than 30 days
        stmt3 = delete(OTPRequest).where(
            (OTPRequest.used_at < thirty_days_ago) |
            (OTPRequest.expires_at < thirty_days_ago)
        )
        await db.execute(stmt3)
        await db.flush()
