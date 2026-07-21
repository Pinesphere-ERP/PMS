import os
from celery import Celery
from celery.schedules import crontab

# Initialize Celery app
# Defaults to Redis running on localhost if REDIS_URL isn't explicitly set in environment
redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379/0")

celery_app = Celery(
    "pinesphere_tasks",
    broker=redis_url,
    backend=redis_url,
    include=["app.tasks.cleanup_sessions", "app.tasks.cleanup_otps", "app.tasks.cleanup_notifications"]
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
)

# Scheduled tasks (Celery Beat)
celery_app.conf.beat_schedule = {
    "cleanup-expired-sessions-every-hour": {
        "task": "app.tasks.cleanup_sessions.run_session_cleanup",
        "schedule": crontab(minute=0),  # Top of every hour
    },
    "cleanup-expired-otps-every-hour": {
        "task": "app.tasks.cleanup_otps.run_otp_cleanup",
        "schedule": crontab(minute=15),  # 15 past every hour
    },
    "cleanup-old-notifications-daily": {
        "task": "app.tasks.cleanup_notifications.run_notification_cleanup",
        "schedule": crontab(minute=30, hour=2),  # 2:30 AM every day
    },
}
