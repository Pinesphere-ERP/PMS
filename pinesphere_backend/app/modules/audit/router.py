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
