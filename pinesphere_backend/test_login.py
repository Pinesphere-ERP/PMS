import asyncio
import sys
import os

# Add pinesphere_backend to sys.path so we can import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.infra.database import AsyncSessionLocal
from app.modules.auth.schemas import LoginRequest
from app.modules.auth.service import AuthService

async def main():
    login_data = LoginRequest(
        email="admin@pinesphere.com",
        password="password123",
        device_uid="d3b54011-e54b-448f-8244-6e4ba1ef094f"
    )
    
    async with AsyncSessionLocal() as db:
        service = AuthService(db)
        try:
            res = await service.login(login_data)
            print("Login successful:", res)
        except Exception as e:
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
