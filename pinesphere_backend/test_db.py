import asyncio
from sqlalchemy import text
from app.infra.database import engine

async def test():
    async with engine.begin() as conn:
        res = await conn.execute(text("SELECT id, email, role_id, property_id FROM users;"))
        users = res.fetchall()
        print("USERS:", users)
        
        for u in users:
            uid = u.id
            access = await conn.execute(text(f"SELECT * FROM user_property_access WHERE user_id = '{uid}';"))
            print(f"Access for {uid}:", access.fetchall())
                
        props = await conn.execute(text("SELECT property_id, property_name, owner_id FROM properties;"))
        print("PROPERTIES:", props.fetchall())
        
        owners = await conn.execute(text("SELECT owner_id, full_name FROM owners;"))
        print("OWNERS TABLE:", owners.fetchall())

asyncio.run(test())
