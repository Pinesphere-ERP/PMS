import urllib.request
import json
import ssl

url = "https://ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/sql"
headers = {
    "Content-Type": "application/json",
    "Neon-Connection-String": "postgresql://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require"
}
data = json.dumps({
    "query": "ALTER TABLE role_permissions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW();"
}).encode("utf-8")

ctx = ssl.create_default_context()
req = urllib.request.Request(url, data=data, headers=headers, method="POST")

try:
    with urllib.request.urlopen(req, context=ctx) as response:
        print("Status:", response.status)
        print(response.read().decode("utf-8"))
except Exception as e:
    print(f"Error: {e}")
