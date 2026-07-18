import asyncio
from app.infra.database import AsyncSessionLocal
from sqlalchemy import text

async def clean_db():
    async with AsyncSessionLocal() as session:
        # Get a valid property ID or use a dummy one if none exists (just to bypass NOT NULL for now)
        res = await session.execute(text("SELECT property_id FROM properties LIMIT 1;"))
        prop_id = res.scalar()
        if not prop_id:
            print("No property found, cannot update.")
            # Instead of updating, delete if no property exists
            await session.execute(text('DELETE FROM subscription_transactions;'))
            await session.execute(text('DELETE FROM invoices;'))
            await session.execute(text('DELETE FROM check_outs;'))
            await session.execute(text('DELETE FROM check_ins;'))
            await session.execute(text('DELETE FROM room_assignments;'))
            await session.execute(text('DELETE FROM payments;'))
            await session.execute(text('DELETE FROM bookings;'))
            await session.execute(text('DELETE FROM guests;'))
            await session.execute(text('DELETE FROM rooms;'))
            await session.execute(text('DELETE FROM room_categories;'))
            await session.execute(text('DELETE FROM housekeeping_tasks;'))
            await session.execute(text('DELETE FROM maintenance_tickets;'))
            await session.execute(text('DELETE FROM lost_and_found;'))
            await session.commit()
            print("Deleted all records instead.")
            return

        tables = ['guests', 'rooms', 'bookings', 'room_categories', 'check_ins', 'check_outs', 'housekeeping_tasks', 'maintenance_tickets', 'invoices', 'payments']
        for table in tables:
            await session.execute(text(f"UPDATE {table} SET property_id = '{prop_id}' WHERE property_id IS NULL;"))
        await session.commit()
        print("Updated tables with property ID:", prop_id)

asyncio.run(clean_db())
