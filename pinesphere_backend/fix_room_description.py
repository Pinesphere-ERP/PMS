import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def alter_table():
    # Connect using the alembic database URL (owner credentials)
    engine = create_async_engine("postgresql+asyncpg://pinesphere:pinesphere_password@localhost:5444/pinesphere")
    async with engine.begin() as conn:
        await conn.execute(text("ALTER TABLE room_categories ADD COLUMN IF NOT EXISTS description TEXT;"))
    print("Database table altered successfully!")

if __name__ == "__main__":
    asyncio.run(alter_table())
