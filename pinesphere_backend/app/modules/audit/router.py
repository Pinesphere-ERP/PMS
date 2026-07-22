import uuid
from typing import Optional
from datetime import datetime

from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Any

from app.infra.database import get_db
from app.core.dependencies import assert_property_access, get_current_role, get_current_user
from app.infra.models import User
from app.modules.audit import service
from app.modules.audit.schemas import AuditLogResponse, ChainVerificationResult
from app.core.responses import success_response, StandardResponse, Pagination

router = APIRouter()

@router.get("", response_model=StandardResponse)
async def list_audit_logs(
    property_id: Optional[uuid.UUID] = Query(None),
    module_name: Optional[str] = Query(None),
    action_type: Optional[str] = Query(None),
    target_entity: Optional[str] = Query(None),
    target_record_id: Optional[uuid.UUID] = Query(None),
    user_id: Optional[uuid.UUID] = Query(None),
    since: Optional[datetime] = Query(None),
    until: Optional[datetime] = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Any:
    if property_id is None:
        property_id = current_user.property_id
    if property_id is None and (await get_current_role(current_user, db)).role_code != "SUPER_ADMIN":
        raise HTTPException(status_code=403, detail="Property scope required")
    if property_id is not None:
        await assert_property_access(property_id, current_user, db)

    skip = (page - 1) * size
    limit = size

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
    
    pages = (total + size - 1) // size
    return success_response(
        data=[AuditLogResponse.model_validate(l).model_dump() for l in logs],
        pagination=Pagination(total=total, page=page, size=size, pages=pages)
    )


@router.get("/verify", response_model=StandardResponse)
async def verify_hash_chain(
    property_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    result = await service.verify_chain(db, property_id=property_id)
    return success_response(data=result)
