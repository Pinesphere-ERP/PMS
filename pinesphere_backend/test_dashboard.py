import asyncio
from sqlalchemy import text
from app.infra.database import async_session_maker
from app.modules.dashboard.router import get_dashboard_metrics

async def test():
    async with async_session_maker() as db:
        prop = await db.execute(text("SELECT property_id FROM properties LIMIT 1;"))
        row = prop.first()
        if not row:
            print("No properties")
            return
        pid = row[0]
        print(f"Testing for property {pid}")
        try:
            res = get_dashboard_metrics(property_id=str(pid), db=db)
            print("SUCCESS:", res)
        except Exception as e:
            import traceback
            traceback.print_exc()

asyncio.run(test())
