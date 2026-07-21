import redis.asyncio as redis
from typing import Optional
from app.core.config import settings

_redis_client: Optional[redis.Redis] = None

def get_redis() -> Optional[redis.Redis]:
    global _redis_client
    if not settings.REDIS_URL:
        return None
    if _redis_client is None:
        _redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)
    return _redis_client
