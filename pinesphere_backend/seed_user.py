import asyncio
import uuid
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.core.config import settings
from app.infra.models import User, Role
from sqlalchemy import select
from app.core.security import get_password_hash

async def seed_user():
    engine = create_async_engine(settings.DATABASE_URL, echo=True)
    async_session = async_sessionmaker(engine, expire_on_commit=False)
    
    async with async_session() as db:
        # Get Super Admin role
        stmt = select(Role).where(Role.role_code == "SUPER_ADMIN")
        res = await db.execute(stmt)
        role = res.scalar_one_or_none()
        
        if not role:
            print("SUPER_ADMIN role not found!")
            return
            
        # Check if user exists
        stmt = select(User).where(User.username == "arunaw")
        res = await db.execute(stmt)
        existing = res.scalar_one_or_none()
        
        if not existing:
            new_user = User(
                id=uuid.uuid4(),
                username="arunaw",
                password_hash=get_password_hash("arunaw2007"),
                email="arunawrishe@gmail.com",
                name="Arunaw",
                mobile_number="0000000000",
                status="ACTIVE",
                role_id=role.id,
                property_id=None
            )
            db.add(new_user)
            await db.commit()
            print("User arunaw created successfully!")
        else:
            existing.password_hash = get_password_hash("arunaw2007")
            existing.role_id = role.id
            await db.commit()
            print("User arunaw updated successfully!")
    
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(seed_user())
