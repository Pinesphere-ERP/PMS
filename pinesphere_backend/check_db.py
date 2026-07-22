import asyncio
from app.infra.database import async_session_maker
from sqlalchemy import text

async def main():
    async with async_session_maker() as session:
        res = await session.execute(text("SELECT id, email, mobile_number, property_id FROM users"))
        print("USERS:", res.fetchall())
        res2 = await session.execute(text("SELECT property_id, property_name FROM properties"))
        print("PROPERTIES:", res2.fetchall())

if __name__ == "__main__":
    asyncio.run(main())
