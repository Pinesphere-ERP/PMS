from fastapi import APIRouter
from src.api.v1.endpoints import auth, sync, property, subscription

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(sync.router, prefix="/sync", tags=["Sync Engine"])
api_router.include_router(property.router, prefix="/properties", tags=["Property Management"])
api_router.include_router(subscription.router, prefix="/subscriptions", tags=["Subscription Management"])
