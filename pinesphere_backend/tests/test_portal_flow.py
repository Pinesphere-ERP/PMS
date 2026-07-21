import os
os.environ["REDIS_URL"] = ""

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
import uuid
from datetime import datetime, timedelta, timezone

from app.main import app
from app.infra.database import AsyncSessionLocal
from app.infra.models import Property, Guest, RoomCategory, Room, Booking, CheckIn, CheckOut, OTPRequest, PortalSession
from app.core.security import get_password_hash

# Pytest async settings
pytestmark = pytest.mark.asyncio

@pytest_asyncio.fixture
async def setup_test_data():
    """Sets up a complete booking, checkin, and OTP flow for the portal."""
    async with AsyncSessionLocal() as db:
        prop_id = uuid.uuid4()
        guest_id = uuid.uuid4()
        cat_id = uuid.uuid4()
        room_id = uuid.uuid4()
        booking_id = uuid.uuid4()
        checkin_id = uuid.uuid4()

        # Seed minimal data required to test the portal
        prop = Property(property_id=prop_id, property_name="Test Property")
        guest = Guest(guest_id=guest_id, property_id=prop_id, mobile="+1234567890", full_name="John Doe")
        room_cat = RoomCategory(id=cat_id, property_id=prop_id, category="Deluxe")
        room = Room(room_id=room_id, property_id=prop_id, room_type_id=cat_id, room_number="101")
        
        booking = Booking(
            booking_id=booking_id,
            property_id=prop_id,
            guest_id=guest_id,
            room_id=room_id,
            booking_reference="B-123456",
            booking_status="checked_in",
            check_in_date=datetime.now(timezone.utc).date() - timedelta(days=1),
            check_out_date=datetime.now(timezone.utc).date() + timedelta(days=1),
        )

        checkin = CheckIn(
            checkin_id=checkin_id,
            property_id=prop_id,
            booking_id=booking_id,
            room_id=room_id,
            status="active"
        )

        # Pre-seed OTP
        otp_val = "123456"
        otp_req = OTPRequest(
            id=uuid.uuid4(),
            booking_id=booking_id,
            purpose="guest_portal",
            otp_hash=get_password_hash(otp_val),
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=5)
        )

        db.add_all([prop, guest, room_cat, room, booking, checkin, otp_req])
        await db.commit()

        yield {
            "prop_id": prop_id,
            "guest_id": guest_id,
            "room_id": room_id,
            "booking_id": booking_id,
            "booking_ref": "B-123456",
            "mobile": "+1234567890",
            "otp": "123456"
        }

        # Cleanup
        await db.execute(OTPRequest.__table__.delete())
        await db.execute(PortalSession.__table__.delete())
        await db.execute(CheckOut.__table__.delete())
        await db.execute(CheckIn.__table__.delete())
        await db.execute(Booking.__table__.delete())
        await db.execute(Room.__table__.delete())
        await db.execute(RoomCategory.__table__.delete())
        await db.execute(Guest.__table__.delete())
        await db.execute(Property.__table__.delete())
        await db.commit()

async def test_portal_lifecycle_flow(setup_test_data):
    """
    Tests the complete guest portal flow from login, through dashboard,
    checkout, and 24-hour grace period expiration.
    """
    td = setup_test_data
    
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Login with OTP
        login_res = await client.post("/portal/auth/verify-otp", json={
            "booking_reference": td["booking_ref"],
            "mobile": td["mobile"],
            "otp": td["otp"]
        })
        assert login_res.status_code == 200
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Access dashboard
        me_res = await client.get("/portal/me", headers=headers)
        assert me_res.status_code == 200
        
        # 3. Request Service
        svc_res = await client.post("/portal/services", headers=headers, json={
            "service_category": "housekeeping",
            "description": "Clean room"
        })
        assert svc_res.status_code == 201

        # 4. Perform Backend Checkout
        async with AsyncSessionLocal() as db:
            from app.modules.checkout.schemas import CheckOutRequest
            from app.modules.checkout.service import perform_checkout
            
            # Find checkin
            from sqlalchemy import select
            ci_res = await db.execute(select(CheckIn).where(CheckIn.booking_id == td["booking_id"]))
            checkin = ci_res.scalars().first()
            
            req = CheckOutRequest(
                checkin_id=checkin.checkin_id,
                room_charges=100.0,
                restaurant_charges=0,
                laundry_charges=0,
                minibar_charges=0,
                damage_charges=0,
                miscellaneous_charges=0,
                discount=0,
                gst=10,
                total_amount=110,
                amount_paid=110,
                key_returned=True,
                id_returned=True
            )
            # Perform checkout
            await perform_checkout(db, req, td["prop_id"])
        
        # 5. Verify Service Request fails (checked out)
        svc_res_2 = await client.post("/portal/services", headers=headers, json={
            "service_category": "housekeeping",
            "description": "Clean room again"
        })
        assert svc_res_2.status_code == 403

        # 6. Verify Dashboard still works (Grace Period)
        me_res_2 = await client.get("/portal/me", headers=headers)
        assert me_res_2.status_code == 200

        # 7. Advance Clock by 24h
        async with AsyncSessionLocal() as db:
            co_res = await db.execute(select(CheckOut).where(CheckOut.booking_id == td["booking_id"]))
            checkout = co_res.scalars().first()
            
            # Backdate checkout by 25 hours
            past = datetime.now(timezone.utc) - timedelta(hours=25)
            checkout.created_at = past
            await db.commit()
            
            # We also need to invalidate the redis cache again for the test to reflect time skip
            from app.modules.portal.cache import PortalCache
            ps_res = await db.execute(select(PortalSession.session_id).where(PortalSession.booking_id == td["booking_id"]))
            for s_id in ps_res.scalars():
                await PortalCache.invalidate_context(s_id)

        # 8. Verify all access lost
        me_res_3 = await client.get("/portal/me", headers=headers)
        assert me_res_3.status_code == 403
