import asyncio
import uuid
from fastapi.testclient import TestClient
from app.main import app
from app.infra.database import AsyncSessionLocal, engine
from app.infra.models import Base, Role, User
from sqlalchemy import select, insert
from app.core.security import get_password_hash

client = TestClient(app)

async def seed_super_admin():
    async with engine.begin() as conn:
        conn_opt = await conn.execution_options(schema_translate_map={"public": None})
        for table in Base.metadata.sorted_tables:
            try:
                await conn_opt.run_sync(table.create)
            except Exception as e:
                if 'already exists' not in str(e):
                    print(f"Error creating {table.name}: {e}")
        
    async with AsyncSessionLocal() as db:
        roles_to_seed = ['SUPER_ADMIN', 'OWNER', 'MANAGER', 'HOUSEKEEPING']
        for role_code in roles_to_seed:
            result = await db.execute(select(Role).where(Role.role_code == role_code))
            if not result.scalar_one_or_none():
                db.add(Role(
                    id=uuid.uuid4(),
                    role_code=role_code,
                    role_name=role_code.capitalize(),
                    is_system_role=True,
                    description=f'{role_code} role'
                ))
        await db.flush()

        result = await db.execute(select(User).where(User.email == 'super@test.com'))
        super_admin = result.scalar_one_or_none()
        if not super_admin:
            result = await db.execute(select(Role).where(Role.role_code == 'SUPER_ADMIN'))
            super_role = result.scalar_one()
            super_admin = User(
                id=uuid.uuid4(),
                email='super@test.com',
                mobile_number='0000000001',
                name='Super Admin Test',
                password_hash=get_password_hash('password123'),
                role_id=super_role.id,
                status='ACTIVE'
            )
            db.add(super_admin)
            
        # Seed USERS permission if not exists
        from app.infra.models import Permission, RolePermission
        perm = (await db.execute(select(Permission).where(Permission.permission_code == 'USERS'))).scalar_one_or_none()
        if not perm:
            perm = Permission(id=uuid.uuid4(), permission_code='USERS', module_name='userRoleManagement', description='Users Permission')
            db.add(perm)
            await db.flush()
            
            # Give OWNER and MANAGER access to USERS
            for code in ['OWNER', 'MANAGER']:
                r = (await db.execute(select(Role).where(Role.role_code == code))).scalar_one()
                db.add(RolePermission(
                    id=uuid.uuid4(),
                    role_id=r.id,
                    permission_id=perm.id,
                    access_level='FULL'
                ))
            
        await db.commit()

asyncio.run(seed_super_admin())

print("--- STARTING FLOW TEST ---")

# 1. Login as Super Admin (must use web)
response = client.post("/api/v1/auth/login", headers={"X-Client-Platform": "web"}, json={
    "email": "super@test.com",
    "password": "password123",
    "device_id": str(uuid.uuid4()),
    "device_fp": "test_device",
    "property_id": None
})
assert response.status_code == 200, f"Super Admin login failed: {response.text}"
super_token = response.json()["access_token"]
print("✅ Super Admin login successful")

# 2. Super Admin creates an Owner User (property_id=None)
async def get_owner_role_id():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Role).where(Role.role_code == 'OWNER'))
        return str(result.scalar_one().id)

owner_role_id = asyncio.run(get_owner_role_id())

owner_email = f"owner_{uuid.uuid4().hex[:6]}@test.com"
response = client.post("/api/v1/users", headers={"Authorization": f"Bearer {super_token}"}, json={
    "name": "Test Owner",
    "email": owner_email,
    "mobile_number": f"1{uuid.uuid4().hex[:9]}",
    "password": "password123",
    "role_id": owner_role_id,
    "property_id": None
})
assert response.status_code == 201, f"Failed to create Owner user: {response.text}"
owner_user_id = response.json()["id"]
print(f"✅ Super Admin created Owner user (ID: {owner_user_id})")

# 3. Super Admin creates a Property and wires it to the newly created Owner User
response = client.post("/api/v1/properties", headers={"Authorization": f"Bearer {super_token}"}, json={
    "owner_user_id": owner_user_id,
    "owner_name": "Test Owner",
    "owner_mobile": f"1{uuid.uuid4().hex[:9]}",
    "owner_email": owner_email,
    "business_name": "Test Business",
    "property_name": "Test Property Resort",
    "property_type": "Resort"
})
assert response.status_code == 200, f"Failed to create Property: {response.text}"
property_id = response.json()["property_id"]

