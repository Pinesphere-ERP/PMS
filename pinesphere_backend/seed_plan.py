import asyncio
from app.infra.database import async_session_maker
from app.infra.models import SubscriptionPlan

async def seed():
    async with async_session_maker() as session:
        plan = SubscriptionPlan(
            name="Standard",
            features="Access to all core features, Property management, Role Management",
            amount="1000.0",
            duration_months=1,
            status="Active"
        )
        session.add(plan)
        await session.commit()
        print("Plan added")

asyncio.run(seed())
