"""
Manager Module — Pydantic Schemas (DTOs)
"""
from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Optional, List, Dict, Any

from pydantic import BaseModel, Field


# ── Dashboard ─────────────────────────────────────────────────────────────────

class DashboardKPI(BaseModel):
    name: str
    value: str
    icon: Optional[str] = None
    trend: Optional[str] = None  # "up" | "down" | "neutral"


class StaffAvailabilityItem(BaseModel):
    staff_id: uuid.UUID
    name: str
    role_code: Optional[str] = None
    shift_status: str  # on_shift | off_shift | on_leave


class ManagerDashboardResponse(BaseModel):
    date: str
    kpis: List[DashboardKPI]
    arrivals: int = 0
    departures: int = 0
    occupancy_percent: float = 0.0
    active_tasks: int = 0
    pending_requests: int = 0
    today_maintenance: int = 0
    today_cleaning: int = 0
    room_blocks: int = 0
    staff_on_shift: int = 0
    staff_availability: List[StaffAvailabilityItem] = []


# ── Staff ─────────────────────────────────────────────────────────────────────

class StaffListItem(BaseModel):
    id: uuid.UUID
    name: str
    email: Optional[str] = None
    mobile_number: Optional[str] = None
    role_id: Optional[uuid.UUID] = None
    role_code: Optional[str] = None
    status: str
    on_shift_today: bool = False

    class Config:
        from_attributes = True


class AttendanceRecord(BaseModel):
    attendance_id: uuid.UUID
    staff_id: uuid.UUID
    staff_name: Optional[str] = None
    property_id: uuid.UUID
    attendance_date: date
    check_in_time: Optional[datetime] = None
    check_out_time: Optional[datetime] = None
    status: str
    remarks: Optional[str] = None

    class Config:
        from_attributes = True


class PerformanceRecord(BaseModel):
    performance_id: uuid.UUID
    staff_id: uuid.UUID
    staff_name: Optional[str] = None
    review_period_start: date
    review_period_end: date
    rating: float
    attendance_score: Optional[float] = None
    task_completion_score: Optional[float] = None
    remarks: Optional[str] = None

    class Config:
        from_attributes = True


class TaskAssignRequest(BaseModel):
    task_id: uuid.UUID
    assigned_to: uuid.UUID
    property_id: uuid.UUID
    due_at: Optional[datetime] = None
    priority: Optional[str] = None  # normal, high, emergency


class TaskAssignResponse(BaseModel):
    message: str
    task_id: str


class StaffShiftCreate(BaseModel):
    property_id: uuid.UUID
    staff_id: uuid.UUID
    shift_date: date
    shift_type: str  # morning, afternoon, evening, night, full_day
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    notes: Optional[str] = None


class StaffShiftResponse(BaseModel):
    shift_id: uuid.UUID
    property_id: uuid.UUID
    staff_id: uuid.UUID
    shift_date: date
    shift_type: str
    status: str
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── Bookings ──────────────────────────────────────────────────────────────────

class BookingListItem(BaseModel):
    booking_id: uuid.UUID
    room_id: uuid.UUID
    room_number: Optional[str] = None
    guest_id: uuid.UUID
    guest_name: Optional[str] = None
    guest_mobile: Optional[str] = None
    check_in_date: date
    check_out_date: date
    adults: int
    children: int
    booking_status: Optional[str] = None
    payment_status: Optional[str] = None
    booking_source: Optional[str] = None
    total_payable: Optional[float] = None

    class Config:
        from_attributes = True


class BookingModifyRequest(BaseModel):
    notes: Optional[str] = None
    booking_status: Optional[str] = None
    check_in_date: Optional[date] = None
    check_out_date: Optional[date] = None


class ChangeRoomRequest(BaseModel):
    new_room_id: uuid.UUID
    reason: Optional[str] = None


# ── Check-in Monitoring ───────────────────────────────────────────────────────

