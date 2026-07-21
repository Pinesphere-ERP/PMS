"""
Manager Module — Router

All endpoints for the manager role, organized by feature phase.
No business logic here — delegates to service layer.

Prefix: /manager   (registered in api.py)
"""
from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.infra.models import User
from app.core.dependencies import get_current_user, assert_property_access

from app.modules.manager import service, schemas

router = APIRouter()


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _require_property_access(
    property_id: uuid.UUID,
    current_user: User,
    db: AsyncSession,
) -> None:
    await assert_property_access(property_id, current_user, db)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — DASHBOARD
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/dashboard",
    response_model=schemas.ManagerDashboardResponse,
    tags=["Manager - Dashboard"],
    summary="Manager operational dashboard",
)
async def manager_dashboard(
    property_id: uuid.UUID = Query(..., description="Property to get dashboard for"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Returns the complete operational dashboard for the manager:
    - Arrivals & departures today
    - Occupancy rate
    - Active tasks count
    - Pending service requests
    - Today's maintenance & cleaning tickets
    - Room blocks
    - Staff availability (on-shift vs off-shift)

    **No financial widgets** — those remain Owner-only.
    """
    await _require_property_access(property_id, current_user, db)
    return await service.get_manager_dashboard(db, property_id)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 3 — STAFF MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/staff",
    response_model=List[schemas.StaffListItem],
    tags=["Manager - Staff"],
    summary="List all active staff for this property",
)
async def list_staff(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all ACTIVE staff assigned to the property, with shift status for today."""
    await _require_property_access(property_id, current_user, db)
    return await service.list_staff(db, property_id)


@router.get(
    "/staff/attendance",
    response_model=List[schemas.AttendanceRecord],
    tags=["Manager - Staff"],
    summary="View staff attendance records",
)
async def get_attendance(
    property_id: uuid.UUID = Query(...),
    attendance_date: Optional[date] = Query(None, description="Filter by date (YYYY-MM-DD)"),
    staff_id: Optional[uuid.UUID] = Query(None, description="Filter by specific staff member"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """View staff attendance records. Filter by date or staff_id."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_attendance(db, property_id, attendance_date, staff_id)


@router.get(
    "/staff/performance",
    response_model=List[schemas.PerformanceRecord],
    tags=["Manager - Staff"],
    summary="View staff performance reviews",
)
async def get_performance(
    property_id: uuid.UUID = Query(...),
    staff_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """View staff performance reviews for this property."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_performance(db, property_id, staff_id)


@router.post(
    "/staff/assign-task",
    response_model=schemas.TaskAssignResponse,
    tags=["Manager - Staff"],
    summary="Assign a task to a staff member",
)
async def assign_task(
    payload: schemas.TaskAssignRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Assign or reassign a task to an active staff member.

    Rules:
    - Task must belong to the declared property_id
    - Staff must be ACTIVE in the same property
    - Disabled users cannot receive tasks
    - Cross-property assignment is forbidden
    """
    await _require_property_access(payload.property_id, current_user, db)
    return await service.assign_task(db, payload, current_user)


# Shifts
@router.post(
    "/staff/shifts",
    response_model=schemas.StaffShiftResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Manager - Staff"],
    summary="Create a staff shift schedule",
)
async def create_shift(
    payload: schemas.StaffShiftCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Schedule a shift for a staff member."""
    await _require_property_access(payload.property_id, current_user, db)
    return await service.create_staff_shift(db, payload, current_user)


@router.get(
    "/staff/shifts",
    response_model=List[schemas.StaffShiftResponse],
    tags=["Manager - Staff"],
    summary="List staff shifts",
)
async def list_shifts(
    property_id: uuid.UUID = Query(...),
    shift_date: Optional[date] = Query(None),
    staff_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List shifts for this property, optionally filtered by date or staff_id."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_shifts(db, property_id, shift_date, staff_id)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 4 — BOOKING OVERSIGHT
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/bookings",
    response_model=List[schemas.BookingListItem],
    tags=["Manager - Bookings"],
    summary="List bookings for this property",
)
async def list_bookings(
    property_id: uuid.UUID = Query(...),
    booking_status: Optional[str] = Query(None, description="Filter by booking status"),
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all bookings for this property. Manager can view but not access payment data."""
    await _require_property_access(property_id, current_user, db)
    return await service.list_bookings(db, property_id, booking_status, from_date, to_date, skip, limit)


@router.get(
    "/bookings/{booking_id}",
    response_model=schemas.BookingListItem,
    tags=["Manager - Bookings"],
    summary="Get booking details",
)
async def get_booking(
    booking_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get full details for a specific booking."""
    detail = await service.get_booking_detail(db, booking_id)
    from app.infra.models import Booking
    booking_res = await db.execute(
        __import__("sqlalchemy.future", fromlist=["select"]).select(Booking).where(Booking.booking_id == booking_id)
    )
    booking = booking_res.scalars().first()
    if booking:
        await _require_property_access(booking.property_id, current_user, db)
    return detail


@router.patch(
    "/bookings/{booking_id}",
    response_model=schemas.BookingListItem,
    tags=["Manager - Bookings"],
    summary="Modify a booking (non-financial fields)",
)
async def modify_booking(
    booking_id: uuid.UUID,
    payload: schemas.BookingModifyRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Manager can update booking notes, status, and dates.
    Payment-related fields are Owner-only.
    """
    from app.infra.models import Booking
    from sqlalchemy.future import select as sa_select
    booking_res = await db.execute(sa_select(Booking).where(Booking.booking_id == booking_id))
    booking = booking_res.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    await _require_property_access(booking.property_id, current_user, db)
    return await service.modify_booking(db, booking_id, payload, current_user)


@router.post(
    "/bookings/{booking_id}/change-room",
    tags=["Manager - Bookings"],
    summary="Change the room for a booking",
)
async def change_room(
    booking_id: uuid.UUID,
    payload: schemas.ChangeRoomRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Move a booking to a different room within the same property."""
    from app.infra.models import Booking
    from sqlalchemy.future import select as sa_select
    booking_res = await db.execute(sa_select(Booking).where(Booking.booking_id == booking_id))
    booking = booking_res.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    await _require_property_access(booking.property_id, current_user, db)
    return await service.change_room(db, booking_id, payload, current_user)


@router.post(
    "/bookings/{booking_id}/confirm",
    tags=["Manager - Bookings"],
    summary="Confirm a pending booking",
)
async def confirm_booking(
    booking_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Confirm a booking that is in pending state."""
    from app.infra.models import Booking
    from sqlalchemy.future import select as sa_select
    booking_res = await db.execute(sa_select(Booking).where(Booking.booking_id == booking_id))
    booking = booking_res.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    await _require_property_access(booking.property_id, current_user, db)
    payload = schemas.BookingModifyRequest(booking_status="confirmed")
    return await service.modify_booking(db, booking_id, payload, current_user)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 5 — CHECK-IN MONITORING
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/checkins",
    response_model=List[schemas.CheckInFeedItem],
    tags=["Manager - Check-ins"],
    summary="Live check-in feed",
)
async def get_checkin_feed(
    property_id: uuid.UUID = Query(...),
    status_filter: Optional[str] = Query(None, description="active, checked_out"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Real-time feed of guest check-ins for this property."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_checkin_feed(db, property_id, status_filter)


@router.get(
    "/checkouts",
    response_model=List[schemas.CheckOutFeedItem],
    tags=["Manager - Check-ins"],
    summary="Check-out feed",
)
async def get_checkout_feed(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Feed of recent check-outs for this property."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_checkout_feed(db, property_id)


@router.get(
    "/rooms/readiness",
    response_model=List[schemas.RoomReadinessItem],
    tags=["Manager - Check-ins"],
    summary="Room readiness board",
)
async def get_room_readiness(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Shows all rooms with their occupancy status, housekeeping status,
    and whether they are currently blocked.
    """
    await _require_property_access(property_id, current_user, db)
    return await service.get_room_readiness(db, property_id)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 6 — HOUSEKEEPING DISPATCH
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/housekeeping",
    response_model=List[schemas.HousekeepingProgressItem],
    tags=["Manager - Housekeeping"],
    summary="View housekeeping task progress",
)
async def get_housekeeping_progress(
    property_id: uuid.UUID = Query(...),
    status_filter: Optional[str] = Query(None, description="pending, in_progress, completed, closed"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all housekeeping tasks with progress and staff assignments."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_housekeeping_progress(db, property_id, status_filter)


@router.post(
    "/housekeeping/assign",
    response_model=schemas.HousekeepingProgressItem,
    status_code=status.HTTP_201_CREATED,
    tags=["Manager - Housekeeping"],
    summary="Assign a cleaning or laundry task",
)
async def assign_housekeeping(
    payload: schemas.AssignCleaningRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Assign a cleaning or laundry task to a housekeeping staff member.

    Task type: cleaning | laundry | deep_clean
    """
    await _require_property_access(payload.property_id, current_user, db)
    return await service.assign_housekeeping(db, payload, current_user)


@router.patch(
    "/housekeeping/{task_id}/reassign",
    response_model=schemas.HousekeepingProgressItem,
    tags=["Manager - Housekeeping"],
    summary="Reassign a housekeeping task to another staff",
)
async def reassign_housekeeping(
    task_id: uuid.UUID,
    payload: schemas.ReassignTaskRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Reassign a pending or in-progress housekeeping task to another staff member."""
    from app.infra.models import HousekeepingTask
    from sqlalchemy.future import select as sa_select
    task_res = await db.execute(sa_select(HousekeepingTask).where(HousekeepingTask.task_id == task_id))
    task = task_res.scalars().first()
    if task:
        await _require_property_access(task.property_id, current_user, db)
    return await service.reassign_housekeeping(db, task_id, payload, current_user)


@router.post(
    "/housekeeping/{task_id}/inspect",
    tags=["Manager - Housekeeping"],
    summary="Inspect a completed housekeeping task",
)
async def inspect_task(
    task_id: uuid.UUID,
    payload: schemas.InspectionRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Manager inspects a completed housekeeping task.
    - Pass: moves to 'inspected' status
    - Fail: moves back to 'pending' for re-cleaning
    """
    from app.infra.models import HousekeepingTask
    from sqlalchemy.future import select as sa_select
    task_res = await db.execute(sa_select(HousekeepingTask).where(HousekeepingTask.task_id == task_id))
    task = task_res.scalars().first()
    if task:
        await _require_property_access(task.property_id, current_user, db)
    return await service.inspect_housekeeping_task(db, task_id, payload, current_user)


@router.post(
    "/housekeeping/{task_id}/close",
    tags=["Manager - Housekeeping"],
    summary="Close a housekeeping task (room becomes available)",
)
async def close_task(
    task_id: uuid.UUID,
    payload: schemas.CloseTaskRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Close a housekeeping task. This marks the room as clean and available.
    Must be called after inspection passes.
    """
    from app.infra.models import HousekeepingTask
    from sqlalchemy.future import select as sa_select
    task_res = await db.execute(sa_select(HousekeepingTask).where(HousekeepingTask.task_id == task_id))
    task = task_res.scalars().first()
    if task:
        await _require_property_access(task.property_id, current_user, db)
    return await service.close_housekeeping_task(db, task_id, payload, current_user)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 7 — MAINTENANCE
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/maintenance",
    response_model=List[schemas.MaintenanceTicketItem],
    tags=["Manager - Maintenance"],
    summary="List maintenance tickets",
)
async def list_maintenance(
    property_id: uuid.UUID = Query(...),
    status_filter: Optional[str] = Query(
        None, description="open, assigned, in_progress, resolved, closed"
    ),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List maintenance tickets. Filter by status for focused views."""
    await _require_property_access(property_id, current_user, db)
    return await service.list_maintenance_tickets(db, property_id, status_filter, skip, limit)


@router.post(
    "/maintenance",
    response_model=schemas.MaintenanceTicketItem,
    status_code=status.HTTP_201_CREATED,
    tags=["Manager - Maintenance"],
    summary="Create a maintenance issue",
)
async def create_maintenance(
    payload: schemas.MaintenanceCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Manager creates a maintenance issue.

    Workflow: Open → Assign → In Progress → Resolved → Closed → Room Available
    """
    await _require_property_access(payload.property_id, current_user, db)
    return await service.create_maintenance_issue(db, payload, current_user)


@router.post(
    "/maintenance/{ticket_id}/assign",
    response_model=schemas.MaintenanceTicketItem,
    tags=["Manager - Maintenance"],
    summary="Assign a technician to a maintenance ticket",
)
async def assign_maintenance(
    ticket_id: uuid.UUID,
    payload: schemas.MaintenanceAssignRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Assign a maintenance technician to an open ticket."""
    from app.infra.models import MaintenanceTicket
    from sqlalchemy.future import select as sa_select
    ticket_res = await db.execute(sa_select(MaintenanceTicket).where(MaintenanceTicket.ticket_id == ticket_id))
    ticket = ticket_res.scalars().first()
    if ticket:
        await _require_property_access(ticket.property_id, current_user, db)
    return await service.assign_maintenance_technician(db, ticket_id, payload, current_user)


@router.patch(
    "/maintenance/{ticket_id}",
    response_model=schemas.MaintenanceTicketItem,
    tags=["Manager - Maintenance"],
    summary="Update maintenance ticket status or priority",
)
async def update_maintenance(
    ticket_id: uuid.UUID,
    payload: schemas.MaintenanceUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update status, priority, or reassign a maintenance ticket."""
    from app.infra.models import MaintenanceTicket
    from sqlalchemy.future import select as sa_select
    ticket_res = await db.execute(sa_select(MaintenanceTicket).where(MaintenanceTicket.ticket_id == ticket_id))
    ticket = ticket_res.scalars().first()
    if ticket:
        await _require_property_access(ticket.property_id, current_user, db)
    return await service.update_maintenance_ticket(db, ticket_id, payload, current_user)


@router.post(
    "/maintenance/{ticket_id}/close",
    tags=["Manager - Maintenance"],
    summary="Close a maintenance issue (room auto-released)",
)
async def close_maintenance(
    ticket_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Manager closes a maintenance ticket.
    This automatically releases the room and marks it as available.
    """
    from app.infra.models import MaintenanceTicket
    from sqlalchemy.future import select as sa_select
    ticket_res = await db.execute(sa_select(MaintenanceTicket).where(MaintenanceTicket.ticket_id == ticket_id))
    ticket = ticket_res.scalars().first()
    if ticket:
        await _require_property_access(ticket.property_id, current_user, db)
    return await service.close_maintenance_issue(db, ticket_id, current_user)


# ══════════════════════════════════════════════════════════════════════════════
# PHASE 8 — REPORTS
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/reports/operational",
    response_model=schemas.OperationalReportResponse,
    tags=["Manager - Reports"],
    summary="Operational report",
)
async def operational_report(
    property_id: uuid.UUID = Query(...),
    from_date: date = Query(...),
    to_date: date = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Operational summary: bookings, check-ins, occupancy, tasks."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_operational_report(db, property_id, from_date, to_date)


@router.get(
    "/reports/occupancy",
    response_model=schemas.OccupancyReportResponse,
    tags=["Manager - Reports"],
    summary="Occupancy report",
)
async def occupancy_report(
    property_id: uuid.UUID = Query(...),
    from_date: date = Query(...),
    to_date: date = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Occupancy rates and trends for the given date range."""
    await _require_property_access(property_id, current_user, db)
    # Simplified occupancy report (delegates to operational report for now)
    op = await service.get_operational_report(db, property_id, from_date, to_date)
    return schemas.OccupancyReportResponse(
        property_id=property_id,
        from_date=from_date,
        to_date=to_date,
        avg_occupancy_percent=op.occupancy_percent,
    )


@router.get(
    "/reports/housekeeping",
    response_model=schemas.HousekeepingReportResponse,
    tags=["Manager - Reports"],
    summary="Housekeeping report",
)
async def housekeeping_report(
    property_id: uuid.UUID = Query(...),
    from_date: date = Query(...),
    to_date: date = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Housekeeping task completion rates and inspection pass rates."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_housekeeping_report(db, property_id, from_date, to_date)


@router.get(
    "/reports/maintenance",
    response_model=schemas.MaintenanceReportResponse,
    tags=["Manager - Reports"],
    summary="Maintenance report",
)
async def maintenance_report(
    property_id: uuid.UUID = Query(...),
    from_date: date = Query(...),
    to_date: date = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Maintenance tickets summary — open, resolved, avg resolution time."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_maintenance_report(db, property_id, from_date, to_date)


@router.get(
    "/reports/staff-performance",
    response_model=schemas.StaffPerformanceReportResponse,
    tags=["Manager - Reports"],
    summary="Staff performance report",
)
async def staff_performance_report(
    property_id: uuid.UUID = Query(...),
    from_date: date = Query(...),
    to_date: date = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Staff performance metrics for the given period."""
    await _require_property_access(property_id, current_user, db)
    return await service.get_staff_performance_report(db, property_id, from_date, to_date)


# ══════════════════════════════════════════════════════════════════════════════
# ROOM BLOCKS
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/room-blocks",
    response_model=List[schemas.RoomBlockResponse],
    tags=["Manager - Room Blocks"],
    summary="List room blocks",
)
async def list_room_blocks(
    property_id: uuid.UUID = Query(...),
    active_only: bool = Query(True, description="Return only active blocks"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all room blocks for this property."""
    await _require_property_access(property_id, current_user, db)
    return await service.list_room_blocks(db, property_id, active_only)


@router.post(
    "/room-blocks",
    response_model=schemas.RoomBlockResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Manager - Room Blocks"],
    summary="Block a room",
)
async def create_room_block(
    payload: schemas.RoomBlockCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Block a room for maintenance, renovation, VIP hold, inspection, or deep cleaning.
    Blocked rooms cannot be booked.
    """
    await _require_property_access(payload.property_id, current_user, db)
    return await service.create_room_block(db, payload, current_user)


@router.delete(
    "/room-blocks/{block_id}",
    tags=["Manager - Room Blocks"],
    summary="Release a room block",
)
async def release_room_block(
    block_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Release (deactivate) a room block.
    The room becomes available for booking again.
    """
    from app.modules.manager.models import RoomBlock
    from sqlalchemy.future import select as sa_select
    block_res = await db.execute(sa_select(RoomBlock).where(RoomBlock.block_id == block_id))
    block = block_res.scalars().first()
    if block:
        await _require_property_access(block.property_id, current_user, db)
    return await service.release_room_block(db, block_id, current_user)


# ══════════════════════════════════════════════════════════════════════════════
# MANAGER NOTES
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/notes",
    response_model=List[schemas.ManagerNoteResponse],
    tags=["Manager - Notes"],
    summary="List manager notes",
)
async def list_notes(
    property_id: uuid.UUID = Query(...),
    note_type: Optional[str] = Query(None),
    is_resolved: Optional[bool] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List manager notes. Pinned notes appear first."""
    await _require_property_access(property_id, current_user, db)
    return await service.list_manager_notes(db, property_id, note_type, is_resolved, skip, limit)


@router.post(
    "/notes",
    response_model=schemas.ManagerNoteResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Manager - Notes"],
    summary="Add a manager note",
)
async def add_note(
    payload: schemas.ManagerNoteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add an operational note. Can be pinned and linked to a room or booking."""
    await _require_property_access(payload.property_id, current_user, db)
    return await service.create_manager_note(db, payload, current_user)


@router.post(
    "/notes/{note_id}/resolve",
    tags=["Manager - Notes"],
    summary="Mark a manager note as resolved",
)
async def resolve_note(
    note_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Mark a note as resolved."""
    from app.modules.manager.models import ManagerNote
    from sqlalchemy.future import select as sa_select
    note_res = await db.execute(sa_select(ManagerNote).where(ManagerNote.note_id == note_id))
    note = note_res.scalars().first()
    if note:
        await _require_property_access(note.property_id, current_user, db)
    return await service.resolve_manager_note(db, note_id, current_user)


@router.delete(
    "/notes/{note_id}",
    tags=["Manager - Notes"],
    summary="Delete a manager note",
)
async def delete_note(
    note_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a note. Only the creator or a manager can delete."""
    from app.modules.manager.models import ManagerNote
    from sqlalchemy.future import select as sa_select
    note_res = await db.execute(sa_select(ManagerNote).where(ManagerNote.note_id == note_id))
    note = note_res.scalars().first()
    if note:
        await _require_property_access(note.property_id, current_user, db)
    return await service.delete_manager_note(db, note_id, current_user)


# ══════════════════════════════════════════════════════════════════════════════
# DAILY CHECKLISTS
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/checklists",
    response_model=List[schemas.ChecklistResponse],
    tags=["Manager - Checklists"],
    summary="List daily checklists",
)
async def list_checklists(
    property_id: uuid.UUID = Query(...),
    checklist_date: Optional[date] = Query(None),
    shift: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List daily checklists for this property."""
    await _require_property_access(property_id, current_user, db)
    return await service.list_checklists(db, property_id, checklist_date, shift)


@router.post(
    "/checklists",
    response_model=schemas.ChecklistResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Manager - Checklists"],
    summary="Start a daily checklist",
)
async def start_checklist(
    payload: schemas.ChecklistCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a daily operational checklist for a shift."""
    await _require_property_access(payload.property_id, current_user, db)
    return await service.create_checklist(db, payload, current_user)


@router.patch(
    "/checklists/{checklist_id}",
    response_model=schemas.ChecklistResponse,
    tags=["Manager - Checklists"],
    summary="Update checklist items",
)
async def update_checklist(
    checklist_id: uuid.UUID,
    payload: schemas.ChecklistUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Mark individual checklist items as complete."""
    from app.modules.manager.models import ManagerDailyChecklist
    from sqlalchemy.future import select as sa_select
    cl_res = await db.execute(sa_select(ManagerDailyChecklist).where(ManagerDailyChecklist.checklist_id == checklist_id))
    cl = cl_res.scalars().first()
    if cl:
        await _require_property_access(cl.property_id, current_user, db)
    return await service.update_checklist(db, checklist_id, payload, current_user)


@router.post(
    "/checklists/{checklist_id}/sign-off",
    response_model=schemas.ChecklistResponse,
    tags=["Manager - Checklists"],
    summary="Sign off on a completed checklist",
)
async def sign_off_checklist(
    checklist_id: uuid.UUID,
    payload: schemas.ChecklistSignOffRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Sign off on a completed daily checklist."""
    from app.modules.manager.models import ManagerDailyChecklist
    from sqlalchemy.future import select as sa_select
    cl_res = await db.execute(sa_select(ManagerDailyChecklist).where(ManagerDailyChecklist.checklist_id == checklist_id))
    cl = cl_res.scalars().first()
    if cl:
        await _require_property_access(cl.property_id, current_user, db)
    return await service.sign_off_checklist(db, checklist_id, payload, current_user)


# ══════════════════════════════════════════════════════════════════════════════
# SERVICE REQUESTS
# ══════════════════════════════════════════════════════════════════════════════

@router.get(
    "/service-requests",
    response_model=List[schemas.ServiceRequestListItem],
    tags=["Manager - Service Requests"],
    summary="List pending service requests",
)
async def list_service_requests(
    property_id: uuid.UUID = Query(...),
    status_filter: Optional[str] = Query(None, description="pending, assigned, in_progress, completed"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List service requests for this property."""
    await _require_property_access(property_id, current_user, db)
    return await service.list_service_requests(db, property_id, status_filter, skip, limit)


@router.post(
    "/service-requests/{request_id}/assign",
    tags=["Manager - Service Requests"],
    summary="Assign a service request to staff",
)
async def assign_service_request(
    request_id: uuid.UUID,
    payload: schemas.ServiceRequestAssignRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Assign a service request to a staff member."""
    from app.infra.models import ServiceRequest
    from sqlalchemy.future import select as sa_select
    sr_res = await db.execute(sa_select(ServiceRequest).where(ServiceRequest.request_id == request_id))
    sr = sr_res.scalars().first()
    if sr:
        await _require_property_access(sr.property_id, current_user, db)
    return await service.assign_service_request(db, request_id, payload, current_user)
