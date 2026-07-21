import asyncio
from app.tasks.celery_app import celery_app

@celery_app.task
def run_notification_cleanup():
    """Celery task to clean up old notifications (Stub)."""
    # TODO: Implement notification pruning when the notification model is finalized.
    return "Notification cleanup skipped (stub)"
