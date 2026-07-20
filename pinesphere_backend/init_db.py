import asyncio
from app.infra.database import engine, Base
import app.infra.models

async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
        print("Created tables:", Base.metadata.tables.keys())

asyncio.run(init())
