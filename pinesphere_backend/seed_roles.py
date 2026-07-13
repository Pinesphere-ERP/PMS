import asyncio
import uuid
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.core.config import settings
from app.infra.models import Role
from sqlalchemy import select

roles_data = [
    {"role_code": "SUPER_ADMIN", "role_name": "Super Admin"},
    {"role_code": "OWNER", "role_name": "Owner"},
    {"role_code": "MANAGER", "role_name": "Manager"},
    {"role_code": "RECEPTION", "role_name": "Reception"},
    {"role_code": "HOUSEKEEPING", "role_name": "Housekeeping"},
    {"role_code": "ACCOUNTANT", "role_name": "Accountant"},
    {"role_code": "GUEST", "role_name": "Guest"},
]

async def seed_roles():
    engine = create_async_engine(settings.DATABASE_URL, echo=True)
    async_session = async_sessionmaker(engine, expire_on_commit=False)
    
    async with async_session() as db:
        for r_data in roles_data:
            stmt = select(Role).where(Role.role_code == r_data["role_code"])
            res = await db.execute(stmt)
            existing = res.scalar_one_or_none()
            if not existing:
                new_role = Role(
                    id=uuid.uuid4(),
                    role_code=r_data["role_code"],
                    role_name=r_data["role_name"],
                    is_system_role=True,
                    description=r_data["role_name"] + " role"
                )
                db.add(new_role)
        
        await db.commit()
    
    await engine.dispose()
    print("Roles seeded successfully!")

if __name__ == "__main__":
    asyncio.run(seed_roles())
