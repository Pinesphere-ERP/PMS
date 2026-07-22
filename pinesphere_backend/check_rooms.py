import asyncio
from sqlalchemy import select
from app.infra.database import AsyncSessionLocal
from app.infra.models import Room

async def main():
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Room))
        rooms = res.scalars().all()
        print(f'Total rooms in DB: {len(rooms)}')
        for r in rooms:
            print(f'Room: {r.room_number}, property_id: {r.property_id}')

asyncio.run(main())
