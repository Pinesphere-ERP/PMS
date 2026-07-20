#!/bin/bash
source venv/bin/activate
pip install aiosqlite
# Initialize DB
python3 -c "
import asyncio
from app.infra.database import engine, Base
async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
asyncio.run(init())
"
echo "Database initialized!"
