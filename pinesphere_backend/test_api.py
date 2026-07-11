import asyncio, httpx
async def main():
  async with httpx.AsyncClient() as client:
    r = await client.get('http://127.0.0.1:8000/api/v1/payments/?page=1&size=20')
    print(r.status_code)
    print(r.text)
asyncio.run(main())