import asyncio
from httpx import AsyncClient
from app.infra.database import SessionLocal
from app.infra.models import User, Role
from sqlalchemy import select
from app.core.security import create_access_token
from datetime import timedelta

async def test():
    async with SessionLocal() as db:
        # Find super admin user
        q = select(User).join(Role).where(Role.role_code == "SUPER_ADMIN")
        res = await db.execute(q)
        user = res.scalars().first()
        
        token = create_access_token(
            data={"sub": str(user.id), "jti": "fake", "device_fp": "fake", "tenant_id": "fake"},
            expires_delta=timedelta(minutes=30)
        )
        
    async with AsyncClient(base_url="http://0.0.0.0:8000") as ac:
        res = await ac.get("/api/v1/properties", headers={"Authorization": f"Bearer {token}"})
        print("GET /properties", res.status_code)
        
        res2 = await ac.get("/api/v1/properties/rooms", headers={"Authorization": f"Bearer {token}"})
        print("GET /properties/rooms", res2.status_code)

asyncio.run(test())
