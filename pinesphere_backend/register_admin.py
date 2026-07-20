import requests

url = "https://pms-bvko.onrender.com/api/v1/onboarding/register"
payload = {
  "owner_name": "Admin User",
  "email": "admin@pinesphere.com",
  "mobile_number": "1234567890",
  "password": "password123",
  "business_name": "Pinesphere Admin Business",
  "property_name": "Pinesphere Admin Property",
  "property_type": "HOTEL",
  "star_category": 5
}

response = requests.post(url, json=payload)
print(response.status_code)
print(response.text)
