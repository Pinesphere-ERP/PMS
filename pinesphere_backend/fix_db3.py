import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect("postgresql://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require")
    try:
        await conn.execute("ALTER TABLE role_permissions ADD COLUMN updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW();")
        print("Column updated_at added to role_permissions successfully")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await conn.close()

asyncio.run(main())
