import asyncio
import asyncpg
import sys

async def main():
    try:
        conn = await asyncpg.connect('postgresql://pinesphere:pinesphere_password@localhost:5432/pinesphere')
        print("Connected as superuser. Creating pinesphere_app role...")
        
        await conn.execute("""
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'pinesphere_app') THEN
                    CREATE ROLE pinesphere_app WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
                        PASSWORD 'pinesphere_password';
                END IF;
            END$$;
        """)
        
        await conn.execute("GRANT USAGE ON SCHEMA public TO pinesphere_app;")
        await conn.execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO pinesphere_app;")
        await conn.execute("GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO pinesphere_app;")
        await conn.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pinesphere_app;")
        await conn.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO pinesphere_app;")
        
        try:
            await conn.execute("REVOKE UPDATE, DELETE ON TABLE audit_logs FROM pinesphere_app;")
            await conn.execute("GRANT SELECT, INSERT ON TABLE audit_logs TO pinesphere_app;")
        except Exception as e:
            pass # audit_logs table might not exist yet if other migrations are missing
            
        print("✅ pinesphere_app role created and granted permissions successfully!")
        await conn.close()
    except Exception as e:
        print(f"❌ Error: {e}")

asyncio.run(main())