class CheckInFeedItem(BaseModel):
    checkin_id: uuid.UUID
    booking_id: uuid.UUID
    room_id: uuid.UUID
    room_number: Optional[str] = None
    guest_id: uuid.UUID
    guest_name: Optional[str] = None
    checked_in_at: Optional[datetime] = None
    status: str

    class Config:
        from_attributes = True


class CheckOutFeedItem(BaseModel):
    checkout_id: uuid.UUID
    checkin_id: uuid.UUID
    booking_id: uuid.UUID
    room_id: uuid.UUID
    room_number: Optional[str] = None
    checkout_time: Optional[datetime] = None
    checkout_status: str
    payment_status: str

    class Config:
        from_attributes = True


class RoomReadinessItem(BaseModel):
    room_id: uuid.UUID
    room_number: str
    occupancy_status: str
    housekeeping_status: str
    is_blocked: bool = False
    block_reason: Optional[str] = None

    class Config:
        from_attributes = True


# ── Housekeeping Dispatch ─────────────────────────────────────────────────────

class AssignCleaningRequest(BaseModel):
    room_id: uuid.UUID
    property_id: uuid.UUID
    assigned_staff_id: uuid.UUID
    task_type: Optional[str] = "cleaning"  # cleaning, laundry, deep_clean
    priority: Optional[str] = "medium"
    remarks: Optional[str] = None


class ReassignTaskRequest(BaseModel):
    new_staff_id: uuid.UUID
    reason: Optional[str] = None


class HousekeepingProgressItem(BaseModel):
    task_id: uuid.UUID
    room_id: uuid.UUID
    room_number: Optional[str] = None
    task_type: Optional[str] = None
    status: str
    priority: str
    assigned_staff_id: Optional[uuid.UUID] = None
    assigned_staff_name: Optional[str] = None
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class InspectionRequest(BaseModel):
    inspection_result: str = Field(..., pattern=r"^(pass|fail)$")
    inspection_remarks: Optional[str] = None


class CloseTaskRequest(BaseModel):
    remarks: Optional[str] = None


# ── Maintenance ───────────────────────────────────────────────────────────────

class MaintenanceCreateRequest(BaseModel):
    property_id: uuid.UUID
    room_id: uuid.UUID
    category: str  # Electrical, AC, Plumbing, TV, Furniture, etc.
    priority: str = "medium"  # low, medium, high, critical
    issue_description: str
    assigned_to: Optional[uuid.UUID] = None
    photo_url: Optional[str] = None


class MaintenanceAssignRequest(BaseModel):
    assigned_to: uuid.UUID
    notes: Optional[str] = None


class MaintenanceUpdateRequest(BaseModel):
    status: Optional[str] = None  # open, assigned, in_progress, resolved, closed
    assigned_to: Optional[uuid.UUID] = None
    priority: Optional[str] = None
    notes: Optional[str] = None


class MaintenanceTicketItem(BaseModel):
    ticket_id: uuid.UUID
    room_id: uuid.UUID
    room_number: Optional[str] = None
    property_id: uuid.UUID
    category: str
    priority: str
    issue_description: str
    status: str
    assigned_to: Optional[uuid.UUID] = None
    assigned_to_name: Optional[str] = None
    reported_by: Optional[uuid.UUID] = None
    reported_by_name: Optional[str] = None
    created_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── Reports ───────────────────────────────────────────────────────────────────

class OperationalReportRequest(BaseModel):
    property_id: uuid.UUID
    from_date: date
    to_date: date


class OperationalReportResponse(BaseModel):
    property_id: uuid.UUID
    from_date: date
    to_date: date
    total_bookings: int = 0
    confirmed_bookings: int = 0
    cancelled_bookings: int = 0
    total_check_ins: int = 0
    total_check_outs: int = 0
    occupancy_percent: float = 0.0
    housekeeping_tasks_completed: int = 0
    maintenance_tickets_resolved: int = 0
    open_maintenance_tickets: int = 0


class OccupancyReportResponse(BaseModel):
    property_id: uuid.UUID
    from_date: date
    to_date: date
    total_rooms: int = 0
    avg_occupancy_percent: float = 0.0
    peak_date: Optional[str] = None
    daily_breakdown: List[Dict[str, Any]] = []


