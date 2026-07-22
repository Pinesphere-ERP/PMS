import uuid
from datetime import date, timedelta
from typing import Optional, List, Dict, Any
from calendar import month_name, monthrange
from decimal import Decimal
from collections import defaultdict

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, extract, desc, case, cast, Date
from sqlalchemy.sql import label
from fastapi import HTTPException

from app.modules.reports.models import DailyKPISnapshot, ReportTemplate, ScheduledReport
from app.infra.models import (
    Booking, Payment, CheckIn, CheckOut, Room, RoomCategory,
    HousekeepingTask, Guest, Invoice, Task, User, Role,
    Property, Expense, SplitPayment,
)
from app.modules.reports.schemas import (
    DailyKPISnapshotResponse,
    PLReportResponse, MonthlyPLRow,
    GSTReturnResponse,
    ReportTemplateCreateRequest, ReportTemplateUpdateRequest,
    ReportTemplateResponse, ReportTemplateListResponse,
    ScheduledReportCreateRequest, ScheduledReportUpdateRequest,
    ScheduledReportResponse, ScheduledReportListResponse,
    DailyReportResponse,
    MonthlyReportResponse,
    OccupancyReportResponse,
    RevenueReportResponse,
    CollectionReportResponse,
    OutstandingReportResponse,
    ExpensesReportResponse, ExpenseResponse,
    BestCustomersReportResponse, BestCustomerRow,
    RoomUtilizationReportResponse, RoomUtilizationRow,
    StaffPerformanceReportResponse, StaffPerformanceRow,
    GlobalSummaryResponse, PropertySummaryRow,
)


# ══════════════════════════════════════════════════════════════════
#  EXISTING: KPI Snapshots
# ══════════════════════════════════════════════════════════════════

async def update_daily_kpi_snapshot(
    db: AsyncSession, property_id: uuid.UUID, target_date: date
) -> None:
    occupied = await db.scalar(select(func.count(Room.room_id)).where(Room.property_id == property_id, func.lower(Room.occupancy_status) == 'occupied'))
    vacant = await db.scalar(select(func.count(Room.room_id)).where(Room.property_id == property_id, func.lower(Room.occupancy_status) == 'vacant'))

    payments = await db.execute(select(Payment).join(Booking).where(
        Booking.property_id == property_id,
        func.date(Payment.created_at) == target_date,
        Payment.status == 'Completed'
    ))
    payments = payments.scalars().all()
    revenue_room_rent = sum((p.amount for p in payments if p.payment_mode != 'Addon'), Decimal('0.0'))
    revenue_addons = sum((p.amount for p in payments if p.payment_mode == 'Addon'), Decimal('0.0'))

    outstanding = await db.scalar(select(func.coalesce(func.sum(Booking.pending_amount), Decimal('0.0'))).where(
        Booking.property_id == property_id,
        Booking.payment_status.in_(['Pending', 'Partial']),
        Booking.booking_status != 'cancelled'
    ))
    gst_collected = (revenue_room_rent + revenue_addons) * Decimal('0.18')

    stmt = select(DailyKPISnapshot).where(
        DailyKPISnapshot.property_id == property_id,
        DailyKPISnapshot.snapshot_date == target_date
    )
    result = await db.execute(stmt)
    snapshot = result.scalar_one_or_none()

    if snapshot:
        snapshot.occupied_rooms = occupied or 0
        snapshot.vacant_rooms = vacant or 0
        snapshot.revenue_room_rent = float(revenue_room_rent)
        snapshot.revenue_addons = float(revenue_addons)
        snapshot.outstanding_payments = float(outstanding or 0.0)
        snapshot.gst_collected = float(gst_collected)
    else:
        snapshot = DailyKPISnapshot(
            property_id=property_id,
            snapshot_date=target_date,
            occupied_rooms=occupied or 0,
            vacant_rooms=vacant or 0,
            revenue_room_rent=float(revenue_room_rent),
            revenue_addons=float(revenue_addons),
            outstanding_payments=float(outstanding or 0.0),
            gst_collected=float(gst_collected),
        )
        db.add(snapshot)

    await db.flush()


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


