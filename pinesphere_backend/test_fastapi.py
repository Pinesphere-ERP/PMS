from dotenv import load_dotenv
load_dotenv()
from fastapi.testclient import TestClient
from app.main import app
client = TestClient(app)
try:
  response = client.get('/api/v1/payments/?page=1&size=20')
  print(response.status_code, response.text)
except Exception as e:
  import traceback
  traceback.print_exc()