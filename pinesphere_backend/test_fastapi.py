import json
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

payload = {
    "owner_name": "Alice Smith",
    "business_name": "Alice Luxury Hotels",
    "property_name": "The Grand Alice"
}

response = client.post("/api/v1/properties", json=payload)
print(f"Status Code: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")
