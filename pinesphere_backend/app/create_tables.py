import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings
from app.infra.database import Base
from app.infra.models import *

async def create_tables():
    engine = create_async_engine(settings.DATABASE_URL, echo=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    print("Tables created successfully in SQLite!")

if __name__ == "__main__":
    asyncio.run(create_tables())