# 3.5 Create a dummy subscription for the property so it passes require_subscription
async def create_dummy_subscription(prop_id):
    async with AsyncSessionLocal() as db:
        from app.infra.models import Subscription
        import datetime
        db.add(Subscription(
            id=uuid.uuid4(),
            property_id=uuid.UUID(prop_id),
            plan="BASIC",
            billing_cycle="MONTHLY",
            start_date=datetime.date.today(),
            expiry_date=datetime.date.today() + datetime.timedelta(days=365),
            status="Active"
        ))
        await db.commit()
asyncio.run(create_dummy_subscription(property_id))

print(f"✅ Super Admin created Property and wired Owner user to Property (ID: {property_id})")

# 4. Login as Owner (can use web or app, we'll use web)
response = client.post("/api/v1/auth/login", headers={"X-Client-Platform": "web"}, json={
    "email": owner_email,
    "password": "password123",
    "device_id": str(uuid.uuid4()),
    "device_fp": "owner_device",
    "property_id": property_id
})
assert response.status_code == 200, f"Owner login failed: {response.text}"
owner_token = response.json()["access_token"]
print("✅ Owner login successful")

# 5. Owner creates a Manager User
async def get_manager_role_id():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Role).where(Role.role_code == 'MANAGER'))
        return str(result.scalar_one().id)

manager_role_id = asyncio.run(get_manager_role_id())

manager_email = f"manager_{uuid.uuid4().hex[:6]}@test.com"
response = client.post("/api/v1/users", headers={"Authorization": f"Bearer {owner_token}", "X-Tenant-ID": property_id}, json={
    "name": "Test Manager",
    "email": manager_email,
    "mobile_number": f"2{uuid.uuid4().hex[:9]}",
    "password": "password123",
    "role_id": manager_role_id
})
assert response.status_code == 201, f"Failed to create Manager user: {response.text}"
manager_user_id = response.json()["id"]
assert response.json()["property_id"] == property_id, "Manager property_id does not match!"
print(f"✅ Owner created Manager user (ID: {manager_user_id})")

# 6. Login as Manager (must use app)
response = client.post("/api/v1/auth/login", headers={"X-Client-Platform": "app"}, json={
    "email": manager_email,
    "password": "password123",
    "device_id": str(uuid.uuid4()),
    "device_fp": "manager_device",
    "property_id": property_id
})
assert response.status_code == 200, f"Manager login failed: {response.text}"
manager_token = response.json()["access_token"]
print("✅ Manager login successful")

# 7. Manager creates a Housekeeping User
async def get_housekeeping_role_id():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Role).where(Role.role_code == 'HOUSEKEEPING'))
        return str(result.scalar_one().id)

hk_role_id = asyncio.run(get_housekeeping_role_id())

hk_email = f"hk_{uuid.uuid4().hex[:6]}@test.com"
response = client.post("/api/v1/users", headers={"Authorization": f"Bearer {manager_token}", "X-Tenant-ID": property_id}, json={
    "name": "Test Housekeeper",
    "email": hk_email,
    "mobile_number": f"3{uuid.uuid4().hex[:9]}",
    "password": "password123",
    "role_id": hk_role_id
})
assert response.status_code == 201, f"Failed to create Housekeeping user: {response.text}"
hk_user_id = response.json()["id"]
assert response.json()["property_id"] == property_id, "Housekeeping property_id does not match!"
print(f"✅ Manager created Housekeeping user (ID: {hk_user_id})")

# 8. Verify Housekeeping can fetch tasks
# (A quick check to make sure their context is correct)
response = client.post("/api/v1/auth/login", headers={"X-Client-Platform": "app"}, json={
    "email": hk_email,
    "password": "password123",
    "device_id": str(uuid.uuid4()),
    "device_fp": "hk_device",
    "property_id": property_id
})
assert response.status_code == 200, f"Housekeeping login failed: {response.text}"
hk_token = response.json()["access_token"]
print("✅ Housekeeping login successful")

response = client.get(f"/api/v1/tasks?property_id={property_id}", headers={"Authorization": f"Bearer {hk_token}", "X-Tenant-ID": property_id})
assert response.status_code == 200, f"Housekeeping failed to list tasks: {response.text}"
print("✅ Housekeeping successfully accessed property tasks")

print("--- FLOW TEST PASSED ---")
