import asyncio
import uuid
import sys
import os
from datetime import datetime, date, timedelta

# Add pinesphere_backend to sys.path so we can import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.infra.database import AsyncSessionLocal
from app.infra.models import (
    Owner, Business, Property, Role, User, RoomCategory, Room, Guest, Booking, Device
)
from app.core.security import get_password_hash

async def seed_data():
    print("Starting data seeding...")
    async with AsyncSessionLocal() as db:
        try:
            # 1. Check if owner already exists to prevent duplicate emails
            result = await db.execute(select(Owner).filter_by(email="admin@pinesphere.com"))
            existing_owner = result.scalars().first()
            if existing_owner:
                print("Mock data already exists! Seeding skipped.")
                return

            print("Creating Owner...")
            owner_id = uuid.uuid4()
            owner = Owner(
                owner_id=owner_id,
                full_name="Mock Admin",
                mobile_number="9999999999",
                email="admin@pinesphere.com",
                password_hash=get_password_hash("password123"),
                mobile_verified=True,
                email_verified=True
            )
            db.add(owner)
            await db.flush()

            print("Creating Business...")
            business_id = uuid.uuid4()
            business = Business(
                business_id=business_id,
                owner_id=owner.owner_id,
                business_name="Pinesphere Hotels Ltd"
            )
            db.add(business)
            await db.flush()

            print("Creating Property...")
            property_id = uuid.uuid4()
            prop = Property(
                property_id=property_id,
                business_id=business.business_id,
                owner_id=owner.owner_id,
                property_name="The Grand Pines Hotel",
                property_type="Hotel",
                total_rooms=20,
                onboarding_status="completed"
            )
            db.add(prop)
            await db.flush()

            print("Creating Role...")
            role_id = uuid.uuid4()
            role = Role(
                id=role_id,
                property_id=property_id,
                role_code="OWNER",
                role_name="Property Owner"
            )
            db.add(role)
            await db.flush()

            print("Creating User...")
            user_id = uuid.uuid4()
            user = User(
                id=user_id,
                property_id=property_id,
                role_id=role_id,
                name="Admin User",
                email="admin@pinesphere.com",
                password_hash=get_password_hash("password123"),
                status="ACTIVE",
                is_primary_owner=True
            )
            db.add(user)
            await db.flush()

            print("Creating Room Categories...")
            cat_deluxe_id = uuid.uuid4()
            cat_deluxe = RoomCategory(
                room_category_id=cat_deluxe_id,
                property_id=property_id,
                room_name="Deluxe Suite",
                base_price=5000.00
            )
            cat_standard_id = uuid.uuid4()
            cat_standard = RoomCategory(
                room_category_id=cat_standard_id,
                property_id=property_id,
                room_name="Standard Room",
                base_price=3000.00
            )
            db.add_all([cat_deluxe, cat_standard])
            await db.flush()

            print("Creating Rooms...")
            room_101_id = uuid.uuid4()
            room_101 = Room(
                room_id=room_101_id,
                room_category_id=cat_deluxe_id,
                room_number="101",
                occupancy_status="vacant",
                housekeeping_status="clean"
            )
            room_102_id = uuid.uuid4()
            room_102 = Room(
                room_id=room_102_id,
                room_category_id=cat_standard_id,
                room_number="102",
                occupancy_status="occupied",
                housekeeping_status="clean"
            )
            db.add_all([room_101, room_102])
            await db.flush()

            print("Creating Guest...")
            guest_id = uuid.uuid4()
            guest = Guest(
                guest_id=guest_id,
                full_name="John Doe",
                mobile="8888888888",
                email="john.doe@example.com"
            )
            db.add(guest)
            await db.flush()

            print("Creating Booking...")
            booking_id = uuid.uuid4()
            booking = Booking(
                booking_id=booking_id,
                property_id=property_id,
                room_id=room_102_id,
                guest_id=guest_id,
                check_in_date=date.today(),
                check_out_date=date.today() + timedelta(days=2),
                adults=2,
                room_rent=6000.00,
                total_payable=6000.00,
                booking_status="confirmed"
            )
            db.add(booking)
            await db.flush()

            await db.commit()
            print("Mock data seeded successfully!")
            print(f"Login with email: admin@pinesphere.com")
            print(f"Password: password123")
            print(f"Property ID (if needed): {property_id}")
            
        except Exception as e:
            await db.rollback()
            print(f"Error seeding data: {e}")

if __name__ == "__main__":
    asyncio.run(seed_data())
