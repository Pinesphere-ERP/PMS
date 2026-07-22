import asyncio
import asyncpg
import ssl

async def main():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    conn = await asyncpg.connect("postgresql://pinesphere_db_wtx9_user:2g5tX4aZ40Y8w3R9M2S5H6P1L3Y5F1M6@dpg-cpl1o75a730s73et3fag-a.singapore-postgres.render.com/pinesphere_db_wtx9", ssl=ctx)
    
    # Get user
    user = await conn.fetchrow("SELECT id, property_id, email, name FROM users WHERE property_id='511e5f8b-bb1e-4f76-a817-6133613f1dd0'")
    print("User:", user)

    if user:
        # Check property
        prop = await conn.fetchrow("SELECT property_id, business_id, owner_id FROM properties WHERE property_id='511e5f8b-bb1e-4f76-a817-6133613f1dd0'")
        print("Property:", prop)

        if not prop:
            print("Property missing! Creating it...")
            # We need an owner. Let's find owner by email.
            owner = await conn.fetchrow("SELECT owner_id FROM owners WHERE email=$1", user['email'])
            print("Owner:", owner)

            if not owner:
                print("Owner missing! Creating it...")
                owner_id = await conn.fetchval("INSERT INTO owners (owner_id, full_name, email, email_verified, mobile_verified, created_at, updated_at) VALUES (gen_random_uuid(), $1, $2, false, false, now(), now()) RETURNING owner_id", user['name'], user['email'])
            else:
                owner_id = owner['owner_id']

            # We need a business
            business = await conn.fetchrow("SELECT business_id FROM businesses WHERE owner_id=$1", owner_id)
            print("Business:", business)

            if not business:
                print("Business missing! Creating it...")
                business_id = await conn.fetchval("INSERT INTO businesses (business_id, owner_id, business_name, created_at, updated_at) VALUES (gen_random_uuid(), $1, $2, now(), now()) RETURNING business_id", owner_id, user['name'] + " Business")
            else:
                business_id = business['business_id']

            # Create property
            await conn.execute("INSERT INTO properties (property_id, business_id, owner_id, property_name, property_type, star_category, onboarding_status, created_at, updated_at) VALUES ('511e5f8b-bb1e-4f76-a817-6133613f1dd0', $1, $2, $3, 'HOTEL', 3, 'draft', now(), now())", business_id, owner_id, "Test Property")
            print("Property created!")
            
    await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
