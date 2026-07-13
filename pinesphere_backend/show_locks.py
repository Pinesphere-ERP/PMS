import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect("postgresql://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require")
    try:
        rows = await conn.fetch("SELECT pid, state, query FROM pg_stat_activity WHERE state != 'idle';")
        for r in rows:
            print(f"PID: {r['pid']} State: {r['state']} Query: {r['query']}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await conn.close()

asyncio.run(main())
