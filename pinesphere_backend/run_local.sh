#!/bin/bash
source venv/bin/activate
pip install aiosqlite
# Initialize DB
python3 -c "
import asyncio
from app.infra.database import engine, Base
import app.infra.models
async def init():
    async with engine.begin() as conn:
        conn_opt = await conn.execution_options(schema_translate_map={'public': None})
        await conn_opt.run_sync(Base.metadata.drop_all)
        await conn_opt.run_sync(Base.metadata.create_all)
asyncio.run(init())
"
echo "Database initialized!"
