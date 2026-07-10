import sys
import os
import uuid
from datetime import datetime

# Add root to sys.path and alias src as app
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import app as app
sys.modules["app"] = app

from app.main import app as fastapi_app
from app.modules.devices.router import router as device_router

def test_device_routes_loaded():
    assert len(device_router.routes) == 18, f"Expected 18 routes, got {len(device_router.routes)}"
    route_paths = [r.path for r in device_router.routes]
    assert "/register" in route_paths
    assert "/sync-checkin" in route_paths
    assert "/{id}/activate" in route_paths
    assert "/{id}/approve" in route_paths
    assert "/{id}/revoke" in route_paths
    assert "/{id}/force-sync" in route_paths
    print("All 18 Device Management endpoints verified cleanly!")

if __name__ == "__main__":
    test_device_routes_loaded()
