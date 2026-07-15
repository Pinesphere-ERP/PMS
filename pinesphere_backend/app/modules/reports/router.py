import uuid
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, Query, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.core.dependencies import get_current_user
from app.infra.models import User, Role

from app.infra.database import get_db
from app.modules.reports import service
from app.modules.reports.schemas import (
    DailyKPISnapshotResponse,
    PLReportResponse,
    GSTReturnResponse,
    ReportTemplateCreateRequest,
    ReportTemplateUpdateRequest,
    ReportTemplateResponse,
    ReportTemplateListResponse,
    ScheduledReportCreateRequest,
    ScheduledReportUpdateRequest,
    ScheduledReportResponse,
    ScheduledReportListResponse,
)

async def require_property_access(
    property_id: uuid.UUID = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    role_res = await db.execute(select(Role).filter(Role.id == user.active_role_id))
    role = role_res.scalars().first()
    
    if role and role.role_code == "SUPER_ADMIN":
        return
        
    if user.active_property_id != property_id:
        raise HTTPException(status_code=403, detail="Forbidden: You do not have access to this property's reports")

router = APIRouter(dependencies=[Depends(require_property_access)])


# ── KPI Snapshots ──────────────────────────────────────────────

@router.get("/kpi/today", response_model=Optional[DailyKPISnapshotResponse])
async def get_todays_kpi(
    property_id: uuid.UUID = Query(..., description="Property UUID"),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_today_kpi(db, property_id)


@router.get("/kpi/range", response_model=list[DailyKPISnapshotResponse])
async def get_kpi_date_range(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_kpi_range(db, property_id, start_date, end_date)


# ── P&L & GST ──────────────────────────────────────────────────

@router.get("/pl", response_model=PLReportResponse)
async def get_profit_and_loss(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_pl_report(db, property_id, start_date, end_date)


@router.get("/gst-returns", response_model=GSTReturnResponse)
async def get_gst_return_data(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_gst_returns(db, property_id, start_date, end_date)


# ── Report Templates ───────────────────────────────────────────

@router.post(
    "/templates",
    response_model=ReportTemplateResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_template(
    property_id: uuid.UUID = Query(...),
    req: ReportTemplateCreateRequest = ...,
    db: AsyncSession = Depends(get_db),
):
    return await service.create_report_template(db, property_id, req)


@router.get("/templates", response_model=ReportTemplateListResponse)
async def list_templates(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_report_templates(db, property_id)


@router.get("/templates/{template_id}", response_model=ReportTemplateResponse)
async def get_template(
    template_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_report_template(db, property_id, template_id)


@router.patch("/templates/{template_id}", response_model=ReportTemplateResponse)
async def update_template(
    template_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    req: ReportTemplateUpdateRequest = ...,
    db: AsyncSession = Depends(get_db),
):
    return await service.update_report_template(db, property_id, template_id, req)


@router.delete(
    "/templates/{template_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_template(
    template_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    await service.delete_report_template(db, property_id, template_id)


# ── Scheduled Reports ──────────────────────────────────────────

@router.post(
    "/schedules",
    response_model=ScheduledReportResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_schedule(
    property_id: uuid.UUID = Query(...),
    req: ScheduledReportCreateRequest = ...,
    db: AsyncSession = Depends(get_db),
):
    return await service.create_scheduled_report(db, property_id, req)


@router.get("/schedules", response_model=ScheduledReportListResponse)
async def list_schedules(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_scheduled_reports(db, property_id)


@router.patch("/schedules/{schedule_id}", response_model=ScheduledReportResponse)
async def update_schedule(
    schedule_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    req: ScheduledReportUpdateRequest = ...,
    db: AsyncSession = Depends(get_db),
):
    return await service.update_scheduled_report(db, property_id, schedule_id, req)
