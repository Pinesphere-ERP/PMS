import asyncio
import httpx
import uuid
import datetime

API_URL = "http://localhost:8000/api/v1"

async def run_e2e_test():
    print("🚀 Starting E2E Workflow Test...")
    
    # 1. We assume the FastAPI server is running on localhost:8000.
    async with httpx.AsyncClient(base_url=API_URL, timeout=10.0) as client:
        
        # Test 1: Create a property
        print("1️⃣ Testing Property Creation...")
        prop_payload = {
            "name": "Pinesphere Test Resort",
            "address": "123 Test Lane",
            "city": "Testville",
            "state": "TS",
            "country": "Testland",
            "zip_code": "12345",
            "email": "contact@testresort.com",
            "phone": "+1234567890",
            "property_type": "resort",
            "currency": "USD",
            "timezone": "UTC"
        }
        resp = await client.post("/properties", json=prop_payload)
        
        # If the property creation fails, we might be hitting an unmounted route or DB issue
        if resp.status_code not in [200, 201]:
            print(f"❌ Property Creation Failed: {resp.status_code} {resp.text}")
            # We don't exit here, we might just be using a stub API.
            property_id = str(uuid.uuid4())
        else:
            print("✅ Property Created Successfully")
            property_id = resp.json().get("property_id")

        # Test 2: Auth Bootstrap & Login
        print("2️⃣ Testing Auth Engine...")
        device_uid = f"device-{uuid.uuid4()}"
        resp = await client.post("/auth/offline-bootstrap", json={
            "device_uid": device_uid,
            "user_id": str(uuid.uuid4())
        })
        if resp.status_code == 200:
            print("✅ Auth Bootstrap Successful")
        else:
            print(f"❌ Auth Bootstrap Failed: {resp.status_code} {resp.text}")

        # Note: We won't test full login right now because we need a real seeded user in DB.
        
        # Test 3: Guest & Booking Creation
        print("3️⃣ Testing Guest & Booking Creation...")
        guest_payload = {
            "property_id": property_id,
            "full_name": "Test Guest",
            "mobile": f"+1999{uuid.uuid4().hex[:7]}",
            "email": "guest@test.com",
            "id_type": "passport",
            "id_number": "A12345678"
        }
        resp = await client.post("/bookings/guests", json=guest_payload)
        if resp.status_code in [200, 201]:
            print("✅ Guest Created Successfully")
            guest_id = resp.json().get("guest_id")
        else:
            print(f"❌ Guest Creation Failed: {resp.status_code} {resp.text}")
            guest_id = str(uuid.uuid4())

        # Test 4: Sync Engine
        print("4️⃣ Testing Sync Engine...")
        sync_payload = {
            "device_uid": device_uid,
            "property_id": property_id,
            "records": [
                {
                    "entity_type": "Guest",
                    "entity_id": guest_id,
                    "operation": "CREATE",
                    "payload": guest_payload,
                    "updated_at": datetime.datetime.utcnow().isoformat(),
                    "device_timestamp": datetime.datetime.utcnow().isoformat()
                }
            ]
        }
        resp = await client.post("/sync/push", json=sync_payload)
        if resp.status_code == 200:
            print("✅ Sync Push Successful")
        else:
            print(f"❌ Sync Push Failed: {resp.status_code} {resp.text}")

        # Test 5: Audit Logs
        print("5️⃣ Testing Audit Logs...")
        resp = await client.get(f"/audit?property_id={property_id}")
        if resp.status_code == 200:
            print("✅ Audit Logs Retrieved Successfully")
            print(f"   Found {resp.json().get('total', 0)} logs.")
        else:
            print(f"❌ Audit Logs Retrieval Failed: {resp.status_code} {resp.text}")

        print("🎉 E2E Workflow Test Complete!")

if __name__ == "__main__":
    asyncio.run(run_e2e_test())
