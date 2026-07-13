import requests

def main():
    login_payload = {
        "email": "admin@pinesphere.com",
        "password": "password123",
        "device_id": "a92c42d31221b34a",
        "device_name": "Linux",
        "device_fingerprint": "a92c42d31221b34a"
    }
    resp = requests.post("https://pms-bvko.onrender.com/api/v1/auth/login", json=login_payload)
    if resp.status_code != 200:
        print("Login failed:", resp.text)
        return
    token = resp.json().get("access_token")
    
    bootstrap_resp = requests.post(
        "https://pms-bvko.onrender.com/api/v1/auth/offline-bootstrap",
        headers={"Authorization": f"Bearer {token}"}
    )
    print("Bootstrap Status:", bootstrap_resp.status_code)
    print("Bootstrap Response:", bootstrap_resp.text)

if __name__ == "__main__":
    main()
