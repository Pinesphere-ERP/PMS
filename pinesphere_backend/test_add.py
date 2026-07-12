import requests
import json

payload = {
    "owner_name": "Alice Smith",
    "business_name": "Alice Luxury Hotels",
    "property_name": "The Grand Alice"
}

try:
    response = requests.post("http://localhost:8000/api/v1/properties/", json=payload)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"Error: {e}")
