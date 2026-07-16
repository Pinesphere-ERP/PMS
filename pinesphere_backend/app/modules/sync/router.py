from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Any

from app.infra.database import get_db
from app.core.dependencies import assert_property_access, get_current_user
from app.infra.models import User
from .schemas import SyncPushRequest, SyncPushResponse, SyncPullRequest, SyncPullResponse
from .service import SyncService

router = APIRouter()

def get_sync_service(db: AsyncSession = Depends(get_db)) -> SyncService:
    return SyncService(db)

@router.post("/push", response_model=SyncPushResponse)
async def push(
    request: SyncPushRequest,
    service: SyncService = Depends(get_sync_service),
    current_user: User = Depends(get_current_user)
) -> Any:
    await assert_property_access(request.property_id, current_user, service.db)
    return await service.push(request)

@router.post("/pull", response_model=SyncPullResponse)
async def pull(
    request: SyncPullRequest,
    service: SyncService = Depends(get_sync_service),
    current_user: User = Depends(get_current_user)
) -> Any:
    await assert_property_access(request.property_id, current_user, service.db)
    return await service.pull(request)
