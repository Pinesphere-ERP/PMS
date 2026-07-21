import asyncio
import sys
import os
import ssl

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import settings

async def test():
    print("Testing Neon DB Connection with URL:", settings.DATABASE_URL.split("@")[1] if "@" in settings.DATABASE_URL else settings.DATABASE_URL)
    
    # Try standard asyncpg engine setup with ssl context or ssl=True
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    engine = create_async_engine(
        settings.DATABASE_URL,
        connect_args={"ssl": ctx, "timeout": 30},
        echo=False
    )
    
    try:
        async with engine.connect() as conn:
            res = await conn.execute(text("SELECT 1"))
            print("✅ Successfully connected to Neon DB! Test Query Result:", res.scalar())
    except Exception as e:
        print("❌ Neon DB Connection Error:", e)

if __name__ == "__main__":
    asyncio.run(test())
