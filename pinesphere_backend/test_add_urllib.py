import urllib.request
import json

payload = {
    "owner_name": "Alice Smith",
    "business_name": "Alice Luxury Hotels",
    "property_name": "The Grand Alice"
}
data = json.dumps(payload).encode('utf-8')
req = urllib.request.Request("http://localhost:8000/api/v1/properties/", data=data, headers={'Content-Type': 'application/json'})

try:
    with urllib.request.urlopen(req) as response:
        print(f"Status Code: {response.getcode()}")
        print(f"Response: {response.read().decode('utf-8')}")
except urllib.error.HTTPError as e:
    print(f"HTTPError: {e.code}")
    print(f"Response: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
