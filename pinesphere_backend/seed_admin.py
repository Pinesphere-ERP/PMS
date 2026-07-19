import asyncio
import asyncpg
import ssl
import uuid
import bcrypt
from datetime import datetime

DATABASE_URL = "postgresql://pinesphere_db_wtx9_user:2g5tX4aZ40Y8w3R9M2S5H6P1L3Y5F1M6@dpg-cpl1o75a730s73et3fag-a.singapore-postgres.render.com/pinesphere_db_wtx9"

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

async def main():
    try:
        # Some render databases require standard ssl=True
        conn = await asyncpg.connect(DATABASE_URL, ssl=True)
        print("Connected!")
        
        # 1. Create Owner
        owner_id = str(uuid.uuid4())
        await conn.execute("""
            INSERT INTO public.owners (owner_id, full_name, mobile_number, email, mobile_verified, email_verified, created_at, updated_at)
            VALUES ($1, $2, $3, $4, false, false, $5, $6)
        """, owner_id, "Admin User", "1234567890", "admin@pinesphere.com", datetime.utcnow(), datetime.utcnow())
        
        # 2. Create Business
        business_id = str(uuid.uuid4())
        await conn.execute("""
            INSERT INTO public.businesses (business_id, owner_id, business_name, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5)
        """, business_id, owner_id, "Admin Business", datetime.utcnow(), datetime.utcnow())
        
        # 3. Create Property
        property_id = str(uuid.uuid4())
        await conn.execute("""
            INSERT INTO public.properties (property_id, business_id, owner_id, property_name, onboarding_status, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        """, property_id, business_id, owner_id, "Admin Property", "active", datetime.utcnow(), datetime.utcnow())
        
        # 4. Create Role
        role_id = str(uuid.uuid4())
        await conn.execute("""
            INSERT INTO public.roles (id, property_id, role_code, role_name, is_system_role, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        """, role_id, property_id, "OWNER", "Owner", True, datetime.utcnow(), datetime.utcnow())
        
        # 5. Create User
        user_id = str(uuid.uuid4())
        pw_hash = get_password_hash("password123")
        await conn.execute("""
            INSERT INTO public.users (id, property_id, role_id, name, email, password_hash, status, created_at, updated_at, failed_login_attempts, is_pending_sync, is_primary_owner, biometric_enabled)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        """, user_id, property_id, role_id, "Admin User", "admin@pinesphere.com", pw_hash, "ACTIVE", datetime.utcnow(), datetime.utcnow(), 0, False, True, False)
        
        print("User admin@pinesphere.com created successfully with password123!")

    except Exception as e:
        print("Error:", e)
    finally:
        if 'conn' in locals() and not conn.is_closed():
            await conn.close()

asyncio.run(main())
