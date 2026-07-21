import asyncio
from datetime import datetime, timedelta, timezone
from sqlalchemy import delete
from app.tasks.celery_app import celery_app
from app.infra.database import AsyncSessionLocal
from app.infra.models import OTPRequest

async def _cleanup_otps_async():
    async with AsyncSessionLocal() as session:
        async with session.begin():
            thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
            stmt = delete(OTPRequest).where(
                (OTPRequest.used_at < thirty_days_ago) |
                (OTPRequest.expires_at < thirty_days_ago)
            )
            await session.execute(stmt)

@celery_app.task
def run_otp_cleanup():
    """Celery task to clean up old OTPRequest records."""
    asyncio.run(_cleanup_otps_async())
    return "OTP cleanup completed"
