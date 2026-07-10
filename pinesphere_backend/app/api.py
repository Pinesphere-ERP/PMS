from fastapi import APIRouter
from app.modules.auth import router as auth
from app.modules.sync import router as sync
from app.modules.properties import router as property
from app.modules.subscriptions import router as subscription

api_router = APIRouter()
api_router.include_router(auth, prefix="/auth", tags=["Authentication"])
api_router.include_router(sync, prefix="/sync", tags=["Sync Engine"])
api_router.include_router(property, prefix="/properties", tags=["Property Management"])
api_router.include_router(subscription, prefix="/subscriptions", tags=["Subscription Management"])
