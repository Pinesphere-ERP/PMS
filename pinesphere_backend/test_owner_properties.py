import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, or_
from app.infra.database import settings
from app.infra.models import Property, Owner, Business, Subscription, UserPropertyAccess, User

async def main():
    engine = create_async_engine(settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"))
    async_session = sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    
    async with async_session() as db:
        # Get an owner user
        user = (await db.execute(select(User).where(User.role_id.in_(
            select(app.infra.models.Role.id).where(app.infra.models.Role.role_code == 'OWNER')
        )))).scalars().first()
        
        if not user:
            print("No owner user found!")
            return
            
        print(f"Testing for user: {user.email} ({user.id})")
        
        q = (
            select(Property, Owner, Business, Subscription)
            .select_from(Property)
            .join(Owner, Property.owner_id == Owner.owner_id)
            .outerjoin(Business, Property.business_id == Business.business_id)
            .outerjoin(Subscription, Subscription.property_id == Property.property_id)
        )
        
        q = q.outerjoin(UserPropertyAccess, UserPropertyAccess.property_id == Property.property_id)
        
        conditions = [UserPropertyAccess.user_id == user.id]
        if user.property_id:
            conditions.append(Property.property_id == user.property_id)
        if user.email:
            conditions.append(Owner.email == user.email)
            
        q = q.where(or_(*conditions))
        
        try:
            result = await db.execute(q)
            rows = result.unique().all()
            print(f"Found {len(rows)} properties!")
            for prop, owner, biz, sub in rows:
                print(f"- {prop.property_name}")
        except Exception as e:
            print(f"ERROR: {e}")

if __name__ == "__main__":
    import app.infra.models
    asyncio.run(main())
