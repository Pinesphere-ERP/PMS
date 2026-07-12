from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Any
import uuid

from app.infra.database import get_db
from app.core.dependencies import get_current_user
from app.infra.models import User
from .schemas import AuditLogListResponse, AuditLogResponse
from .service import AuditService

router = APIRouter()

def get_audit_service(db: AsyncSession = Depends(get_db)) -> AuditService:
    return AuditService(db)

@router.get("/", response_model=AuditLogListResponse)
async def list_audit_logs(
    property_id: uuid.UUID = None,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    service: AuditService = Depends(get_audit_service),
    # Require authentication (in real app, use require_permission("AUDIT_LOGS"))
    current_user: User = Depends(get_current_user)
) -> Any:
    skip = (page - 1) * size
    logs, total = await service.list_audit_logs(property_id=property_id, skip=skip, limit=size)
    
    return {
        "items": logs,
        "total": total,
        "page": page,
        "size": size
    }
import uuid
from typing import Optional
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.modules.audit import service
from app.modules.audit.schemas import (
    AuditLogResponse,
    AuditLogListResponse,
    ChainVerificationResult,
)

router = APIRouter()


@router.get("/", response_model=AuditLogListResponse)
async def list_audit_logs(
    property_id: Optional[uuid.UUID] = Query(None),
    module_name: Optional[str] = Query(None),
    action_type: Optional[str] = Query(None),
    target_entity: Optional[str] = Query(None),
    target_record_id: Optional[uuid.UUID] = Query(None),
    user_id: Optional[uuid.UUID] = Query(None),
    since: Optional[datetime] = Query(None),
    until: Optional[datetime] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
):
    logs, total = await service.query_logs(
        db,
        property_id=property_id,
        module_name=module_name,
        action_type=action_type,
        target_entity=target_entity,
        target_record_id=target_record_id,
        user_id=user_id,
        since=since,
        until=until,
        skip=skip,
        limit=limit,
    )
    return AuditLogListResponse(
        items=[AuditLogResponse.model_validate(l) for l in logs],
        total=total,
    )


@router.get("/verify", response_model=ChainVerificationResult)
async def verify_hash_chain(
    property_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    result = await service.verify_chain(db, property_id=property_id)
    return ChainVerificationResult(**result)
