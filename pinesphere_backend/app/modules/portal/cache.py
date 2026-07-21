import json
import uuid
from typing import Optional, Dict
from app.core.redis import get_redis

class PortalCache:
    TTL_SECONDS = 300  # 5 minutes

    @staticmethod
    def _key(session_id: uuid.UUID) -> str:
        return f"portal:context:{session_id}"

    @classmethod
    async def get_context(cls, session_id: uuid.UUID) -> Optional[Dict]:
        client = get_redis()
        if not client:
            return None
        try:
            data = await client.get(cls._key(session_id))
            if data:
                return json.loads(data)
        except Exception:
            return None
        return None

    @classmethod
    async def set_context(cls, session_id: uuid.UUID, context: Dict) -> None:
        client = get_redis()
        if not client:
            return
        try:
            # We serialize basic info required for access checks
            # Context dict should contain serializable types only.
            data = json.dumps(context)
            await client.setex(cls._key(session_id), cls.TTL_SECONDS, data)
        except Exception:
            pass

    @classmethod
    async def invalidate_context(cls, session_id: uuid.UUID) -> None:
        client = get_redis()
        if not client:
            return
        try:
            await client.delete(cls._key(session_id))
        except Exception:
            pass
