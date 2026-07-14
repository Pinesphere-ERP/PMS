import asyncio
from dotenv import load_dotenv
load_dotenv()

from app.infra.database import engine, Base
from app.infra.models import *

async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

if __name__ == "__main__":
    asyncio.run(init())
