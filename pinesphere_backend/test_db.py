import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def main():
    engine = create_async_engine('postgresql+asyncpg://pinesphere_db_wtx9_user:2g5tX4aZ40Y8w3R9M2S5H6P1L3Y5F1M6@dpg-cpl1o75a730s73et3fag-a.singapore-postgres.render.com/pinesphere_db_wtx9?ssl=require', connect_args={'timeout': 5})
    async with engine.connect() as conn:
        res = await conn.execute(text("SELECT email FROM users WHERE email = 'admin@pinesphere.com'"))
        print(res.fetchall())
asyncio.run(main())
