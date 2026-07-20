import asyncio
import uuid
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from app.main import app
from app.infra.database import AsyncSessionLocal
from app.infra.models import Booking

client = TestClient(app)

async def test_offline_sync():
    print("--- STARTING SYNC FLOW TEST ---")
    response = client.post("/api/v1/auth/login", headers={"X-Client-Platform": "web"}, json={
        "email": "super@test.com",
        "password": "password123",
        "device_id": str(uuid.uuid4()),
        "device_fp": "test_device",
        "property_id": None
    })
    if response.status_code != 200:
        print(f"Login failed: {response.text}")
        return
    token = response.json()["access_token"]
    
    response = client.post("/api/v1/properties", headers={"Authorization": f"Bearer {token}"}, json={
        "owner_name": "Test Owner",
        "owner_mobile": f"1{uuid.uuid4().hex[:9]}",
        "owner_email": f"owner_{uuid.uuid4().hex[:6]}@test.com",
        "business_name": "Test Business",
        "property_name": "Sync Test Property",
        "property_type": "Hotel"
    })
    if response.status_code != 200:
        print(f"Property creation failed: {response.text}")
        return
    property_id = response.json()["property_id"]

    offline_uuid = str(uuid.uuid4())
    now_str = datetime.now(timezone.utc).isoformat()
    flutter_payload = {
        "uuid": offline_uuid,
        "property_id": property_id,
        "room_id": str(uuid.uuid4()),
        "guest_id": str(uuid.uuid4()),
        "guest_name": "John Doe Offline",
        "room_number": "101",
        "room_type": "Deluxe",
        "booking_type": "offline",
        "booking_source": "walk-in",
        "check_in_date": "2026-07-21",
        "check_out_date": "2026-07-23",
        "total_payable": 500.0,
        "booking_status": "confirmed",
        "payment_status": "pending",
        "last_modified_hlc": now_str
    }
    push_request = {
        "device_uid": "test_device_flutter",
        "property_id": property_id,
        "records": [
            {
                "entity_type": "Booking",
                "entity_id": offline_uuid,
                "operation": "CREATE",
                "payload": flutter_payload,
                "updated_at": now_str,
                "device_timestamp": now_str
            }
        ]
    }

    print("Pushing offline payload to /sync/push...")
    response = client.post(
        "/api/v1/sync/push",
        headers={"Authorization": f"Bearer {token}", "X-Tenant-ID": property_id},
        json=push_request
    )
    if response.status_code not in [200, 201]:
        print(f"Sync Push Failed: {response.status_code} - {response.text}")
        return
    print(f"Sync Push Response: {response.json()}")
    
    async with AsyncSessionLocal() as db:
        from sqlalchemy import select
        result = await db.execute(select(Booking).where(Booking.booking_id == uuid.UUID(offline_uuid)))
        booking = result.scalar_one_or_none()
        if booking:
            print("✅ SUCCESS: Offline Booking was successfully saved to PostgreSQL via Sync Push!")
        else:
            print("❌ FAILURE: Booking not found in database!")

asyncio.run(test_offline_sync())