# ══════════════════════════════════════════════════════════════════
#  EXISTING: P&L Report
# ══════════════════════════════════════════════════════════════════

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
        label_ = f"{month_name[int(mo)]} {yr}"
        breakdown.append(MonthlyPLRow(
            month=label_,
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


# ══════════════════════════════════════════════════════════════════
#  EXISTING: GST Returns
# ══════════════════════════════════════════════════════════════════

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


# ══════════════════════════════════════════════════════════════════
#  EXISTING: Report Templates
# ══════════════════════════════════════════════════════════════════

async def create_report_template(db, property_id, req):
    template = ReportTemplate(property_id=property_id, report_name=req.report_name, report_type=req.report_type, configuration_json=req.configuration_json)
    db.add(template)
    await db.flush()
    await db.refresh(template)
    return ReportTemplateResponse.model_validate(template)

async def list_report_templates(db, property_id):
    stmt = select(ReportTemplate).where(ReportTemplate.property_id == property_id).order_by(ReportTemplate.created_at.desc())
    result = await db.execute(stmt)
    items = [ReportTemplateResponse.model_validate(r) for r in result.scalars().all()]
    return ReportTemplateListResponse(items=items, total=len(items))

async def get_report_template(db, property_id, template_id):
    stmt = select(ReportTemplate).where(ReportTemplate.template_id == template_id, ReportTemplate.property_id == property_id)
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Report template not found")
    return ReportTemplateResponse.model_validate(entity)

async def update_report_template(db, property_id, template_id, req):
    stmt = select(ReportTemplate).where(ReportTemplate.template_id == template_id, ReportTemplate.property_id == property_id)
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Report template not found")
    if req.report_name is not None: entity.report_name = req.report_name
    if req.report_type is not None: entity.report_type = req.report_type
    if req.configuration_json is not None: entity.configuration_json = req.configuration_json
    await db.flush()
    await db.refresh(entity)
    return ReportTemplateResponse.model_validate(entity)

async def delete_report_template(db, property_id, template_id):
    stmt = select(ReportTemplate).where(ReportTemplate.template_id == template_id, ReportTemplate.property_id == property_id)
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Report template not found")
    await db.delete(entity)
    await db.flush()


# ══════════════════════════════════════════════════════════════════
#  EXISTING: Scheduled Reports
# ══════════════════════════════════════════════════════════════════

async def create_scheduled_report(db, property_id, req):
    tpl_stmt = select(ReportTemplate).where(ReportTemplate.template_id == req.template_id, ReportTemplate.property_id == property_id)
    tpl_result = await db.execute(tpl_stmt)
    if not tpl_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Report template not found for this property")
    schedule = ScheduledReport(template_id=req.template_id, recipient_role=req.recipient_role, delivery_channel=req.delivery_channel, frequency=req.frequency, is_active=req.is_active)
    db.add(schedule)
    await db.flush()
    await db.refresh(schedule)
    return ScheduledReportResponse.model_validate(schedule)

async def list_scheduled_reports(db, property_id):
    tpl_ids_stmt = select(ReportTemplate.template_id).where(ReportTemplate.property_id == property_id)
    tpl_result = await db.execute(tpl_ids_stmt)
    template_ids = [row[0] for row in tpl_result.all()]
    if not template_ids:
        return ScheduledReportListResponse(items=[], total=0)
    stmt = select(ScheduledReport).where(ScheduledReport.template_id.in_(template_ids)).order_by(ScheduledReport.created_at.desc())
    result = await db.execute(stmt)
    items = [ScheduledReportResponse.model_validate(r) for r in result.scalars().all()]
    return ScheduledReportListResponse(items=items, total=len(items))

async def update_scheduled_report(db, property_id, schedule_id, req):
    tpl_ids_stmt = select(ReportTemplate.template_id).where(ReportTemplate.property_id == property_id)
    tpl_result = await db.execute(tpl_ids_stmt)
    template_ids = [row[0] for row in tpl_result.all()]
    stmt = select(ScheduledReport).where(ScheduledReport.schedule_id == schedule_id, ScheduledReport.template_id.in_(template_ids) if template_ids else False)
    result = await db.execute(stmt)
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Scheduled report not found")
    if req.recipient_role is not None: entity.recipient_role = req.recipient_role
    if req.delivery_channel is not None: entity.delivery_channel = req.delivery_channel
    if req.frequency is not None: entity.frequency = req.frequency
    if req.is_active is not None: entity.is_active = req.is_active
    await db.flush()
    await db.refresh(entity)
    return ScheduledReportResponse.model_validate(entity)


# ══════════════════════════════════════════════════════════════════
#  NEW: 1. Daily Report
# ══════════════════════════════════════════════════════════════════

async def get_daily_report(
    db: AsyncSession, property_id: uuid.UUID, report_date: date
) -> DailyReportResponse:
    # Total rooms
    total_rooms = await db.scalar(
        select(func.count(Room.room_id)).where(Room.property_id == property_id)
    ) or 0

    # Occupied / Vacant
    occupied = await db.scalar(
        select(func.count(Room.room_id)).where(
            Room.property_id == property_id,
            func.lower(Room.occupancy_status) == 'occupied'
        )
    ) or 0
    vacant = total_rooms - occupied

    # Check-ins today
    checkins = await db.scalar(
        select(func.count(CheckIn.checkin_id)).where(
            CheckIn.property_id == property_id,
            func.date(CheckIn.checked_in_at) == report_date
        )
    ) or 0

    # Check-outs today
    checkouts = await db.scalar(
        select(func.count(CheckOut.checkout_id)).where(
            CheckOut.property_id == property_id,
            func.date(CheckOut.checkout_time) == report_date
        )
    ) or 0

    # New bookings
    new_bookings = await db.scalar(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            func.date(Booking.created_at) == report_date,
            Booking.booking_status != 'cancelled'
        )
    ) or 0

    # Cancelled bookings
    cancelled = await db.scalar(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            func.date(Booking.updated_at) == report_date,
            Booking.booking_status == 'cancelled'
        )
    ) or 0

    # Revenue collected
    revenue = await db.scalar(
        select(func.coalesce(func.sum(Payment.amount), 0)).join(Booking).where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) == report_date,
            Payment.status == 'Completed'
        )
    ) or 0

    # Pending payments
    pending = await db.scalar(
        select(func.coalesce(func.sum(Booking.pending_amount), 0)).where(
            Booking.property_id == property_id,
            Booking.payment_status.in_(['Pending', 'Partial']),
            Booking.booking_status != 'cancelled'
        )
    ) or 0

    # Housekeeping
    hk_completed = await db.scalar(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
            func.date(HousekeepingTask.completed_at) == report_date,
            HousekeepingTask.status == 'completed'
        )
    ) or 0
    hk_pending = await db.scalar(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
            HousekeepingTask.status.in_(['pending', 'in_progress']),
        )
    ) or 0

    occ_pct = round((occupied / total_rooms * 100) if total_rooms > 0 else 0, 1)

    return DailyReportResponse(
        report_date=report_date,
        property_id=property_id,
        total_checkins=checkins,
        total_checkouts=checkouts,
        occupied_rooms=occupied,
        vacant_rooms=vacant,
        new_bookings=new_bookings,
        cancelled_bookings=cancelled,
        revenue_collected=float(revenue),
        pending_payments=float(pending),
        housekeeping_completed=hk_completed,
        housekeeping_pending=hk_pending,
        total_rooms=total_rooms,
        occupancy_pct=occ_pct,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 2. Monthly Report
# ══════════════════════════════════════════════════════════════════

async def get_monthly_report(
    db: AsyncSession, property_id: uuid.UUID, month: int, year: int
) -> MonthlyReportResponse:
    first_day = date(year, month, 1)
    _, last = monthrange(year, month)
    last_day = date(year, month, last)

    # Total bookings in month
    total_bookings = await db.scalar(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            Booking.check_in_date <= last_day,
            Booking.check_out_date >= first_day,
            Booking.booking_status != 'cancelled'
        )
    ) or 0

    cancelled = await db.scalar(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            func.date(Booking.updated_at) >= first_day,
            func.date(Booking.updated_at) <= last_day,
            Booking.booking_status == 'cancelled'
        )
    ) or 0

    # Revenue
    total_revenue = await db.scalar(
        select(func.coalesce(func.sum(Payment.amount), 0)).join(Booking).where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= first_day,
            func.date(Payment.created_at) <= last_day,
            Payment.status == 'Completed'
        )
    ) or 0

    # Outstanding
    total_outstanding = await db.scalar(
        select(func.coalesce(func.sum(Booking.pending_amount), 0)).where(
            Booking.property_id == property_id,
            Booking.payment_status.in_(['Pending', 'Partial']),
            Booking.booking_status != 'cancelled'
        )
    ) or 0

    # Expenses
    total_expenses = await db.scalar(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(
            Expense.property_id == property_id,
            Expense.expense_date >= first_day,
            Expense.expense_date <= last_day
        )
    ) or 0

    # Occupancy
    total_rooms = await db.scalar(
        select(func.count(Room.room_id)).where(Room.property_id == property_id)
    ) or 0
    total_room_nights = total_rooms * last
    occupied_nights = await db.scalar(
        select(func.coalesce(
            func.sum(
                func.least(Booking.check_out_date, last_day) - func.greatest(Booking.check_in_date, first_day)
            ), 0
        )).where(
            Booking.property_id == property_id,
            Booking.check_in_date <= last_day,
            Booking.check_out_date >= first_day,
            Booking.booking_status.in_(['confirmed', 'checked_in', 'checked_out', 'upcoming'])
        )
    ) or 0
    occ_pct = round((int(occupied_nights) / total_room_nights * 100) if total_room_nights > 0 else 0, 1)

    # Previous month revenue for comparison
    if month == 1:
        prev_first = date(year - 1, 12, 1)
        prev_last = date(year - 1, 12, 31)
    else:
        prev_first = date(year, month - 1, 1)
        _, prev_last_day = monthrange(year, month - 1)
        prev_last = date(year, month - 1, prev_last_day)

    prev_revenue = await db.scalar(
        select(func.coalesce(func.sum(Payment.amount), 0)).join(Booking).where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= prev_first,
            func.date(Payment.created_at) <= prev_last,
            Payment.status == 'Completed'
        )
    ) or 0

    rev_growth = 0.0
    if float(prev_revenue) > 0:
        rev_growth = round(((float(total_revenue) - float(prev_revenue)) / float(prev_revenue)) * 100, 1)

    # Daily revenue trend from KPI snapshots
    kpi_stmt = select(DailyKPISnapshot).where(
        DailyKPISnapshot.property_id == property_id,
        DailyKPISnapshot.snapshot_date >= first_day,
        DailyKPISnapshot.snapshot_date <= last_day,
    ).order_by(DailyKPISnapshot.snapshot_date)
    kpi_res = await db.execute(kpi_stmt)
    daily_trend = [
        {"date": str(k.snapshot_date), "revenue": float(k.revenue_room_rent) + float(k.revenue_addons)}
        for k in kpi_res.scalars().all()
    ]

    return MonthlyReportResponse(
        property_id=property_id,
        month=month,
        year=year,
        total_bookings=total_bookings,
        occupancy_pct=occ_pct,
        total_revenue=float(total_revenue),
        total_collected=float(total_revenue),
        total_outstanding=float(total_outstanding),
        total_expenses=float(total_expenses),
        cancelled_bookings=cancelled,
        prev_month_revenue=float(prev_revenue),
        revenue_growth_pct=rev_growth,
        daily_revenue_trend=daily_trend,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 3. Occupancy Report
# ══════════════════════════════════════════════════════════════════

async def get_occupancy_report(
    db: AsyncSession, property_id: uuid.UUID,
    start_date: date, end_date: date,
    room_type: Optional[str] = None
) -> OccupancyReportResponse:
    total_rooms = await db.scalar(
        select(func.count(Room.room_id)).where(Room.property_id == property_id)
    ) or 0

    num_days = (end_date - start_date).days + 1
    available_room_nights = total_rooms * num_days

    # Occupied room-nights from bookings
    booking_q = select(Booking).where(
        Booking.property_id == property_id,
        Booking.check_in_date <= end_date,
        Booking.check_out_date >= start_date,
        Booking.booking_status.in_(['confirmed', 'checked_in', 'checked_out', 'upcoming'])
    )
    if room_type:
        booking_q = booking_q.join(Room).join(RoomCategory).where(RoomCategory.room_name == room_type)

    bookings_res = await db.execute(booking_q)
    bookings = bookings_res.scalars().all()

    occupied_nights = 0
    for b in bookings:
        eff_start = max(b.check_in_date, start_date)
        eff_end = min(b.check_out_date, end_date)
        occupied_nights += max((eff_end - eff_start).days, 0)

    avg_occ = round((occupied_nights / available_room_nights * 100) if available_room_nights > 0 else 0, 1)

    # Reserved rooms today
    today = date.today()
    reserved = await db.scalar(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            Booking.check_in_date <= today,
            Booking.check_out_date > today,
            Booking.booking_status.in_(['confirmed', 'checked_in', 'upcoming'])
        )
    ) or 0

    # Daily occupancy from KPI snapshots
    kpi_res = await db.execute(
        select(DailyKPISnapshot).where(
            DailyKPISnapshot.property_id == property_id,
            DailyKPISnapshot.snapshot_date >= start_date,
            DailyKPISnapshot.snapshot_date <= end_date,
        ).order_by(DailyKPISnapshot.snapshot_date)
    )
    daily_occ = []
    for k in kpi_res.scalars().all():
        t = k.occupied_rooms + k.vacant_rooms
        pct = round((k.occupied_rooms / t * 100) if t > 0 else 0, 1)
        daily_occ.append({"date": str(k.snapshot_date), "occupied": k.occupied_rooms, "vacant": k.vacant_rooms, "pct": pct})

    # By room type
    type_res = await db.execute(
        select(
            RoomCategory.room_name,
            func.count(Room.room_id).label("count"),
        )
        .join(Room, Room.room_category_id == RoomCategory.room_category_id)
        .where(Room.property_id == property_id)
        .group_by(RoomCategory.room_name)
    )
    by_type = [{"room_type": r[0] or "Unknown", "count": r[1], "occupancy_pct": 0} for r in type_res.all()]

    return OccupancyReportResponse(
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        total_rooms=total_rooms,
        avg_occupancy_pct=avg_occ,
        occupied_room_nights=occupied_nights,
        available_room_nights=available_room_nights,
        reserved_rooms_today=reserved,
        daily_occupancy=daily_occ,
        by_room_type=by_type,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 4. Revenue Report
# ══════════════════════════════════════════════════════════════════

async def get_revenue_report(
    db: AsyncSession, property_id: uuid.UUID,
    start_date: date, end_date: date
) -> RevenueReportResponse:
    # Total revenue
    total = await db.scalar(
        select(func.coalesce(func.sum(Payment.amount), 0))
        .join(Booking).where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= start_date,
            func.date(Payment.created_at) <= end_date,
            Payment.status == 'Completed'
        )
    ) or 0

    # By payment method
    method_res = await db.execute(
        select(Payment.payment_mode, func.sum(Payment.amount))
        .join(Booking).where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= start_date,
            func.date(Payment.created_at) <= end_date,
            Payment.status == 'Completed'
        ).group_by(Payment.payment_mode)
    )
    by_method = [{"method": r[0] or "Other", "revenue": float(r[1])} for r in method_res.all()]

    # By booking source
    source_res = await db.execute(
        select(Booking.booking_source, func.coalesce(func.sum(Payment.amount), 0))
        .join(Payment, Payment.booking_id == Booking.booking_id)
        .where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= start_date,
            func.date(Payment.created_at) <= end_date,
            Payment.status == 'Completed'
        ).group_by(Booking.booking_source)
    )
    by_source = [{"source": r[0] or "Direct", "revenue": float(r[1])} for r in source_res.all()]

    # Taxes collected
    taxes = await db.scalar(
        select(func.coalesce(func.sum(Booking.taxes), 0)).where(
            Booking.property_id == property_id,
            Booking.check_in_date <= end_date,
            Booking.check_out_date >= start_date,
            Booking.booking_status != 'cancelled'
        )
    ) or 0

    # Discounts
    discounts = await db.scalar(
        select(func.coalesce(func.sum(Booking.discount), 0)).where(
            Booking.property_id == property_id,
            Booking.check_in_date <= end_date,
            Booking.check_out_date >= start_date,
            Booking.booking_status != 'cancelled'
        )
    ) or 0

    # By room type
    room_type_res = await db.execute(
        select(RoomCategory.room_name, func.coalesce(func.sum(Payment.amount), 0))
        .select_from(Payment)
        .join(Booking, Payment.booking_id == Booking.booking_id)
        .join(Room, Booking.room_id == Room.room_id)
        .join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id)
        .where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= start_date,
            func.date(Payment.created_at) <= end_date,
            Payment.status == 'Completed'
        ).group_by(RoomCategory.room_name)
    )
    by_room_type = [{"room_type": r[0] or "Unknown", "revenue": float(r[1])} for r in room_type_res.all()]

    # Daily trend
    daily_res = await db.execute(
        select(func.date(Payment.created_at).label("d"), func.sum(Payment.amount))
        .join(Booking).where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= start_date,
            func.date(Payment.created_at) <= end_date,
            Payment.status == 'Completed'
        ).group_by("d").order_by("d")
    )
    daily_trend = [{"date": str(r[0]), "revenue": float(r[1])} for r in daily_res.all()]

    return RevenueReportResponse(
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        total_revenue=float(total),
        by_room_type=by_room_type,
        by_booking_source=by_source,
        by_payment_method=by_method,
        taxes_collected=float(taxes),
        discounts_given=float(discounts),
        daily_revenue_trend=daily_trend,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 5. Collection Report
# ══════════════════════════════════════════════════════════════════

async def get_collection_report(
    db: AsyncSession, property_id: uuid.UUID,
    start_date: date, end_date: date
) -> CollectionReportResponse:
    base = (
        select(Payment.payment_mode, func.sum(Payment.amount).label("total"), func.count().label("cnt"))
        .join(Booking).where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= start_date,
            func.date(Payment.created_at) <= end_date,
            Payment.status == 'Completed'
        ).group_by(Payment.payment_mode)
    )
    res = await db.execute(base)
    rows = res.all()

    mode_map = defaultdict(lambda: {"amount": 0.0, "count": 0})
    for mode, amt, cnt in rows:
        key = (mode or "Other").lower()
        mode_map[key]["amount"] = float(amt)
        mode_map[key]["count"] = cnt

    total = sum(v["amount"] for v in mode_map.values())

    # Daily collections
    daily_res = await db.execute(
        select(func.date(Payment.created_at).label("d"), func.sum(Payment.amount))
        .join(Booking).where(
            Booking.property_id == property_id,
            func.date(Payment.created_at) >= start_date,
            func.date(Payment.created_at) <= end_date,
            Payment.status == 'Completed'
        ).group_by("d").order_by("d")
    )
    daily = [{"date": str(r[0]), "amount": float(r[1])} for r in daily_res.all()]

    by_method = [{"method": k, "amount": v["amount"], "count": v["count"]} for k, v in mode_map.items()]

    return CollectionReportResponse(
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        total_collections=total,
        cash_collections=mode_map.get("cash", {}).get("amount", 0),
        card_collections=mode_map.get("card", {}).get("amount", 0),
        upi_collections=mode_map.get("upi", {}).get("amount", 0),
        bank_transfer_collections=mode_map.get("bank_transfer", {}).get("amount", 0) + mode_map.get("bank transfer", {}).get("amount", 0),
        other_collections=mode_map.get("other", {}).get("amount", 0),
        by_method=by_method,
        daily_collections=daily,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 6. Outstanding Report
# ══════════════════════════════════════════════════════════════════

async def get_outstanding_report(
    db: AsyncSession, property_id: uuid.UUID,
    start_date: date, end_date: date
) -> OutstandingReportResponse:
    # Outstanding bookings
    stmt = (
        select(Booking, Guest)
        .join(Guest, Booking.guest_id == Guest.guest_id)
        .where(
            Booking.property_id == property_id,
            Booking.payment_status.in_(['Pending', 'Partial']),
            Booking.booking_status != 'cancelled',
            Booking.check_in_date <= end_date,
        )
        .order_by(desc(Booking.pending_amount))
    )
    res = await db.execute(stmt)
    rows = res.all()

    total = 0.0
    customer_wise = []
    ageing = {"0-30": 0.0, "31-60": 0.0, "61-90": 0.0, "90+": 0.0}
    overdue = 0
    today = date.today()

    for booking, guest in rows:
        amt = float(booking.pending_amount or 0)
        total += amt
        days = (today - booking.check_out_date).days if booking.check_out_date <= today else 0
        if days > 0:
            overdue += 1
        if days <= 30:
            ageing["0-30"] += amt
        elif days <= 60:
            ageing["31-60"] += amt
        elif days <= 90:
            ageing["61-90"] += amt
        else:
            ageing["90+"] += amt

        customer_wise.append({
            "guest_name": guest.full_name,
            "amount": amt,
            "booking_ref": booking.booking_reference or str(booking.booking_id)[:8],
            "due_date": str(booking.check_out_date),
        })

    # Pending invoices
    pending_invoices = await db.scalar(
        select(func.count(Invoice.invoice_id)).where(
            Invoice.property_id == property_id,
            Invoice.status.in_(['Pending', 'Partial']),
        )
    ) or 0

    return OutstandingReportResponse(
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        total_outstanding=total,
        pending_invoices_count=pending_invoices,
        overdue_count=overdue,
        customer_wise=customer_wise[:50],
        ageing=ageing,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 7. Expenses Report
# ══════════════════════════════════════════════════════════════════

async def get_expenses_report(
    db: AsyncSession, property_id: uuid.UUID,
    start_date: date, end_date: date,
    category: Optional[str] = None,
) -> ExpensesReportResponse:
    base_filter = [
        Expense.property_id == property_id,
        Expense.expense_date >= start_date,
        Expense.expense_date <= end_date,
    ]
    if category:
        base_filter.append(Expense.category == category)

    total = await db.scalar(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(*base_filter)
    ) or 0

    # By category
    cat_res = await db.execute(
        select(Expense.category, func.sum(Expense.amount), func.count())
        .where(*base_filter)
        .group_by(Expense.category)
    )
    by_cat = [{"category": r[0], "amount": float(r[1]), "count": r[2]} for r in cat_res.all()]

    # Monthly trend
    monthly_res = await db.execute(
        select(
            func.to_char(Expense.expense_date, 'YYYY-MM').label("m"),
            func.sum(Expense.amount),
        ).where(
            Expense.property_id == property_id,
            Expense.expense_date >= start_date,
            Expense.expense_date <= end_date,
        ).group_by("m").order_by("m")
    )
    monthly_trend = [{"month": r[0], "amount": float(r[1])} for r in monthly_res.all()]

    # Recent expenses
    recent_res = await db.execute(
        select(Expense).where(*base_filter).order_by(desc(Expense.expense_date)).limit(20)
    )
    recent = [ExpenseResponse.model_validate(e) for e in recent_res.scalars().all()]

    return ExpensesReportResponse(
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        total_expenses=float(total),
        by_category=by_cat,
        monthly_trend=monthly_trend,
        recent_expenses=recent,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 8. Best Customers Report
# ══════════════════════════════════════════════════════════════════

async def get_best_customers_report(
    db: AsyncSession, property_id: uuid.UUID,
    start_date: date, end_date: date
) -> BestCustomersReportResponse:
    stmt = (
        select(
            Guest.guest_id,
            Guest.full_name,
            func.count(Booking.booking_id).label("total_bookings"),
            func.coalesce(func.sum(
                func.least(Booking.check_out_date, end_date) - func.greatest(Booking.check_in_date, start_date)
            ), 0).label("total_nights"),
            func.coalesce(func.sum(Booking.total_payable), 0).label("total_revenue"),
            func.max(Booking.check_out_date).label("last_stay"),
        )
        .join(Booking, Booking.guest_id == Guest.guest_id)
        .where(
            Booking.property_id == property_id,
            Booking.check_in_date <= end_date,
            Booking.check_out_date >= start_date,
            Booking.booking_status != 'cancelled',
        )
        .group_by(Guest.guest_id, Guest.full_name)
        .order_by(desc("total_revenue"))
        .limit(20)
    )
    res = await db.execute(stmt)
    customers = []
    for r in res.all():
        total_rev = float(r[4])
        total_book = int(r[2])
        customers.append(BestCustomerRow(
            guest_id=r[0],
            guest_name=r[1],
            total_bookings=total_book,
            total_nights=max(int(r[3]), 0),
            total_revenue=total_rev,
            avg_booking_value=round(total_rev / total_book, 2) if total_book > 0 else 0,
            last_stay_date=r[5],
        ))

    return BestCustomersReportResponse(
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        customers=customers,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 9. Room Utilization Report
# ══════════════════════════════════════════════════════════════════

async def get_room_utilization_report(
    db: AsyncSession, property_id: uuid.UUID,
    start_date: date, end_date: date,
    room_type: Optional[str] = None,
) -> RoomUtilizationReportResponse:
    num_days = (end_date - start_date).days + 1

    room_q = (
        select(Room, RoomCategory.room_name)
        .join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id)
        .where(Room.property_id == property_id)
    )
    if room_type:
        room_q = room_q.where(RoomCategory.room_name == room_type)

    rooms_res = await db.execute(room_q)
    rooms_data = rooms_res.all()

    utilization = []
    best_occ = ("", 0.0)
    worst_occ = ("", 101.0)

    for room, cat_name in rooms_data:
        # Bookings for this room
        bk_res = await db.execute(
            select(Booking).where(
                Booking.room_id == room.room_id,
                Booking.check_in_date <= end_date,
                Booking.check_out_date >= start_date,
                Booking.booking_status.in_(['confirmed', 'checked_in', 'checked_out', 'upcoming'])
            )
        )
        room_bookings = bk_res.scalars().all()
        occ_nights = 0
        rev = 0.0
        for b in room_bookings:
            eff_start = max(b.check_in_date, start_date)
            eff_end = min(b.check_out_date, end_date)
            occ_nights += max((eff_end - eff_start).days, 0)
            rev += float(b.total_payable or 0)

        idle = num_days - occ_nights
        pct = round((occ_nights / num_days * 100) if num_days > 0 else 0, 1)

        utilization.append(RoomUtilizationRow(
            room_id=room.room_id,
            room_number=room.room_number,
            room_type=cat_name or "Unknown",
            total_bookings=len(room_bookings),
            occupied_nights=occ_nights,
            idle_days=max(idle, 0),
            occupancy_pct=pct,
            revenue=rev,
        ))

        if pct > best_occ[1]:
            best_occ = (room.room_number, pct)
        if pct < worst_occ[1]:
            worst_occ = (room.room_number, pct)

    return RoomUtilizationReportResponse(
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        rooms=utilization,
        most_utilized=best_occ[0] if utilization else None,
        least_utilized=worst_occ[0] if utilization else None,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: 10. Staff Performance Report
# ══════════════════════════════════════════════════════════════════

async def get_staff_performance_report(
    db: AsyncSession, property_id: uuid.UUID,
    start_date: date, end_date: date,
    staff_id: Optional[uuid.UUID] = None,
) -> StaffPerformanceReportResponse:
    # Get staff users for this property
    staff_q = (
        select(User, Role.role_name)
        .join(Role, User.role_id == Role.id)
        .where(
            User.property_id == property_id,
            User.status == "ACTIVE",
            Role.role_code.notin_(["SUPER_ADMIN", "GUEST"]),
        )
    )
    if staff_id:
        staff_q = staff_q.where(User.id == staff_id)

    staff_res = await db.execute(staff_q)
    staff_data = staff_res.all()

    perf = []
    total_completed = 0
    total_pending = 0

    for user, role_name in staff_data:
        # Tasks completed
        completed = await db.scalar(
            select(func.count(Task.task_id)).where(
                Task.property_id == property_id,
                Task.assigned_to == user.id,
                Task.status == 'completed',
                func.date(Task.completed_at) >= start_date,
                func.date(Task.completed_at) <= end_date,
            )
        ) or 0

        pending = await db.scalar(
            select(func.count(Task.task_id)).where(
                Task.property_id == property_id,
                Task.assigned_to == user.id,
                Task.status.in_(['pending', 'accepted', 'in_progress']),
            )
        ) or 0

        hk_tasks = await db.scalar(
            select(func.count(HousekeepingTask.task_id)).where(
                HousekeepingTask.property_id == property_id,
                HousekeepingTask.assigned_staff_id == user.id,
                func.date(HousekeepingTask.completed_at) >= start_date,
                func.date(HousekeepingTask.completed_at) <= end_date,
            )
        ) or 0

        bookings_handled = await db.scalar(
            select(func.count(CheckIn.checkin_id)).where(
                CheckIn.property_id == property_id,
                CheckIn.staff_id == user.id,
                func.date(CheckIn.checked_in_at) >= start_date,
                func.date(CheckIn.checked_in_at) <= end_date,
            )
        ) or 0

        total_completed += completed
        total_pending += pending

        perf.append(StaffPerformanceRow(
            user_id=user.id,
            staff_name=user.name,
            role=role_name,
            tasks_completed=completed,
            tasks_pending=pending,
            housekeeping_tasks=hk_tasks,
            bookings_handled=bookings_handled,
        ))

    return StaffPerformanceReportResponse(
        property_id=property_id,
        start_date=start_date,
        end_date=end_date,
        staff=perf,
        total_tasks_completed=total_completed,
        total_tasks_pending=total_pending,
    )


# ══════════════════════════════════════════════════════════════════
#  NEW: Global Summary (Superadmin)
# ══════════════════════════════════════════════════════════════════

async def get_global_summary(db: AsyncSession) -> GlobalSummaryResponse:
    # All properties
    props_res = await db.execute(select(Property))
    properties = props_res.scalars().all()

    summaries = []
    total_rev = 0.0
    total_outstanding = 0.0
    occ_pcts = []

    today = date.today()
    first_of_month = date(today.year, today.month, 1)

    for prop in properties:
        rooms_count = await db.scalar(
            select(func.count(Room.room_id)).where(Room.property_id == prop.property_id)
        ) or 0

        occupied = await db.scalar(
            select(func.count(Room.room_id)).where(
                Room.property_id == prop.property_id,
                func.lower(Room.occupancy_status) == 'occupied'
            )
        ) or 0

        occ_pct = round((occupied / rooms_count * 100) if rooms_count > 0 else 0, 1)
        occ_pcts.append(occ_pct)

        revenue = await db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0))
            .join(Booking).where(
                Booking.property_id == prop.property_id,
                func.date(Payment.created_at) >= first_of_month,
                Payment.status == 'Completed'
            )
        ) or 0

        outstanding = await db.scalar(
            select(func.coalesce(func.sum(Booking.pending_amount), 0)).where(
                Booking.property_id == prop.property_id,
                Booking.payment_status.in_(['Pending', 'Partial']),
                Booking.booking_status != 'cancelled'
            )
        ) or 0

        total_rev += float(revenue)
        total_outstanding += float(outstanding)

        summaries.append(PropertySummaryRow(
            property_id=prop.property_id,
            property_name=prop.property_name,
            total_rooms=rooms_count,
            occupancy_pct=occ_pct,
            revenue=float(revenue),
            outstanding=float(outstanding),
        ))

    avg_occ = round(sum(occ_pcts) / len(occ_pcts), 1) if occ_pcts else 0

    return GlobalSummaryResponse(
        total_properties=len(properties),
        total_revenue=total_rev,
        avg_occupancy_pct=avg_occ,
        total_outstanding=total_outstanding,
        properties=summaries,
    )


# ══════════════════════════════════════════════════════════════════
#  Expense CRUD helpers
# ══════════════════════════════════════════════════════════════════

async def create_expense(
    db: AsyncSession, property_id: uuid.UUID, user_id: uuid.UUID,
    category: str, description: str, amount: float, expense_date: date,
) -> ExpenseResponse:
    exp = Expense(
        property_id=property_id,
        category=category,
        description=description,
        amount=amount,
        expense_date=expense_date,
        created_by=user_id,
    )
    db.add(exp)
    await db.flush()
    await db.refresh(exp)
    return ExpenseResponse.model_validate(exp)
