import asyncio
import httpx

async def main():
    async with httpx.AsyncClient() as client:
        resp = await client.post("https://pms-bvko.onrender.com/api/v1/auth/login", json={
            "email": "admin@pinesphere.com",
            "password": "password123",
            "device_id": "test-device",
            "device_name": "Test Device",
            "device_fingerprint": "test-fingerprint"
        })
        print(resp.status_code)
        print(resp.text)

asyncio.run(main())
