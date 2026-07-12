import asyncio
import uuid
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.core.security import get_password_hash
from app.infra.models import Owner, Business, Property, RoomCategory, Room, User, Subscription, Device, Role

async def seed_data():
    engine = create_async_engine(settings.DATABASE_URL, echo=True)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        async with session.begin():
            # Check if Owner already exists
            owner_id = uuid.UUID("11111111-1111-1111-1111-111111111111")
            owner = await session.get(Owner, owner_id)
            if not owner:
                owner = Owner(
                    owner_id=owner_id,
                    full_name="PineSphere Owner",
                    email="owner@pinesphere.com",
                    mobile_number="+91 9999999999",
                )
                session.add(owner)
                print("Owner created.")

            # Check if Business already exists
            business_id = uuid.UUID("22222222-2222-2222-2222-222222222222")
            business = await session.get(Business, business_id)
            if not business:
                business = Business(
                    business_id=business_id,
                    owner_id=owner_id,
                    business_name="PineSphere Resorts Ltd",
                )
                session.add(business)
                print("Business created.")

            # Check if Resorts/Properties already exist
            # Resort 1: Kodaikanal
            resort_1_id = uuid.UUID("33333333-3333-3333-3333-333333333333")
            resort_1 = await session.get(Property, resort_1_id)
            if not resort_1:
                resort_1 = Property(
                    property_id=resort_1_id,
                    business_id=business_id,
                    owner_id=owner_id,
                    property_name="PineSphere Forest Resort",
                    property_type="Resort",
                )
                session.add(resort_1)
                print("Resort 1 created.")

            # Resort 2: Varkala
            resort_2_id = uuid.UUID("44444444-4444-4444-4444-444444444444")
            resort_2 = await session.get(Property, resort_2_id)
            if not resort_2:
                resort_2 = Property(
                    property_id=resort_2_id,
                    business_id=business_id,
                    owner_id=owner_id,
                    property_name="PineSphere Beachside Sanctuary",
                    property_type="Resort",
                )
                session.add(resort_2)
                print("Resort 2 created.")

            await session.flush()

            # Create a Role for Resort 1
            role_id = uuid.UUID("cccccccc-cccc-cccc-cccc-cccccccccccc")
            role = await session.get(Role, role_id)
            if not role:
                role = Role(
                    id=role_id,
                    property_id=resort_1_id,
                    role_code="owner",
                    role_name="Owner",
                    is_system_role=True
                )
                session.add(role)
                print("Role created.")

            # Create a Subscription for Resort 1
            subscription_id = uuid.UUID("dddddddd-dddd-dddd-dddd-dddddddddddd")
            subscription = await session.get(Subscription, subscription_id)
            if not subscription:
                from datetime import date
                subscription = Subscription(
                    id=subscription_id,
                    property_id=resort_1_id,
                    plan="Enterprise Offline",
                    billing_cycle="yearly",
                    start_date=date(2026, 1, 1),
                    expiry_date=date(2030, 12, 31),
                    status="Active",
                    license_id="LIC-12345"
                )
                session.add(subscription)
                print("Subscription created.")

            # Create a User (Staff/Admin) for Resort 1
            user_id = uuid.UUID("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")
            user = await session.get(User, user_id)
            if not user:
                user = User(
                    id=user_id,
                    property_id=resort_1_id,
                    role_id=role_id,
                    name="Admin User",
                    email="admin@pinesphere.com",
                    password_hash=get_password_hash("password123"),
                    status="ACTIVE",
                    is_primary_owner=True
                )
                session.add(user)
                print("Admin User created (admin@pinesphere.com / password123).")

            # Create a Device for Resort 1
            device_id = uuid.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff")
            device = await session.get(Device, device_id)
            if not device:
                device = Device(
                    id=device_id,
                    device_uid="mock-device-fingerprint-12345",
                    property_id=resort_1_id,
                    primary_user_id=user_id,
                    device_name="Admin Test Device",
                    os_type="android",
                    status="active"
                )
                session.add(device)
                print("Admin Device created.")

            await session.flush()

            # Create Room Categories for Resort 1 if not exists
            cat_deluxe_1_id = uuid.UUID("55555555-5555-5555-5555-555555555555")
            cat_deluxe_1 = await session.get(RoomCategory, cat_deluxe_1_id)
            if not cat_deluxe_1:
                cat_deluxe_1 = RoomCategory(
                    room_category_id=cat_deluxe_1_id,
                    property_id=resort_1_id,
                    room_name="Deluxe Suite",
                    number_of_rooms=2,
                    base_price=120.0
                )
                session.add(cat_deluxe_1)

            cat_twin_1_id = uuid.UUID("66666666-6666-6666-6666-666666666666")
            cat_twin_1 = await session.get(RoomCategory, cat_twin_1_id)
            if not cat_twin_1:
                cat_twin_1 = RoomCategory(
                    room_category_id=cat_twin_1_id,
                    property_id=resort_1_id,
                    room_name="Twin Room",
                    number_of_rooms=1,
                    base_price=85.0
                )
                session.add(cat_twin_1)

            cat_king_1_id = uuid.UUID("77777777-7777-7777-7777-777777777777")
            cat_king_1 = await session.get(RoomCategory, cat_king_1_id)
            if not cat_king_1:
                cat_king_1 = RoomCategory(
                    room_category_id=cat_king_1_id,
                    property_id=resort_1_id,
                    room_name="Standard King",
                    number_of_rooms=1,
                    base_price=95.0
                )
                session.add(cat_king_1)

            # Create Rooms for Resort 1 if not exists
            # Room 101 (Deluxe)
            room_101_id = uuid.UUID("88888888-8888-8888-8888-888888888888")
            room_101 = await session.get(Room, room_101_id)
            if not room_101:
                room_101 = Room(
                    room_id=room_101_id,
                    room_category_id=cat_deluxe_1_id,
                    room_number="101",
                    housekeeping_status="clean",
                    occupancy_status="occupied"
                )
                session.add(room_101)

            # Room 102 (Twin)
            room_102_id = uuid.UUID("99999999-9999-9999-9999-999999999999")
            room_102 = await session.get(Room, room_102_id)
            if not room_102:
                room_102 = Room(
                    room_id=room_102_id,
                    room_category_id=cat_twin_1_id,
                    room_number="102",
                    housekeeping_status="clean",
                    occupancy_status="vacant"
                )
                session.add(room_102)

            # Room 103 (Standard King)
            room_103_id = uuid.UUID("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
            room_103 = await session.get(Room, room_103_id)
            if not room_103:
                room_103 = Room(
                    room_id=room_103_id,
                    room_category_id=cat_king_1_id,
                    room_number="103",
                    housekeeping_status="cleaning",
                    occupancy_status="vacant"
                )
                session.add(room_103)

            # Room 104 (Deluxe)
            room_104_id = uuid.UUID("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")
            room_104 = await session.get(Room, room_104_id)
            if not room_104:
                room_104 = Room(
                    room_id=room_104_id,
                    room_category_id=cat_deluxe_1_id,
                    room_number="104",
                    housekeeping_status="clean",
                    occupancy_status="vacant"
                )
                session.add(room_104)

            await session.commit()
            print("Database seeded successfully with resorts and rooms!")

if __name__ == "__main__":
    asyncio.run(seed_data())
