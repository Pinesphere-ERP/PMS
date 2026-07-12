import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect("postgresql://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require")
    try:
        await conn.execute("ALTER TABLE users ADD COLUMN username VARCHAR(120);")
        print("Column added successfully")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await conn.close()

asyncio.run(main())
