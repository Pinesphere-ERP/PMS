import requests

def main():
    login_payload = {
        "email": "admin@pinesphere.com",
        "password": "password123",
        "device_uid": "d3b54011-e54b-448f-8244-6e4ba1ef094f"
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
