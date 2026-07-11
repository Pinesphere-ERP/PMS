import asyncio, asyncpg
async def main():
    conn = await asyncpg.connect('postgresql://pinesphere_app:pinesphere_password@localhost:5444/pinesphere')
    try:
        await conn.execute("INSERT INTO payment_transactions (txn_id, payment_id, event, amount) VALUES ('00000000-0000-0000-0000-000000000000', '94139a54-efd2-4f26-ab49-1d3c3257d5be', 'test', 0)")
        print('inserted')
    except Exception as e:
        print('Error:', type(e), e)
asyncio.run(main())
