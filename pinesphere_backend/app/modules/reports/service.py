import uuid
from datetime import date
from typing import Optional, List, Dict, Any
from calendar import month_name
from decimal import Decimal
from collections import defaultdict

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, extract, desc
from fastapi import HTTPException

from app.infra.models import (
    DailyKPISnapshot, ReportTemplate, ScheduledReport,
    Booking, Payment, CheckOut,
)
from app.modules.reports.schemas import (
    DailyKPISnapshotResponse,
    PLReportResponse, MonthlyPLRow,
    GSTReturnResponse,
    ReportTemplateCreateRequest, ReportTemplateUpdateRequest,
    ReportTemplateResponse, ReportTemplateListResponse,
    ScheduledReportCreateRequest, ScheduledReportUpdateRequest,
    ScheduledReportResponse, ScheduledReportListResponse,
)


# ── KPI Snapshots ──────────────────────────────────────────────

async def get_today_kpi(
    db: AsyncSession, property_id: uuid.UUID
) -> Optional[DailyKPISnapshotResponse]:
    today = date.today()
    stmt = select(DailyKPISnapshot).where(
        DailyKPISnapshot.property_id == property_id,
        DailyKPISnapshot.snapshot_date == today,
    )
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if entity is None:
        return None
    return DailyKPISnapshotResponse.model_validate(entity)


async def get_kpi_range(
    db: AsyncSession,
    property_id: uuid.UUID,
    start_date: date,
    end_date: date,
) -> List[DailyKPISnapshotResponse]:
    stmt = (
        select(DailyKPISnapshot)
        .where(
            DailyKPISnapshot.property_id == property_id,
            DailyKPISnapshot.snapshot_date >= start_date,
            DailyKPISnapshot.snapshot_date <= end_date,
        )
        .order_by(DailyKPISnapshot.snapshot_date)
    )
    result = await db.execute(stmt)
    return [DailyKPISnapshotResponse.model_validate(r) for r in result.scalars().all()]


# ── Multi-Month P&L ────────────────────────────────────────────

async def get_pl_report(
    db: AsyncSession,
    property_id: uuid.UUID,
    start_date: date,
    end_date: date,
) -> PLReportResponse:
    stmt = (
        select(DailyKPISnapshot)
        .where(
            DailyKPISnapshot.property_id == property_id,
            DailyKPISnapshot.snapshot_date >= start_date,
            DailyKPISnapshot.snapshot_date <= end_date,
        )
        .order_by(DailyKPISnapshot.snapshot_date)
    )
    result = await db.execute(stmt)
    rows = result.scalars().all()

    monthly: Dict[str, Dict[str, float]] = defaultdict(
        lambda: {
            "room_rent": 0, "addons": 0, "revenue": 0,
            "expenses": 0, "gst": 0, "outstanding": 0,
        }
    )

    for row in rows:
        key = row.snapshot_date.strftime("%Y-%m")
        monthly[key]["room_rent"] += float(row.revenue_room_rent)
        monthly[key]["addons"] += float(row.revenue_addons)
        monthly[key]["revenue"] += float(row.revenue_room_rent) + float(row.revenue_addons)
        monthly[key]["expenses"] += float(row.expenses_amount)
        monthly[key]["gst"] += float(row.gst_collected)
        monthly[key]["outstanding"] += float(row.outstanding_payments)

    breakdown: List[MonthlyPLRow] = []
    total_rev = total_exp = total_np = total_gst = total_out = 0.0

    for key in sorted(monthly.keys()):
        d = monthly[key]
        net = d["revenue"] - d["expenses"]
        yr, mo = key.split("-")
        label = f"{month_name[int(mo)]} {yr}"
        breakdown.append(MonthlyPLRow(
            month=label,
            total_room_rent=round(d["room_rent"], 2),
            total_addons=round(d["addons"], 2),
            total_revenue=round(d["revenue"], 2),
            total_expenses=round(d["expenses"], 2),
            net_profit=round(net, 2),
            gst_collected=round(d["gst"], 2),
            outstanding=round(d["outstanding"], 2),
        ))
        total_rev += d["revenue"]
        total_exp += d["expenses"]
        total_np += net
        total_gst += d["gst"]
        total_out += d["outstanding"]

    return PLReportResponse(
        property_id=property_id,
        period_start=start_date,
        period_end=end_date,
        monthly_breakdown=breakdown,
        summary_total_revenue=round(total_rev, 2),
        summary_total_expenses=round(total_exp, 2),
        summary_net_profit=round(total_np, 2),
    )


# ── GST Returns ────────────────────────────────────────────────

async def get_gst_returns(
    db: AsyncSession,
    property_id: uuid.UUID,
    start_date: date,
    end_date: date,
) -> GSTReturnResponse:
    stmt = (
        select(DailyKPISnapshot)
        .where(
            DailyKPISnapshot.property_id == property_id,
            DailyKPISnapshot.snapshot_date >= start_date,
            DailyKPISnapshot.snapshot_date <= end_date,
        )
        .order_by(DailyKPISnapshot.snapshot_date)
    )
    result = await db.execute(stmt)
    rows = result.scalars().all()

    total_revenue = Decimal("0")
    total_gst = Decimal("0")
    monthly_gst: List[Dict[str, Any]] = []

    monthly_agg: Dict[str, Decimal] = defaultdict(lambda: Decimal("0"))

    for row in rows:
        rev = Decimal(str(row.revenue_room_rent)) + Decimal(str(row.revenue_addons))
        gst = Decimal(str(row.gst_collected))
        total_revenue += rev
        total_gst += gst
        key = row.snapshot_date.strftime("%Y-%m")
        monthly_agg[key] += gst

    for key in sorted(monthly_agg.keys()):
        yr, mo = key.split("-")
        monthly_gst.append({
            "month": f"{month_name[int(mo)]} {yr}",
            "gst_collected": float(monthly_agg[key]),
        })

    cgst = total_gst / 2
    sgst = total_gst / 2
    igst = Decimal("0")

    return GSTReturnResponse(
        property_id=property_id,
        period_start=start_date,
        period_end=end_date,
        total_taxable_revenue=float(total_revenue),
        total_gst_collected=float(total_gst),
        cgst=float(cgst),
        sgst=float(sgst),
        igst=float(igst),
        monthly_gst=monthly_gst,
    )


