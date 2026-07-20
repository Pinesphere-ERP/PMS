import asyncio
import uuid
from datetime import datetime
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
import os

from app.core.security import get_password_hash
from app.infra.models import User, Role, Owner, Business, Property
from app.infra.database import provision_tenant_schema

async def seed_hosted():
    engine = create_async_engine(
        'postgresql+asyncpg://pinesphere_db_wtx9_user:2g5tX4aZ40Y8w3R9M2S5H6P1L3Y5F1M6@dpg-cpl1o75a730s73et3fag-a.singapore-postgres.render.com/pinesphere_db_wtx9?ssl=require'
    )
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as db:
        async with db.begin():
            # Check if role exists
            role_result = await db.execute(text("SELECT id FROM roles WHERE role_code = 'OWNER'"))
            role_row = role_result.first()
            if not role_row:
                owner_role = Role(
                    id=uuid.uuid4(),
                    role_code="OWNER",
                    role_name="Property Owner",
                    is_system_role=True,
                    description="Default role for Property Owners"
                )
                db.add(owner_role)
                await db.flush()
                role_id = owner_role.id
            else:
                role_id = role_row.id

            # Create Owner
            owner_id = uuid.uuid4()
            new_owner = Owner(
                owner_id=owner_id,
                full_name="Admin User",
                email="admin@pinesphere.com",
                mobile_number="1234567890",
                email_verified=True,
                mobile_verified=True
            )
            db.add(new_owner)
            await db.flush()

            # Create Business
            business_id = uuid.uuid4()
            new_business = Business(
                business_id=business_id,
                owner_id=owner_id,
                business_name="Pinesphere Admin Business"
            )
            db.add(new_business)
            await db.flush()

            # Create Property
            property_id = uuid.uuid4()
            new_property = Property(
                property_id=property_id,
                business_id=business_id,
                owner_id=owner_id,
                property_name="Pinesphere Admin Property",
                property_type="HOTEL",
                star_category=5,
                year_established=datetime.now().year,
                onboarding_status="active"
            )
            db.add(new_property)
            await db.flush()
            
            # Create User
            user_id = uuid.uuid4()
            new_user = User(
                id=user_id,
                email="admin@pinesphere.com",
                mobile_number="1234567890",
                password_hash=get_password_hash("password123"),
                name="Admin User",
                role_id=role_id,
                property_id=property_id,
                status="ACTIVE",
                is_primary_owner=True
            )
            db.add(new_user)
            await db.flush()
            print(f"User created: {new_user.email}")
            
    # We must provision tenant schema using the engine directly outside the transaction
    await provision_tenant_schema(str(property_id))
    print("Database seeding completed.")

if __name__ == "__main__":
    asyncio.run(seed_hosted())
