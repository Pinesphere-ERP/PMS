import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone

from app.infra.database import get_db
from app.infra.models import ServiceRequest, User
from app.core.dependencies import get_current_user
from app.modules.service_requests.schemas import (
    ServiceRequestCreate,
    ServiceRequestResponse,
    ServiceRequestAssign,
    ServiceRequestComplete,
    ServiceRequestVerify
)
from app.modules.properties.dependencies import assert_property_access
from app.core.responses import success_response, StandardResponse

router = APIRouter()

@router.post("/", response_model=StandardResponse, status_code=201)
async def create_service_request(
    request_data: ServiceRequestCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Enforce property access
    await assert_property_access(db, current_user, request_data.property_id)
    
    new_request = ServiceRequest(**request_data.model_dump())
    db.add(new_request)
    await db.commit()
    await db.refresh(new_request)
    return success_response(data=new_request, message="Service request created successfully")

@router.get("/", response_model=StandardResponse)
async def list_service_requests(
    property_id: uuid.UUID,
    status: Optional[str] = None,
    assigned_to: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    await assert_property_access(db, current_user, property_id)
    
    query = select(ServiceRequest).where(ServiceRequest.property_id == property_id)
    
    if status:
        query = query.where(ServiceRequest.status == status)
    if assigned_to:
        query = query.where(ServiceRequest.assigned_to == assigned_to)
        
    result = await db.execute(query)
    requests = result.scalars().all()
    return success_response(data=requests)

@router.patch("/{request_id}/assign", response_model=StandardResponse)
async def assign_service_request(
    request_id: uuid.UUID,
    assign_data: ServiceRequestAssign,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Only managers should be able to do this ideally, but we'll enforce property access at minimum
    query = select(ServiceRequest).where(ServiceRequest.request_id == request_id)
    result = await db.execute(query)
    service_request = result.scalar_one_or_none()
    
    if not service_request:
        raise HTTPException(status_code=404, detail="Service request not found")
        
    await assert_property_access(db, current_user, service_request.property_id)
    
    service_request.assigned_to = assign_data.assigned_to
    service_request.assigned_at = datetime.now(timezone.utc)
    service_request.status = "assigned"
    
    await db.commit()
    await db.refresh(service_request)
    return success_response(data=service_request, message="Service request assigned successfully")

@router.patch("/{request_id}/complete", response_model=StandardResponse)
async def complete_service_request(
    request_id: uuid.UUID,
    complete_data: ServiceRequestComplete,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(ServiceRequest).where(ServiceRequest.request_id == request_id)
    result = await db.execute(query)
    service_request = result.scalar_one_or_none()
    
    if not service_request:
        raise HTTPException(status_code=404, detail="Service request not found")
        
    await assert_property_access(db, current_user, service_request.property_id)
    
    service_request.status = "completed"
    service_request.completed_by = current_user.id
    service_request.completed_at = datetime.now(timezone.utc)
    
    if complete_data.completion_photo_url:
        service_request.completion_photo_url = complete_data.completion_photo_url
    if complete_data.remarks:
        service_request.remarks = complete_data.remarks
        
    await db.commit()
    await db.refresh(service_request)
    return success_response(data=service_request, message="Service request completed")

@router.patch("/{request_id}/verify", response_model=StandardResponse)
async def verify_service_request(
    request_id: uuid.UUID,
    verify_data: ServiceRequestVerify,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(ServiceRequest).where(ServiceRequest.request_id == request_id)
    result = await db.execute(query)
    service_request = result.scalar_one_or_none()
    
    if not service_request:
        raise HTTPException(status_code=404, detail="Service request not found")
        
    await assert_property_access(db, current_user, service_request.property_id)
    
    service_request.status = "verified"
    service_request.manager_verified = verify_data.manager_verified
    service_request.verified_by = current_user.id
    service_request.verified_at = datetime.now(timezone.utc)
    
    if verify_data.remarks:
        service_request.remarks = f"{service_request.remarks or ''} | Mgr: {verify_data.remarks}"
        
    await db.commit()
    await db.refresh(service_request)
    return success_response(data=service_request, message="Service request verified")
