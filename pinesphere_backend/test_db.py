import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
import os

async def main():
    engine = create_async_engine(os.environ.get('DATABASE_URL', 'postgresql+asyncpg://pinesphere_db_wtx9_user:2g5tX4aZ40Y8w3R9M2S5H6P1L3Y5F1M6@dpg-cpl1o75a730s73et3fag-a.singapore-postgres.render.com/pinesphere_db_wtx9?ssl=require'))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        result = await session.execute(text("SELECT email, status, role_id, failed_login_attempts FROM users;"))
        for row in result:
            print(row)
        
asyncio.run(main())
