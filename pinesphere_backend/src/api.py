from fastapi import APIRouter
from app.modules.auth import router as auth
from app.modules.sync import router as sync
from app.modules.properties import router as property
from app.modules.subscriptions import router as subscription
from app.modules.devices import router as device

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(sync.router, prefix="/sync", tags=["Sync Engine"])
api_router.include_router(property.router, prefix="/properties", tags=["Property Management"])
api_router.include_router(subscription.router, prefix="/subscriptions", tags=["Subscription Management"])
api_router.include_router(device.router, prefix="/devices", tags=["Device Management"])
