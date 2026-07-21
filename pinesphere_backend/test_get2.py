import asyncio
from app.infra.database import AsyncSessionLocal
from app.infra.models import Property, Owner, Business, Subscription
from sqlalchemy import select

async def test():
    async with AsyncSessionLocal() as db:
        q = (
            select(Property, Owner, Business, Subscription)
            .select_from(Property)
            .join(Owner, Property.owner_id == Owner.owner_id)
            .join(Business, Property.business_id == Business.business_id)
            .outerjoin(Subscription, Subscription.property_id == Property.property_id)
        )
        res = await db.execute(q)
        rows = res.unique().all()
        
        seen = {}
        for prop, owner, biz, sub in rows:
            pid = str(prop.property_id)
            if pid not in seen:
                seen[pid] = (prop, owner, biz, sub)

        data = []
        for pid, (prop, owner, biz, sub) in seen.items():
            data.append({
                "id": pid,
                "name": prop.property_name,
            })
        print("Data:", data)

asyncio.run(test())
