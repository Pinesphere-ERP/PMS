import uuid
from datetime import date, datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, ConfigDict


# ── Daily KPI Snapshot ──────────────────────────────────────────

class DailyKPISnapshotResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    snapshot_id: uuid.UUID
    property_id: uuid.UUID
    snapshot_date: date
    occupied_rooms: int
    vacant_rooms: int
    revenue_room_rent: float
    revenue_addons: float
    expenses_amount: float
    outstanding_payments: float
    gst_collected: float
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


# ── P&L Report ─────────────────────────────────────────────────

class MonthlyPLRow(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    month: str
    total_room_rent: float
    total_addons: float
    total_revenue: float
    total_expenses: float
    net_profit: float
    gst_collected: float
    outstanding: float


class PLReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    property_id: uuid.UUID
    period_start: date
    period_end: date
    monthly_breakdown: List[MonthlyPLRow]
    summary_total_revenue: float
    summary_total_expenses: float
    summary_net_profit: float


# ── GST Return ─────────────────────────────────────────────────

class GSTReturnResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    property_id: uuid.UUID
    period_start: date
    period_end: date
    total_taxable_revenue: float
    total_gst_collected: float
    cgst: float
    sgst: float
    igst: float
    monthly_gst: List[Dict[str, Any]]


# ── Report Template ────────────────────────────────────────────

class ReportTemplateCreateRequest(BaseModel):
    report_name: str
    report_type: str
    configuration_json: Optional[Dict[str, Any]] = None


class ReportTemplateUpdateRequest(BaseModel):
    report_name: Optional[str] = None
    report_type: Optional[str] = None
    configuration_json: Optional[Dict[str, Any]] = None


class ReportTemplateResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    template_id: uuid.UUID
    property_id: Optional[uuid.UUID] = None
    report_name: str
    report_type: str
    configuration_json: Optional[Dict[str, Any]] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ReportTemplateListResponse(BaseModel):
    items: List[ReportTemplateResponse]
    total: int


# ── Scheduled Report ───────────────────────────────────────────

class ScheduledReportCreateRequest(BaseModel):
    template_id: uuid.UUID
    recipient_role: str
    delivery_channel: str
    frequency: str
    is_active: bool = True


class ScheduledReportUpdateRequest(BaseModel):
    recipient_role: Optional[str] = None
    delivery_channel: Optional[str] = None
    frequency: Optional[str] = None
    is_active: Optional[bool] = None


class ScheduledReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    schedule_id: uuid.UUID
    template_id: uuid.UUID
    recipient_role: str
    delivery_channel: str
    frequency: str
    is_active: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class ScheduledReportListResponse(BaseModel):
    items: List[ScheduledReportResponse]
    total: int


# ══════════════════════════════════════════════════════════════════
#  NEW REPORT SCHEMAS
# ══════════════════════════════════════════════════════════════════


# ── 1. Daily Report ────────────────────────────────────────────

class DailyReportResponse(BaseModel):
    report_date: date
    property_id: uuid.UUID
    total_checkins: int
    total_checkouts: int
    occupied_rooms: int
    vacant_rooms: int
    new_bookings: int
    cancelled_bookings: int
    revenue_collected: float
    pending_payments: float
    housekeeping_completed: int
    housekeeping_pending: int
    total_rooms: int
    occupancy_pct: float


# ── 2. Monthly Report ─────────────────────────────────────────

class MonthlyReportResponse(BaseModel):
    property_id: uuid.UUID
    month: int
    year: int
    total_bookings: int
    occupancy_pct: float
    total_revenue: float
    total_collected: float
    total_outstanding: float
    total_expenses: float
    cancelled_bookings: int
    prev_month_revenue: float
    revenue_growth_pct: float
    daily_revenue_trend: List[Dict[str, Any]]  # [{date, revenue}]


# ── 3. Occupancy Report ───────────────────────────────────────

class OccupancyReportResponse(BaseModel):
    property_id: uuid.UUID
    start_date: date
    end_date: date
    total_rooms: int
    avg_occupancy_pct: float
    occupied_room_nights: int
    available_room_nights: int
    reserved_rooms_today: int
    daily_occupancy: List[Dict[str, Any]]  # [{date, occupied, vacant, pct}]
    by_room_type: List[Dict[str, Any]]  # [{room_type, occupancy_pct, count}]


# ── 4. Revenue Report ─────────────────────────────────────────

class RevenueReportResponse(BaseModel):
    property_id: uuid.UUID
    start_date: date
    end_date: date
    total_revenue: float
    by_room_type: List[Dict[str, Any]]  # [{room_type, revenue}]
    by_booking_source: List[Dict[str, Any]]  # [{source, revenue}]
    by_payment_method: List[Dict[str, Any]]  # [{method, revenue}]
    taxes_collected: float
    discounts_given: float
    daily_revenue_trend: List[Dict[str, Any]]  # [{date, revenue}]


# ── 5. Collection Report ──────────────────────────────────────

class CollectionReportResponse(BaseModel):
    property_id: uuid.UUID
    start_date: date
    end_date: date
    total_collections: float
    cash_collections: float
    card_collections: float
    upi_collections: float
    bank_transfer_collections: float
    other_collections: float
    by_method: List[Dict[str, Any]]  # [{method, amount, count}]
    daily_collections: List[Dict[str, Any]]  # [{date, amount}]


# ── 6. Outstanding Report ─────────────────────────────────────

class OutstandingReportResponse(BaseModel):
    property_id: uuid.UUID
    start_date: date
    end_date: date
    total_outstanding: float
    pending_invoices_count: int
    overdue_count: int
    customer_wise: List[Dict[str, Any]]  # [{guest_name, amount, booking_ref, due_date}]
    ageing: Dict[str, float]  # {"0-30": x, "31-60": y, "61-90": z, "90+": w}


# ── 7. Expenses Report ────────────────────────────────────────

class ExpenseCreateRequest(BaseModel):
    category: str
    description: str
    amount: float
    expense_date: date


class ExpenseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    expense_id: uuid.UUID
    property_id: uuid.UUID
    category: str
    description: str
    amount: float
    expense_date: date
    created_by: Optional[uuid.UUID] = None
    created_at: Optional[datetime] = None


class ExpensesReportResponse(BaseModel):
    property_id: uuid.UUID
    start_date: date
    end_date: date
    total_expenses: float
    by_category: List[Dict[str, Any]]  # [{category, amount, count}]
    monthly_trend: List[Dict[str, Any]]  # [{month, amount}]
    recent_expenses: List[ExpenseResponse]


# ── 8. Best Customers Report ──────────────────────────────────

class BestCustomerRow(BaseModel):
    guest_id: uuid.UUID
    guest_name: str
    total_bookings: int
    total_nights: int
    total_revenue: float
    avg_booking_value: float
    last_stay_date: Optional[date] = None


class BestCustomersReportResponse(BaseModel):
    property_id: uuid.UUID
    start_date: date
    end_date: date
    customers: List[BestCustomerRow]


# ── 9. Room Utilization Report ─────────────────────────────────

class RoomUtilizationRow(BaseModel):
    room_id: uuid.UUID
    room_number: str
    room_type: str
    total_bookings: int
    occupied_nights: int
    idle_days: int
    occupancy_pct: float
    revenue: float


class RoomUtilizationReportResponse(BaseModel):
    property_id: uuid.UUID
    start_date: date
    end_date: date
    rooms: List[RoomUtilizationRow]
    most_utilized: Optional[str] = None
    least_utilized: Optional[str] = None


# ── 10. Staff Performance Report ──────────────────────────────

class StaffPerformanceRow(BaseModel):
    user_id: uuid.UUID
    staff_name: str
    role: str
    tasks_completed: int
    tasks_pending: int
    housekeeping_tasks: int
    bookings_handled: int
    avg_task_completion_hours: Optional[float] = None


class StaffPerformanceReportResponse(BaseModel):
    property_id: uuid.UUID
    start_date: date
    end_date: date
    staff: List[StaffPerformanceRow]
    total_tasks_completed: int
    total_tasks_pending: int


# ── Global Summary (Superadmin) ────────────────────────────────

class PropertySummaryRow(BaseModel):
    property_id: uuid.UUID
    property_name: str
    total_rooms: int
    occupancy_pct: float
    revenue: float
    outstanding: float


class GlobalSummaryResponse(BaseModel):
    total_properties: int
    total_revenue: float
    avg_occupancy_pct: float
    total_outstanding: float
    properties: List[PropertySummaryRow]


# ── Access Matrix (for frontends) ─────────────────────────────

class AccessMatrixResponse(BaseModel):
    role_code: str
    reports: List[str]
    can_download_all: bool
