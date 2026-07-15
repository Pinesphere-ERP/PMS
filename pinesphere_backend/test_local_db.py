import asyncio
import asyncpg
import time

async def main():
    urls = [
        "postgresql://postgres:postgres@localhost:5432/postgres",
        "postgresql://postgres@localhost:5432/postgres",
        "postgresql://postgres:admin@localhost:5432/postgres",
        "postgresql://postgres:root@localhost:5432/postgres",
        "postgresql://admin:admin@localhost:5432/postgres",
        "postgresql://root:root@localhost:5432/postgres",
        "postgresql://postgres:password@localhost:5432/postgres"
    ]
    
    for url in urls:
        print(f"Testing local connection: {url}")
        try:
            conn = await asyncpg.connect(url, timeout=2)
            print(f"SUCCESS: Connected to {url}")
            await conn.close()
            return
        except asyncpg.exceptions.InvalidAuthorizationSpecificationError:
            print(f"FAILED (Auth): {url}")
        except asyncpg.exceptions.InvalidPasswordError:
            print(f"FAILED (Password): {url}")
        except Exception as e:
            print(f"FAILED: {e}")

if __name__ == "__main__":
    asyncio.run(main())
