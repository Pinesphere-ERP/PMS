import asyncio
import uuid
import ssl
from datetime import datetime
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from app.infra.models import Owner, Business, Property, User, Role
from app.core.security import get_password_hash
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./pinesphere.db")

async def main():
    engine = create_async_engine(DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        async with session.begin():
            try:
                owner_id = uuid.uuid4()
                owner = Owner(owner_id=owner_id, full_name="Admin User", mobile_number="1234567890", email="admin@pinesphere.com")
                session.add(owner)
                await session.flush()
                
                business_id = uuid.uuid4()
                biz = Business(business_id=business_id, owner_id=owner_id, business_name="Admin Business")
                session.add(biz)
                await session.flush()
                
                property_id = uuid.uuid4()
                prop = Property(property_id=property_id, business_id=business_id, owner_id=owner_id, property_name="Admin Property", onboarding_status="active")
                session.add(prop)
                await session.flush()
                
                role_id = uuid.uuid4()
                role = Role(id=role_id, property_id=property_id, role_code="OWNER", role_name="Owner", is_system_role=True)
                session.add(role)
                await session.flush()
                
                user_id = uuid.uuid4()
                user = User(id=user_id, property_id=property_id, role_id=role_id, name="Admin User", email="admin@pinesphere.com", password_hash=get_password_hash("password123"), status="ACTIVE", failed_login_attempts=0, is_primary_owner=True)
                session.add(user)
                await session.flush()
                
                print("SUCCESS: User admin@pinesphere.com created in local SQLite DB!")
            except Exception as e:
                print("Error:", e)
                raise e

asyncio.run(main())
