from app.infra.database import engine, Base
from app.infra import models

async def init_db():
    async with engine.begin() as conn:
        # We will simply create all new tables
        await conn.run_sync(Base.metadata.create_all)
        print("Database tables created successfully!")

import asyncio
asyncio.run(init_db())
