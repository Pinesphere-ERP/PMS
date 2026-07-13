import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.infra.models import Owner, Business, Property, User, Role
from app.core.security import get_password_hash

async def seed_mock_data(db: AsyncSession):
    # Check if mock data already exists
    stmt = select(Property).where(Property.property_name == "Sunset Grand Hotel")
    res = await db.execute(stmt)
    if res.scalar_one_or_none():
        return # Already seeded

    # Create Mock Owner
    owner_id = uuid.uuid4()
    owner = Owner(
        owner_id=owner_id,
        full_name="John Doe",
        designation="Managing Director",
        mobile_number="9876543210",
        email="john.doe@example.com",
        mobile_verified=True,
        email_verified=True
    )
    db.add(owner)
    await db.flush()

    # Create Mock Business
    business_id = uuid.uuid4()
    business = Business(
        business_id=business_id,
        owner_id=owner_id,
        business_type="Hotel Chain",
        business_name="Sunset Hospitality Group",
    )
    db.add(business)
    await db.flush()

    # Create Mock Properties
    prop1_id = uuid.uuid4()
    prop1 = Property(
        property_id=prop1_id,
        business_id=business_id,
        owner_id=owner_id,
        property_name="Sunset Grand Hotel",
        property_type="Hotel",
        star_category=5,
        year_established=2015,
        total_floors=10,
        total_rooms=200,
        description="Luxury 5-star hotel in the city center.",
        whatsapp_number="9876543211",
        onboarding_status="active"
    )
    db.add(prop1)

    prop2_id = uuid.uuid4()
    prop2 = Property(
        property_id=prop2_id,
        business_id=business_id,
        owner_id=owner_id,
        property_name="Sunset Boutique Resort",
        property_type="Resort",
        star_category=4,
        year_established=2020,
        total_floors=3,
        total_rooms=50,
        description="A beautiful beachfront resort.",
        whatsapp_number="9876543212",
        onboarding_status="active"
    )
    db.add(prop2)
    await db.flush()

    # Fetch Roles
    res = await db.execute(select(Role))
    roles = {r.role_code: r for r in res.scalars().all()}
    
    if "MANAGER" in roles:
        # Create Mock User (Manager) for Property 1
        user1 = User(
            id=uuid.uuid4(),
            property_id=prop1_id,
            role_id=roles["MANAGER"].id,
            name="Alice Smith",
            username="alice_mgr",
            email="alice@sunset.com",
            mobile_number="9876543220",
            status="ACTIVE",
            password_hash=get_password_hash("password123")
        )
        db.add(user1)

    if "RECEPTION" in roles:
        # Create Mock User (Reception) for Property 1
        user2 = User(
            id=uuid.uuid4(),
            property_id=prop1_id,
            role_id=roles["RECEPTION"].id,
            name="Bob Jones",
            username="bob_rec",
            email="bob@sunset.com",
            mobile_number="9876543221",
            status="ACTIVE",
            password_hash=get_password_hash("password123")
        )
        db.add(user2)

    await db.commit()
    print("Mock data seeded successfully!")
