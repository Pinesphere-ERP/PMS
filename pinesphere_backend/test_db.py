import asyncio
import asyncpg
import time
import os
import sys
from dotenv import load_dotenv

if sys.platform == 'win32':
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

load_dotenv()

async def main():
    url = os.environ.get("DATABASE_URL")
    if url.startswith("postgresql+asyncpg://"):
        url = url.replace("postgresql+asyncpg://", "postgresql://")
        
    print(f"Connecting to: {url}")
    start = time.time()
    try:
        conn = await asyncpg.connect(url, timeout=15)
        print(f"Connected in {time.time() - start:.2f}s")
        await conn.close()
    except Exception as e:
        print(f"Failed after {time.time() - start:.2f}s: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
