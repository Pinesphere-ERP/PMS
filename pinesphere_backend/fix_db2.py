import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect("postgresql://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require")
    try:
        sql = """
        CREATE TABLE user_sessions (
            id UUID PRIMARY KEY,
            user_id UUID,
            device_id UUID,
            session_token VARCHAR,
            is_offline_session BOOLEAN,
            issued_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
            expires_at TIMESTAMP WITHOUT TIME ZONE,
            revoked_at TIMESTAMP WITHOUT TIME ZONE,
            revoked_reason VARCHAR
        );
        """
        await conn.execute(sql)
        print("Table user_sessions created successfully")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await conn.close()

asyncio.run(main())
