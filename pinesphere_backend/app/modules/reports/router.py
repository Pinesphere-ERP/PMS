import uuid
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, Query, status, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import require_property_access, get_current_user, get_current_role
from app.infra.database import get_db
from app.infra.models import User, Role
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
    DailyReportResponse,
    MonthlyReportResponse,
    OccupancyReportResponse,
    RevenueReportResponse,
    CollectionReportResponse,
    OutstandingReportResponse,
    ExpenseCreateRequest,
    ExpenseResponse,
    ExpensesReportResponse,
    BestCustomersReportResponse,
    RoomUtilizationReportResponse,
    StaffPerformanceReportResponse,
    GlobalSummaryResponse,
    AccessMatrixResponse,
)

router = APIRouter(dependencies=[Depends(require_property_access)])

# ── Role-based helpers ─────────────────────────────────────────

FINANCIAL_ROLES = {"SUPER_ADMIN", "OWNER", "ACCOUNTANT"}
MANAGEMENT_ROLES = {"SUPER_ADMIN", "OWNER", "PROPERTY_MANAGER"}
OPERATIONAL_ROLES = {"SUPER_ADMIN", "OWNER", "PROPERTY_MANAGER", "RECEPTIONIST"}
ALL_STAFF_ROLES = {"SUPER_ADMIN", "OWNER", "PROPERTY_MANAGER", "RECEPTIONIST", "ACCOUNTANT", "HOUSEKEEPING"}

# ── Report → allowed roles mapping ─────────────────────────────

REPORT_ACCESS_MAP = {
    "daily": OPERATIONAL_ROLES,
    "monthly": FINANCIAL_ROLES | MANAGEMENT_ROLES,
    "occupancy": OPERATIONAL_ROLES,
    "revenue": FINANCIAL_ROLES,
    "collection": FINANCIAL_ROLES,
    "outstanding": FINANCIAL_ROLES,
    "expenses": FINANCIAL_ROLES,
    "best_customers": MANAGEMENT_ROLES,
    "room_utilization": OPERATIONAL_ROLES,
    "staff_performance": MANAGEMENT_ROLES,
    "pl": FINANCIAL_ROLES | MANAGEMENT_ROLES,
    "gst_returns": FINANCIAL_ROLES,
}


async def _get_role_code(user: User, db: AsyncSession) -> str:
    active_role_id = getattr(user, 'active_role_id', user.role_id)
    from sqlalchemy import select
    res = await db.execute(select(Role).where(Role.id == active_role_id))
    role = res.scalars().first()
    return role.role_code if role else "UNKNOWN"


async def _assert_roles(user: User, db: AsyncSession, allowed: set):
    code = await _get_role_code(user, db)
    if code not in allowed:
        raise HTTPException(status_code=403, detail="You do not have access to this report")


# ── KPI Snapshots (existing) ──────────────────────────────────

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


# ── P&L & GST (existing) ──────────────────────────────────────

@router.get("/pl", response_model=PLReportResponse)
async def get_profit_and_loss(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, FINANCIAL_ROLES | MANAGEMENT_ROLES)
    return await service.get_pl_report(db, property_id, start_date, end_date)


@router.get("/gst-returns", response_model=GSTReturnResponse)
async def get_gst_return_data(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, FINANCIAL_ROLES)
    return await service.get_gst_returns(db, property_id, start_date, end_date)


# ══════════════════════════════════════════════════════════════
#  NEW REPORT ENDPOINTS
# ══════════════════════════════════════════════════════════════


# ── 1. Daily Report ────────────────────────────────────────────

