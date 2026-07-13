import asyncio
import sys
import os

# Add pinesphere_backend to sys.path so we can import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from app.main import app

def main():
    client = TestClient(app)
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "admin@pinesphere.com",
            "password": "password123",
            "device_uid": "d3b54011-e54b-448f-8244-6e4ba1ef094f"
        }
    )
    print("Status Code:", response.status_code)
    print("Response JSON:", response.text)

if __name__ == "__main__":
    main()
