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
