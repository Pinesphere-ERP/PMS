import asyncio
from httpx import AsyncClient
from app.main import app

async def test():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        # We don't have token, but GET /properties requires get_current_user.
        # We can bypass it or mock it.
        pass

asyncio.run(test())
