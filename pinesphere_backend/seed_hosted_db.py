import asyncio
import uuid
from datetime import datetime
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
import os

from app.core.security import get_password_hash
from app.infra.models import User, Role, Owner, Business, Property, Permission, RolePermission
from app.infra.database import provision_tenant_schema

async def seed_hosted():
    engine = create_async_engine(
        'postgresql+asyncpg://pinesphere_db_wtx9_user:2g5tX4aZ40Y8w3R9M2S5H6P1L3Y5F1M6@dpg-cpl1o75a730s73et3fag-a.singapore-postgres.render.com/pinesphere_db_wtx9?ssl=require'
    )
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as db:
        async with db.begin():
            # 1. Seed Roles
            roles_data = [
                {"role_code": "OWNER", "role_name": "Property Owner", "description": "Default role for Property Owners"},
                {"role_code": "RECEPTIONIST", "role_name": "Receptionist", "description": "Handles guest check-ins and front desk operations"},
                {"role_code": "HOUSEKEEPING", "role_name": "Housekeeping", "description": "Manages room cleaning and status"},
                {"role_code": "MAINTENANCE", "role_name": "Maintenance", "description": "Handles repair and maintenance tasks"},
                {"role_code": "KITCHEN", "role_name": "Kitchen Staff", "description": "Manages dining and room service orders"},
                {"role_code": "MANAGER", "role_name": "Property Manager", "description": "Oversees daily operations"},
                {"role_code": "ACCOUNTANT", "role_name": "Accountant", "description": "Manages billing, invoicing, and finances"},
                {"role_code": "SECURITY", "role_name": "Security Guard", "description": "Monitors property security and visitor logs"},
                {"role_code": "BROKER", "role_name": "Broker", "description": "Manages guest acquisition and broker commissions"}
            ]

            roles_dict = {}
            for r in roles_data:
                role_result = await db.execute(text(f"SELECT id FROM roles WHERE role_code = '{r['role_code']}'"))
                role_row = role_result.first()
                if not role_row:
                    new_role = Role(
                        id=uuid.uuid4(),
                        role_code=r["role_code"],
                        role_name=r["role_name"],
                        is_system_role=True,
                        description=r["description"]
                    )
                    db.add(new_role)
                    await db.flush()
                    roles_dict[r["role_code"]] = new_role.id
                else:
                    roles_dict[r["role_code"]] = role_row.id

            role_id = roles_dict["OWNER"]

            # 2. Seed Permissions
            permissions_data = [
                {"code": "property.manage", "module": "Property", "desc": "Manage property details"},
                {"code": "property.view", "module": "Property", "desc": "View property details"},
                {"code": "bookings.manage", "module": "Bookings", "desc": "Manage bookings"},
                {"code": "bookings.view", "module": "Bookings", "desc": "View bookings"},
                {"code": "rooms.manage", "module": "Rooms", "desc": "Manage rooms"},
                {"code": "rooms.view", "module": "Rooms", "desc": "View rooms"},
                {"code": "staff.manage", "module": "Staff", "desc": "Manage staff members"},
                {"code": "staff.view", "module": "Staff", "desc": "View staff directory"},
                {"code": "reports.view", "module": "Reports", "desc": "View analytics and reports"},
                {"code": "billing.manage", "module": "Billing", "desc": "Manage billing and invoices"},
                {"code": "housekeeping.manage", "module": "Housekeeping", "desc": "Manage housekeeping tasks"},
                {"code": "kitchen.manage", "module": "Kitchen", "desc": "Manage kitchen operations"}
            ]

            permissions_dict = {}
            for p in permissions_data:
                perm_result = await db.execute(text(f"SELECT id FROM permissions WHERE permission_code = '{p['code']}'"))
                perm_row = perm_result.first()
                if not perm_row:
                    new_perm = Permission(
                        id=uuid.uuid4(),
                        permission_code=p['code'],
                        module_name=p['module'],
                        description=p['desc']
                    )
                    db.add(new_perm)
                    await db.flush()
                    permissions_dict[p['code']] = new_perm.id
                else:
                    permissions_dict[p['code']] = perm_row.id

            # 3. Map Permissions to Roles
            role_mappings = {
                "OWNER": ["property.manage", "property.view", "bookings.manage", "bookings.view", "rooms.manage", "rooms.view", "staff.manage", "staff.view", "reports.view", "billing.manage", "housekeeping.manage", "kitchen.manage"],
                "MANAGER": ["property.view", "bookings.manage", "bookings.view", "rooms.manage", "rooms.view", "staff.view", "reports.view", "billing.manage", "housekeeping.manage", "kitchen.manage"],
                "RECEPTIONIST": ["property.view", "bookings.manage", "bookings.view", "rooms.view", "staff.view", "billing.manage"],
                "HOUSEKEEPING": ["rooms.view", "housekeeping.manage"],
                "KITCHEN": ["kitchen.manage"],
                "ACCOUNTANT": ["property.view", "bookings.view", "reports.view", "billing.manage"],
                "SECURITY": ["property.view", "bookings.view"],
                "BROKER": ["bookings.view"],
                "MAINTENANCE": ["rooms.view"]
            }

            for r_code, p_codes in role_mappings.items():
                r_id = roles_dict[r_code]
                for p_code in p_codes:
                    p_id = permissions_dict[p_code]
                    rp_result = await db.execute(text(f"SELECT id FROM role_permissions WHERE role_id = '{r_id}' AND permission_id = '{p_id}'"))
                    rp_row = rp_result.first()
                    if not rp_row:
                        new_rp = RolePermission(
                            id=uuid.uuid4(),
                            role_id=r_id,
                            permission_id=p_id,
                            access_level="write" if "manage" in p_code else "read"
                        )
                        db.add(new_rp)
            await db.flush()


            # Create Owner
            owner_id = uuid.uuid4()
            new_owner = Owner(
                owner_id=owner_id,
                full_name="Admin User",
                email="admin@pinesphere.com",
                mobile_number="1234567890",
                email_verified=True,
                mobile_verified=True
            )
            db.add(new_owner)
            await db.flush()

            # Create Business
            business_id = uuid.uuid4()
            new_business = Business(
                business_id=business_id,
                owner_id=owner_id,
                business_name="Pinesphere Admin Business"
            )
            db.add(new_business)
            await db.flush()

            # Create Property
            property_id = uuid.uuid4()
            new_property = Property(
                property_id=property_id,
                business_id=business_id,
                owner_id=owner_id,
                property_name="Pinesphere Admin Property",
                property_type="HOTEL",
                star_category=5,
                year_established=datetime.now().year,
                onboarding_status="active"
            )
            db.add(new_property)
            await db.flush()
            
            # Create User
            user_id = uuid.uuid4()
            new_user = User(
                id=user_id,
                email="admin@pinesphere.com",
                mobile_number="1234567890",
                password_hash=get_password_hash("password123"),
                name="Admin User",
                role_id=role_id,
                property_id=property_id,
                status="ACTIVE",
                is_primary_owner=True
            )
            db.add(new_user)
            await db.flush()
            print(f"User created: {new_user.email}")
            
    # We must provision tenant schema using the engine directly outside the transaction
    await provision_tenant_schema(str(property_id))
    print("Database seeding completed.")

if __name__ == "__main__":
    asyncio.run(seed_hosted())
