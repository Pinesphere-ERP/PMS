import asyncio
from datetime import datetime, timedelta, timezone
from sqlalchemy import delete
from app.tasks.celery_app import celery_app
from app.infra.database import AsyncSessionLocal
from app.infra.models import PortalSession

async def _cleanup_sessions_async():
    async with AsyncSessionLocal() as session:
        async with session.begin():
            thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
            stmt1 = delete(PortalSession).where(PortalSession.expires_at < thirty_days_ago)
            await session.execute(stmt1)
            stmt2 = delete(PortalSession).where(PortalSession.revoked_at < thirty_days_ago)
            await session.execute(stmt2)

@celery_app.task
def run_session_cleanup():
    """Celery task to clean up old PortalSession records."""
    asyncio.run(_cleanup_sessions_async())
    return "Session cleanup completed"