class HousekeepingReportResponse(BaseModel):
    property_id: uuid.UUID
    from_date: date
    to_date: date
    total_tasks: int = 0
    completed_tasks: int = 0
    pending_tasks: int = 0
    avg_completion_time_minutes: Optional[float] = None
    inspection_pass_rate: float = 0.0


class MaintenanceReportResponse(BaseModel):
    property_id: uuid.UUID
    from_date: date
    to_date: date
    total_tickets: int = 0
    open_tickets: int = 0
    resolved_tickets: int = 0
    avg_resolution_time_hours: Optional[float] = None
    by_category: List[Dict[str, Any]] = []


class StaffPerformanceReportResponse(BaseModel):
    property_id: uuid.UUID
    from_date: date
    to_date: date
    staff_metrics: List[Dict[str, Any]] = []


# ── Room Blocks ───────────────────────────────────────────────────────────────

class RoomBlockCreate(BaseModel):
    property_id: uuid.UUID
    room_id: uuid.UUID
    from_date: date
    to_date: date
    reason: str  # maintenance, renovation, vip_hold, inspection, deep_cleaning, other
    notes: Optional[str] = None


class RoomBlockResponse(BaseModel):
    block_id: uuid.UUID
    property_id: uuid.UUID
    room_id: uuid.UUID
    room_number: Optional[str] = None
    blocked_by: uuid.UUID
    blocked_by_name: Optional[str] = None
    from_date: date
    to_date: date
    reason: str
    notes: Optional[str] = None
    is_active: bool
    created_at: Optional[datetime] = None
    released_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── Manager Notes ─────────────────────────────────────────────────────────────

class ManagerNoteCreate(BaseModel):
    property_id: uuid.UUID
    note_type: str = "general"  # general, shift_handover, maintenance, guest, housekeeping
    content: str
    room_id: Optional[uuid.UUID] = None
    booking_id: Optional[uuid.UUID] = None
    is_pinned: Optional[bool] = False


class ManagerNoteResponse(BaseModel):
    note_id: uuid.UUID
    property_id: uuid.UUID
    created_by: uuid.UUID
    created_by_name: Optional[str] = None
    note_type: str
    content: str
    is_pinned: bool
    is_resolved: bool
    room_id: Optional[uuid.UUID] = None
    booking_id: Optional[uuid.UUID] = None
    created_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── Daily Checklists ──────────────────────────────────────────────────────────

class ChecklistCreate(BaseModel):
    property_id: uuid.UUID
    checklist_date: date
    shift: str = "morning"  # morning, afternoon, evening, night
    items: Optional[Dict[str, bool]] = None


class ChecklistUpdateRequest(BaseModel):
    items: Dict[str, bool]
    notes: Optional[str] = None
    status: Optional[str] = None  # pending, in_progress, completed


class ChecklistSignOffRequest(BaseModel):
    notes: Optional[str] = None


class ChecklistResponse(BaseModel):
    checklist_id: uuid.UUID
    property_id: uuid.UUID
    manager_id: uuid.UUID
    manager_name: Optional[str] = None
    checklist_date: date
    shift: str
    items: Optional[Dict[str, Any]] = None
    status: str
    notes: Optional[str] = None
    completed_at: Optional[datetime] = None
    signed_off_by: Optional[uuid.UUID] = None
    signed_off_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── Notifications (for sending) ───────────────────────────────────────────────

class NotificationOut(BaseModel):
    notification_id: uuid.UUID
    title: str
    message: str
    channel: str
    status: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── Service Requests ──────────────────────────────────────────────────────────

class ServiceRequestListItem(BaseModel):
    request_id: uuid.UUID
    property_id: uuid.UUID
    room_id: Optional[uuid.UUID] = None
    room_number: Optional[str] = None
    request_category: str
    title: str
    priority: str
    status: str
    assigned_to: Optional[uuid.UUID] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ServiceRequestAssignRequest(BaseModel):
    assigned_to: uuid.UUID
    notes: Optional[str] = None