# ── Report Templates ───────────────────────────────────────────

async def create_report_template(
    db: AsyncSession,
    property_id: uuid.UUID,
    req: ReportTemplateCreateRequest,
) -> ReportTemplateResponse:
    template = ReportTemplate(
        property_id=property_id,
        report_name=req.report_name,
        report_type=req.report_type,
        configuration_json=req.configuration_json,
    )
    db.add(template)
    await db.flush()
    await db.refresh(template)
    return ReportTemplateResponse.model_validate(template)


async def list_report_templates(
    db: AsyncSession, property_id: uuid.UUID
) -> ReportTemplateListResponse:
    stmt = (
        select(ReportTemplate)
        .where(ReportTemplate.property_id == property_id)
        .order_by(ReportTemplate.created_at.desc())
    )
    result = await db.execute(stmt)
    items = [ReportTemplateResponse.model_validate(r) for r in result.scalars().all()]
    return ReportTemplateListResponse(items=items, total=len(items))


async def get_report_template(
    db: AsyncSession, property_id: uuid.UUID, template_id: uuid.UUID
) -> ReportTemplateResponse:
    stmt = select(ReportTemplate).where(
        ReportTemplate.template_id == template_id,
        ReportTemplate.property_id == property_id,
    )
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Report template not found")
    return ReportTemplateResponse.model_validate(entity)


async def update_report_template(
    db: AsyncSession,
    property_id: uuid.UUID,
    template_id: uuid.UUID,
    req: ReportTemplateUpdateRequest,
) -> ReportTemplateResponse:
    stmt = select(ReportTemplate).where(
        ReportTemplate.template_id == template_id,
        ReportTemplate.property_id == property_id,
    )
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Report template not found")

    if req.report_name is not None:
        entity.report_name = req.report_name
    if req.report_type is not None:
        entity.report_type = req.report_type
    if req.configuration_json is not None:
        entity.configuration_json = req.configuration_json

    await db.flush()
    await db.refresh(entity)
    return ReportTemplateResponse.model_validate(entity)


async def delete_report_template(
    db: AsyncSession, property_id: uuid.UUID, template_id: uuid.UUID
) -> None:
    stmt = select(ReportTemplate).where(
        ReportTemplate.template_id == template_id,
        ReportTemplate.property_id == property_id,
    )
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Report template not found")
    await db.delete(entity)
    await db.flush()


# ── Scheduled Reports ──────────────────────────────────────────

async def create_scheduled_report(
    db: AsyncSession,
    property_id: uuid.UUID,
    req: ScheduledReportCreateRequest,
) -> ScheduledReportResponse:
    tpl_stmt = select(ReportTemplate).where(
        ReportTemplate.template_id == req.template_id,
        ReportTemplate.property_id == property_id,
    )
    tpl_result = await db.execute(tpl_stmt)
    if not tpl_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Report template not found for this property")

    schedule = ScheduledReport(
        template_id=req.template_id,
        recipient_role=req.recipient_role,
        delivery_channel=req.delivery_channel,
        frequency=req.frequency,
        is_active=req.is_active,
    )
    db.add(schedule)
    await db.flush()
    await db.refresh(schedule)
    return ScheduledReportResponse.model_validate(schedule)


async def list_scheduled_reports(
    db: AsyncSession, property_id: uuid.UUID
) -> ScheduledReportListResponse:
    tpl_ids_stmt = select(ReportTemplate.template_id).where(
        ReportTemplate.property_id == property_id
    )
    tpl_result = await db.execute(tpl_ids_stmt)
    template_ids = [row[0] for row in tpl_result.all()]

    if not template_ids:
        return ScheduledReportListResponse(items=[], total=0)

    stmt = (
        select(ScheduledReport)
        .where(ScheduledReport.template_id.in_(template_ids))
        .order_by(ScheduledReport.created_at.desc())
    )
    result = await db.execute(stmt)
    items = [ScheduledReportResponse.model_validate(r) for r in result.scalars().all()]
    return ScheduledReportListResponse(items=items, total=len(items))


async def update_scheduled_report(
    db: AsyncSession,
    property_id: uuid.UUID,
    schedule_id: uuid.UUID,
    req: ScheduledReportUpdateRequest,
) -> ScheduledReportResponse:
    tpl_ids_stmt = select(ReportTemplate.template_id).where(
        ReportTemplate.property_id == property_id
    )
    tpl_result = await db.execute(tpl_ids_stmt)
    template_ids = [row[0] for row in tpl_result.all()]

    stmt = select(ScheduledReport).where(
        ScheduledReport.schedule_id == schedule_id,
        ScheduledReport.template_id.in_(template_ids) if template_ids else False,
    )
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Scheduled report not found")

    if req.recipient_role is not None:
        entity.recipient_role = req.recipient_role
    if req.delivery_channel is not None:
        entity.delivery_channel = req.delivery_channel
    if req.frequency is not None:
        entity.frequency = req.frequency
    if req.is_active is not None:
        entity.is_active = req.is_active

    await db.flush()
    await db.refresh(entity)
    return ScheduledReportResponse.model_validate(entity)
