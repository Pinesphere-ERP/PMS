import asyncio, asyncpg
async def main():
    conn = await asyncpg.connect('postgresql://pinesphere_app:pinesphere_password@localhost:5444/pinesphere')
    rows = await conn.fetch('SELECT * FROM payments')
    print(rows)
asyncio.run(main())