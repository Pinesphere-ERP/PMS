import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?ssl=require")

async def main():
    engine = create_async_engine(DATABASE_URL, echo=True)
    async with engine.begin() as conn:
        try:
            await conn.execute(text("ALTER TABLE role_permissions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;"))
            print("Added updated_at to role_permissions")
        except Exception as e:
            print("Error adding updated_at:", e)
        
        try:
            await conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS device_fingerprint VARCHAR(255);"))
            print("Added device_fingerprint to users")
        except Exception as e:
            print("Error adding device_fingerprint to users:", e)
            
        try:
            await conn.execute(text("ALTER TABLE invoice_items DROP COLUMN IF EXISTS remarks;"))
            print("Dropped remarks from invoice_items")
        except Exception as e:
            pass

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