@router.get("/daily", response_model=DailyReportResponse)
async def get_daily_report(
    property_id: uuid.UUID = Query(...),
    report_date: date = Query(default=None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, OPERATIONAL_ROLES)
    if report_date is None:
        report_date = date.today()
    return await service.get_daily_report(db, property_id, report_date)


# ── 2. Monthly Report ─────────────────────────────────────────

@router.get("/monthly", response_model=MonthlyReportResponse)
async def get_monthly_report(
    property_id: uuid.UUID = Query(...),
    month: int = Query(..., ge=1, le=12),
    year: int = Query(..., ge=2020, le=2050),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, FINANCIAL_ROLES | MANAGEMENT_ROLES)
    return await service.get_monthly_report(db, property_id, month, year)


# ── 3. Occupancy Report ───────────────────────────────────────

@router.get("/occupancy", response_model=OccupancyReportResponse)
async def get_occupancy_report(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    room_type: Optional[str] = Query(default=None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, OPERATIONAL_ROLES)
    return await service.get_occupancy_report(db, property_id, start_date, end_date, room_type)


# ── 4. Revenue Report ─────────────────────────────────────────

@router.get("/revenue", response_model=RevenueReportResponse)
async def get_revenue_report(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, FINANCIAL_ROLES)
    return await service.get_revenue_report(db, property_id, start_date, end_date)


# ── 5. Collection Report ──────────────────────────────────────

@router.get("/collection", response_model=CollectionReportResponse)
async def get_collection_report(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, FINANCIAL_ROLES)
    return await service.get_collection_report(db, property_id, start_date, end_date)


# ── 6. Outstanding Report ─────────────────────────────────────

@router.get("/outstanding", response_model=OutstandingReportResponse)
async def get_outstanding_report(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, FINANCIAL_ROLES)
    return await service.get_outstanding_report(db, property_id, start_date, end_date)


# ── 7. Expenses Report ────────────────────────────────────────

@router.get("/expenses", response_model=ExpensesReportResponse)
async def get_expenses_report(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    category: Optional[str] = Query(default=None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, FINANCIAL_ROLES)
    return await service.get_expenses_report(db, property_id, start_date, end_date, category)


@router.post("/expenses", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
async def create_expense(
    property_id: uuid.UUID = Query(...),
    req: ExpenseCreateRequest = ...,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, FINANCIAL_ROLES | MANAGEMENT_ROLES)
    return await service.create_expense(db, property_id, user.id, req.category, req.description, req.amount, req.expense_date)


# ── 8. Best Customers Report ──────────────────────────────────

@router.get("/best-customers", response_model=BestCustomersReportResponse)
async def get_best_customers(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, MANAGEMENT_ROLES)
    return await service.get_best_customers_report(db, property_id, start_date, end_date)


# ── 9. Room Utilization Report ─────────────────────────────────

@router.get("/room-utilization", response_model=RoomUtilizationReportResponse)
async def get_room_utilization(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    room_type: Optional[str] = Query(default=None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, OPERATIONAL_ROLES)
    return await service.get_room_utilization_report(db, property_id, start_date, end_date, room_type)


# ── 10. Staff Performance Report ──────────────────────────────

@router.get("/staff-performance", response_model=StaffPerformanceReportResponse)
async def get_staff_performance(
    property_id: uuid.UUID = Query(...),
    start_date: date = Query(...),
    end_date: date = Query(...),
    staff_id: Optional[uuid.UUID] = Query(default=None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, MANAGEMENT_ROLES)
    return await service.get_staff_performance_report(db, property_id, start_date, end_date, staff_id)


# ── Access Matrix (for frontends) ─────────────────────────────

@router.get("/access-matrix", response_model=AccessMatrixResponse)
async def get_access_matrix(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    role_code = await _get_role_code(user, db)
    allowed = REPORT_ACCESS_MAP.get("_all", set())
    reports_allowed = [
        report for report, roles in REPORT_ACCESS_MAP.items()
        if role_code in roles
    ]
    return AccessMatrixResponse(
        role_code=role_code,
        reports=reports_allowed,
        can_download_all=role_code in {"SUPER_ADMIN", "OWNER"},
    )


# ── PDF Export Endpoint ───────────────────────────────────────

@router.get("/{report_type}/pdf")
async def download_report_pdf(
    report_type: str,
    property_id: uuid.UUID = Query(...),
    start_date: Optional[date] = Query(default=None),
    end_date: Optional[date] = Query(default=None),
    report_date: Optional[date] = Query(default=None),
    month: Optional[int] = Query(default=None),
    year: Optional[int] = Query(default=None),
    room_type: Optional[str] = Query(default=None),
    category: Optional[str] = Query(default=None),
    staff_id: Optional[uuid.UUID] = Query(default=None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    allowed_roles = REPORT_ACCESS_MAP.get(report_type)
    if allowed_roles is None:
        raise HTTPException(status_code=404, detail=f"Unknown report type: {report_type}")
    await _assert_roles(user, db, allowed_roles)

    from app.modules.reports.pdf_generator import generate_report_pdf
    return await generate_report_pdf(
        db=db,
        report_type=report_type,
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        report_date=report_date,
        month=month,
        year=year,
        room_type=room_type,
        category=category,
        staff_id=staff_id,
    )


# ── Global Summary (Superadmin only) ──────────────────────────

global_router = APIRouter()

@global_router.get("/reports/global-summary", response_model=GlobalSummaryResponse)
async def get_global_summary(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, {"SUPER_ADMIN"})
    return await service.get_global_summary(db)


# ── Report Templates (secured) ────────────────────────────────

TEMPLATE_ACCESS = MANAGEMENT_ROLES | FINANCIAL_ROLES

@router.post(
    "/templates",
    response_model=ReportTemplateResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_template(
    property_id: uuid.UUID = Query(...),
    req: ReportTemplateCreateRequest = ...,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, TEMPLATE_ACCESS)
    return await service.create_report_template(db, property_id, req)


@router.get("/templates", response_model=ReportTemplateListResponse)
async def list_templates(
    property_id: uuid.UUID = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, TEMPLATE_ACCESS)
    return await service.list_report_templates(db, property_id)


@router.get("/templates/{template_id}", response_model=ReportTemplateResponse)
async def get_template(
    template_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, TEMPLATE_ACCESS)
    return await service.get_report_template(db, property_id, template_id)


@router.patch("/templates/{template_id}", response_model=ReportTemplateResponse)
async def update_template(
    template_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    req: ReportTemplateUpdateRequest = ...,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, TEMPLATE_ACCESS)
    return await service.update_report_template(db, property_id, template_id, req)


@router.delete(
    "/templates/{template_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_template(
    template_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, TEMPLATE_ACCESS)
    await service.delete_report_template(db, property_id, template_id)


# ── Scheduled Reports (secured) ───────────────────────────────

SCHEDULE_ACCESS = MANAGEMENT_ROLES | FINANCIAL_ROLES

@router.post(
    "/schedules",
    response_model=ScheduledReportResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_schedule(
    property_id: uuid.UUID = Query(...),
    req: ScheduledReportCreateRequest = ...,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, SCHEDULE_ACCESS)
    return await service.create_scheduled_report(db, property_id, req)


@router.get("/schedules", response_model=ScheduledReportListResponse)
async def list_schedules(
    property_id: uuid.UUID = Query(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, SCHEDULE_ACCESS)
    return await service.list_scheduled_reports(db, property_id)


@router.patch("/schedules/{schedule_id}", response_model=ScheduledReportResponse)
async def update_schedule(
    schedule_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    req: ScheduledReportUpdateRequest = ...,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _assert_roles(user, db, SCHEDULE_ACCESS)
    return await service.update_scheduled_report(db, property_id, schedule_id, req)
