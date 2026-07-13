import asyncio
import uuid
import json
import random
from datetime import date, datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.infra.models import (
    Owner, Business, Property, User, Role, Device, UserDevice, UserSession,
    StaffInvitation, CredentialResetRequest, UserSyncLog, RoomCategory, Room, Guest, Booking, CheckIn, CheckOut,
    Invoice, Payment, Subscription, SubscriptionTransaction, PaymentTransaction, PendingDue, InvoiceItem, SplitPayment,
    DailyKPISnapshot, ReportTemplate, ScheduledReport, SystemConfiguration, PropertySetting, RoomAssignment,
    HousekeepingTask, MaintenanceTicket, LostAndFound, AuditLog
)
from app.core.security import get_password_hash

async def seed_admin_mock_data():
    engine = create_async_engine("sqlite+aiosqlite:///./pinesphere.db", echo=True)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        async with session.begin():
            now = datetime.now(timezone.utc)
            today = date.today()

            # Create Roles
            roles_map = {}
            for r_code in ["SUPER_ADMIN", "OWNER", "MANAGER", "RECEPTION"]:
                stmt = select(Role).where(Role.role_code == r_code)
                role = (await session.execute(stmt)).scalar_one_or_none()
                if not role:
                    role = Role(id=uuid.uuid4(), role_code=r_code, role_name=r_code.title(), is_system_role=True)
                    session.add(role)
                roles_map[r_code] = role
            
            await session.flush()

            # Create 3 Owners
            owners = []
            for i in range(1, 4):
                o = Owner(
                    owner_id=uuid.uuid4(),
                    full_name=f"Admin Mock Owner {i}",
                    designation="CEO",
                    mobile_number=f"100000000{i}",
                    email=f"owner{i}@adminmock.com",
                    mobile_verified=True,
                    email_verified=True
                )
                session.add(o)
                owners.append(o)
            await session.flush()

            # Create 3 Businesses
            businesses = []
            for i, o in enumerate(owners):
                b = Business(
                    business_id=uuid.uuid4(),
                    owner_id=o.owner_id,
                    business_type="Chain",
                    business_name=f"Admin Mock Business {i+1}",
                )
                session.add(b)
                businesses.append(b)
            await session.flush()

            # Create 10 Properties
            properties = []
            for i in range(1, 11):
                b = businesses[i % 3]
                p = Property(
                    property_id=uuid.uuid4(),
                    business_id=b.business_id,
                    owner_id=b.owner_id,
                    property_name=f"Admin Mock Property {i}",
                    property_type="Hotel" if i % 2 == 0 else "Resort",
                    star_category=random.choice([3, 4, 5]),
                    year_established=random.randint(2010, 2025),
                    total_floors=random.randint(2, 10),
                    total_rooms=random.randint(20, 200),
                    description=f"Admin Mock Property {i} Description.",
                    whatsapp_number=f"20000000{i:02d}",
                    onboarding_status=random.choice(["active", "pending", "draft"])
                )
                session.add(p)
                properties.append(p)
            await session.flush()

            # Create 15 Users
            users = []
            for i in range(1, 16):
                p = random.choice(properties)
                role_code = random.choice(["MANAGER", "RECEPTION"])
                u = User(
                    id=uuid.uuid4(),
                    property_id=p.property_id,
                    role_id=roles_map[role_code].id,
                    name=f"Admin Mock User {i}",
                    username=f"admin_mock_{i}",
                    email=f"user{i}@adminmock.com",
                    mobile_number=f"30000000{i:02d}",
                    status=random.choice(["ACTIVE", "INACTIVE", "PENDING"]),
                    password_hash=get_password_hash("password123")
                )
                session.add(u)
                users.append(u)
            await session.flush()

            # Create 10 Devices
            devices = []
            for i in range(1, 11):
                p = random.choice(properties)
                u = random.choice([user for user in users if user.property_id == p.property_id] or [users[0]])
                d = Device(
                    id=uuid.uuid4(),
                    device_uid=f"mock-dev-{uuid.uuid4().hex[:8]}",
                    property_id=p.property_id,
                    primary_user_id=u.id,
                    device_name=f"Admin Mock Device {i}",
                    os_type=random.choice(["android", "ios"]),
                    status=random.choice(["active", "pending_approval", "revoked"])
                )
                session.add(d)
                devices.append(d)
            await session.flush()

            # Create Subscriptions
            for p in properties:
                status = random.choice(["Active", "Expired", "Suspended", "Pending"])
                plan = random.choice(["Basic", "Premium", "Enterprise"])
                sub = Subscription(
                    id=uuid.uuid4(),
                    property_id=p.property_id,
                    plan=plan,
                    billing_cycle=random.choice(["monthly", "yearly"]),
                    start_date=today - timedelta(days=random.randint(10, 300)),
                    expiry_date=today + timedelta(days=random.randint(-10, 365)),
                    status=status
                )
                session.add(sub)
                
                # Create Pending Dues for some
                if status == "Expired" or random.random() > 0.7:
                    session.add(PendingDue(
                        id=uuid.uuid4(),
                        property_id=p.property_id,
                        plan=plan,
                        due_date=today - timedelta(days=random.randint(1, 30)),
                        amount_due=random.choice([99.0, 199.0, 499.0]),
                        days_overdue=random.randint(1, 30)
                    ))
            
            # Create Audit Logs
            for i in range(20):
                p = random.choice(properties)
                u = random.choice([user for user in users if user.property_id == p.property_id] or [users[0]])
                session.add(AuditLog(
                    log_id=uuid.uuid4(),
                    property_id=p.property_id,
                    user_id=u.id,
                    timestamp=now - timedelta(hours=random.randint(1, 72)),
                    module_name=random.choice(["Authentication", "Booking", "Settings", "Subscription"]),
                    action_type=random.choice(["CREATE", "UPDATE", "DELETE", "LOGIN"]),
                    target_entity="User",
                    ip_address="192.168.1." + str(random.randint(1, 255)),
                    old_value_snapshot=json.dumps({"status": "PENDING"}),
                    new_value_snapshot=json.dumps({"status": "ACTIVE"})
                ))

            # System Configs
            session.add(SystemConfiguration(id=uuid.uuid4(), config_key="maintenance_mode", config_value=json.dumps({"enabled": False})))
            session.add(SystemConfiguration(id=uuid.uuid4(), config_key="max_login_attempts", config_value=json.dumps({"value": 5})))
            session.add(SystemConfiguration(id=uuid.uuid4(), config_key="default_currency", config_value=json.dumps({"currency": "INR"})))

            await session.commit()
            print("Extensive admin mock data seeded successfully!")

if __name__ == "__main__":
    asyncio.run(seed_admin_mock_data())
