from fastapi import APIRouter
from src.api.v1.endpoints import auth, sync

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(sync.router, prefix="/sync", tags=["Sync Engine"])
