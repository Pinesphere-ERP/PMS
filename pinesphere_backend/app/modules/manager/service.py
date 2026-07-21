"""
Manager Module — Service Layer

All business logic for manager operations.
Controller (router) → Service → Repository (direct SQLAlchemy async queries) → Database
"""
from __future__ import annotations

import uuid
from datetime import date, datetime, timezone
from typing import Optional, List, Dict, Any, Tuple

from fastapi import HTTPException
from sqlalchemy import func, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.models import (
    User, Role, Room, Booking, CheckIn, CheckOut,
    HousekeepingTask, MaintenanceTicket, Task, TaskLog,
    Notification, AuditLog, ServiceRequest,
)
from app.modules.staff.models import (
    StaffAttendance, StaffPerformance,
)
from app.modules.manager.models import (
    ManagerNote, RoomBlock, ManagerDailyChecklist, StaffShift,
)
from app.modules.manager import schemas


# ── Helpers ───────────────────────────────────────────────────────────────────

async def _get_staff_role_code(db: AsyncSession, user: User) -> str:
    role_res = await db.execute(select(Role).where(Role.id == user.role_id))
    role = role_res.scalars().first()
    return role.role_code if role else ""


async def _require_manager_or_above(db: AsyncSession, user: User) -> None:
    role_code = await _get_staff_role_code(db, user)
    if role_code not in ("SUPER_ADMIN", "OWNER", "PROPERTY_MANAGER"):
        raise HTTPException(status_code=403, detail="Manager access required")


async def _create_in_app_notification(
    db: AsyncSession,
    recipient_id: uuid.UUID,
    title: str,
    message: str,
    priority: str = "normal",
    payload: Optional[dict] = None,
) -> None:
    """Fire-and-forget in-app notification. Errors are swallowed to not break the main flow."""
    try:
        notif = Notification(
            recipient_id=recipient_id,
            title=title,
            message=message,
            channel="in_app",
            priority=priority,
            status="unread",
            payload=payload or {},
        )
        db.add(notif)
    except Exception:
        pass


async def _write_audit_log(
    db: AsyncSession,
    *,
    property_id: uuid.UUID,
    user_id: uuid.UUID,
    module_name: str,
    action_type: str,
    target_entity: str,
    target_record_id: uuid.UUID,
    old_value: Optional[dict] = None,
    new_value: Optional[dict] = None,
) -> None:
    try:
        from app.modules.audit.logger import AuditLogger
        await AuditLogger.log(
            db,
            property_id=property_id,
            user_id=user_id,
            module_name=module_name,
            action_type=action_type,
            target_entity=target_entity,
            target_record_id=target_record_id,
            old_value=old_value,
            new_value=new_value,
        )
    except Exception:
        pass


# ── Phase 2: Dashboard ─────────────────────────────────────────────────────────

async def get_manager_dashboard(
    db: AsyncSession, property_id: uuid.UUID
) -> schemas.ManagerDashboardResponse:
    today = date.today()

    # Arrivals (bookings with check_in_date == today, confirmed)
    arrivals_q = await db.execute(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            Booking.check_in_date == today,
            Booking.booking_status.in_(["confirmed", "checked_in"]),
        )
    )
    arrivals = arrivals_q.scalar() or 0

    # Departures
    departures_q = await db.execute(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            Booking.check_out_date == today,
            Booking.booking_status.in_(["confirmed", "checked_in"]),
        )
    )
    departures = departures_q.scalar() or 0

    # Active check-ins
    checkin_q = await db.execute(
        select(func.count(CheckIn.checkin_id)).where(
            CheckIn.property_id == property_id,
            CheckIn.status == "active",
        )
    )
    active_checkins = checkin_q.scalar() or 0

    # Total rooms for occupancy
    rooms_q = await db.execute(
        select(func.count(Room.room_id)).where(Room.property_id == property_id)
    )
    total_rooms = rooms_q.scalar() or 1
    occupancy_percent = round((active_checkins / total_rooms) * 100, 1) if total_rooms else 0.0

    # Active tasks (pending + in_progress)
    active_tasks_q = await db.execute(
        select(func.count(Task.task_id)).where(
            Task.property_id == property_id,
            Task.status.in_(["pending", "accepted", "in_progress"]),
        )
    )
    active_tasks = active_tasks_q.scalar() or 0

    # Pending service requests
    pending_req_q = await db.execute(
        select(func.count(ServiceRequest.request_id)).where(
            ServiceRequest.property_id == property_id,
            ServiceRequest.status.in_(["pending", "assigned"]),
        )
    )
    pending_requests = pending_req_q.scalar() or 0

    # Today's maintenance (open + in_progress)
    maint_q = await db.execute(
        select(func.count(MaintenanceTicket.ticket_id)).where(
            MaintenanceTicket.property_id == property_id,
            MaintenanceTicket.status.in_(["open", "in_progress"]),
        )
    )
    today_maintenance = maint_q.scalar() or 0

    # Today's cleaning (pending + in_progress housekeeping)
    cleaning_q = await db.execute(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
            HousekeepingTask.status.in_(["pending", "in_progress"]),
        )
    )
    today_cleaning = cleaning_q.scalar() or 0

    # Active room blocks
    room_blocks_q = await db.execute(
        select(func.count(RoomBlock.block_id)).where(
            RoomBlock.property_id == property_id,
            RoomBlock.is_active == True,
            RoomBlock.from_date <= today,
            RoomBlock.to_date >= today,
        )
    )
    room_blocks_count = room_blocks_q.scalar() or 0

    # Staff on shift today
    on_shift_q = await db.execute(
        select(StaffShift).where(
            StaffShift.property_id == property_id,
            StaffShift.shift_date == today,
            StaffShift.status.in_(["scheduled", "active"]),
        )
    )
    shift_rows = on_shift_q.scalars().all()
    staff_on_shift = len(shift_rows)

    # Staff availability
    staff_q = await db.execute(
        select(User, Role).join(Role, Role.id == User.role_id).where(
            User.property_id == property_id,
            User.status == "ACTIVE",
        )
    )
    staff_rows = staff_q.all()
    shift_staff_ids = {s.staff_id for s in shift_rows}
    availability = [
        schemas.StaffAvailabilityItem(
            staff_id=s.id,
            name=s.name,
            role_code=r.role_code if r else None,
            shift_status="on_shift" if s.id in shift_staff_ids else "off_shift",
        )
        for s, r in staff_rows
    ]

    kpis = [
        schemas.DashboardKPI(name="Arrivals", value=str(arrivals), icon="LogIn"),
        schemas.DashboardKPI(name="Departures", value=str(departures), icon="LogOut"),
        schemas.DashboardKPI(name="Occupancy", value=f"{occupancy_percent}%", icon="BedDouble"),
        schemas.DashboardKPI(name="Active Tasks", value=str(active_tasks), icon="ClipboardList"),
        schemas.DashboardKPI(name="Pending Requests", value=str(pending_requests), icon="Bell"),
        schemas.DashboardKPI(name="Maintenance", value=str(today_maintenance), icon="Wrench"),
        schemas.DashboardKPI(name="Cleaning", value=str(today_cleaning), icon="Sparkles"),
        schemas.DashboardKPI(name="Room Blocks", value=str(room_blocks_count), icon="Lock"),
        schemas.DashboardKPI(name="Staff On Shift", value=str(staff_on_shift), icon="Users"),
    ]

    return schemas.ManagerDashboardResponse(
        date=str(today),
        kpis=kpis,
        arrivals=arrivals,
        departures=departures,
        occupancy_percent=occupancy_percent,
        active_tasks=active_tasks,
        pending_requests=pending_requests,
        today_maintenance=today_maintenance,
        today_cleaning=today_cleaning,
        room_blocks=room_blocks_count,
        staff_on_shift=staff_on_shift,
        staff_availability=availability,
    )


# ── Phase 3: Staff ─────────────────────────────────────────────────────────────

async def list_staff(
    db: AsyncSession, property_id: uuid.UUID
) -> List[schemas.StaffListItem]:
    today = date.today()
    staff_q = await db.execute(
        select(User, Role).join(Role, Role.id == User.role_id).where(
            User.property_id == property_id,
            User.status == "ACTIVE",
        )
    )
    rows = staff_q.all()

    # Get on-shift staff IDs for today
    shift_q = await db.execute(
        select(StaffShift.staff_id).where(
            StaffShift.property_id == property_id,
            StaffShift.shift_date == today,
            StaffShift.status.in_(["scheduled", "active"]),
        )
    )
    on_shift_ids = {r for r in shift_q.scalars().all()}

    return [
        schemas.StaffListItem(
            id=u.id,
            name=u.name,
            email=u.email,
            mobile_number=u.mobile_number,
            role_id=u.role_id,
            role_code=r.role_code if r else None,
            status=u.status,
            on_shift_today=u.id in on_shift_ids,
        )
        for u, r in rows
    ]


async def get_attendance(
    db: AsyncSession,
    property_id: uuid.UUID,
    attendance_date: Optional[date] = None,
    staff_id: Optional[uuid.UUID] = None,
) -> List[schemas.AttendanceRecord]:
    filters = [StaffAttendance.property_id == property_id]
    if attendance_date:
        filters.append(StaffAttendance.attendance_date == attendance_date)
    if staff_id:
        filters.append(StaffAttendance.staff_id == staff_id)

    q = await db.execute(
        select(StaffAttendance, User)
        .join(User, User.id == StaffAttendance.staff_id)
        .where(*filters)
        .order_by(StaffAttendance.attendance_date.desc())
    )
    rows = q.all()
    return [
        schemas.AttendanceRecord(
            attendance_id=a.attendance_id,
            staff_id=a.staff_id,
            staff_name=u.name,
            property_id=a.property_id,
            attendance_date=a.attendance_date,
            check_in_time=a.check_in_time,
            check_out_time=a.check_out_time,
            status=a.status,
            remarks=a.remarks,
        )
        for a, u in rows
    ]


async def get_performance(
    db: AsyncSession,
    property_id: uuid.UUID,
    staff_id: Optional[uuid.UUID] = None,
) -> List[schemas.PerformanceRecord]:
    # Performance records are in staff_performance; property_id comes via the user
    # We join User to filter by property
    filters = [User.property_id == property_id]
    if staff_id:
        filters.append(StaffPerformance.staff_id == staff_id)

    q = await db.execute(
        select(StaffPerformance, User)
        .join(User, User.id == StaffPerformance.staff_id)
        .where(*filters)
        .order_by(StaffPerformance.review_date.desc())
        .limit(200)
    )
    rows = q.all()
    return [
        schemas.PerformanceRecord(
            performance_id=p.performance_id,
            staff_id=p.staff_id,
            staff_name=u.name,
            review_period_start=p.review_period_start,
            review_period_end=p.review_period_end,
            rating=p.rating,
            attendance_score=p.attendance_score,
            task_completion_score=p.task_completion_score,
            remarks=p.remarks,
        )
        for p, u in rows
    ]


async def assign_task(
    db: AsyncSession,
    payload: schemas.TaskAssignRequest,
    current_user: User,
) -> schemas.TaskAssignResponse:
    """Assign a task to an active staff member from the same property."""
    # Fetch task
    task_res = await db.execute(
        select(Task).where(Task.task_id == payload.task_id)
    )
    task = task_res.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Verify task belongs to same property
    if task.property_id != payload.property_id:
        raise HTTPException(
            status_code=403,
            detail="Task does not belong to this property.",
        )

    # Validate staff member
    staff_res = await db.execute(
        select(User).where(
            User.id == payload.assigned_to,
            User.property_id == payload.property_id,
            User.status == "ACTIVE",
        )
    )
    staff_member = staff_res.scalars().first()
    if not staff_member:
        raise HTTPException(
            status_code=422,
            detail=(
                "Staff member not found in this property or is inactive. "
                "Cross-property assignment is not permitted."
            ),
        )

    old_assigned = task.assigned_to
    task.assigned_to = payload.assigned_to
    if payload.due_at:
        task.due_at = payload.due_at
    if payload.priority:
        task.priority = payload.priority
    task.status = "pending"

    # Task log entry
    log = TaskLog(
        task_id=task.task_id,
        user_id=current_user.id,
        old_status=task.status,
        new_status="pending",
        notes=f"Assigned to {staff_member.name} by manager {current_user.name}",
    )
    db.add(log)

    # In-app notification to assignee
    await _create_in_app_notification(
        db,
        recipient_id=payload.assigned_to,
        title="Task Assigned",
        message=f"You have been assigned a new task by {current_user.name}.",
        priority="normal",
        payload={"task_id": str(task.task_id)},
    )

    # Audit
    await _write_audit_log(
        db,
        property_id=payload.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="TASK_ASSIGNED",
        target_entity="tasks",
        target_record_id=task.task_id,
        old_value={"assigned_to": str(old_assigned)} if old_assigned else None,
        new_value={"assigned_to": str(payload.assigned_to)},
    )

    return schemas.TaskAssignResponse(
        message="Task assigned successfully.",
        task_id=str(task.task_id),
    )


async def create_staff_shift(
    db: AsyncSession,
    payload: schemas.StaffShiftCreate,
    current_user: User,
) -> schemas.StaffShiftResponse:
    # Validate staff belongs to this property
    staff_res = await db.execute(
        select(User).where(
            User.id == payload.staff_id,
            User.property_id == payload.property_id,
            User.status == "ACTIVE",
        )
    )
    if not staff_res.scalars().first():
        raise HTTPException(status_code=422, detail="Staff not found in this property")

    shift = StaffShift(
        property_id=payload.property_id,
        staff_id=payload.staff_id,
        shift_date=payload.shift_date,
        shift_type=payload.shift_type,
        start_time=payload.start_time,
        end_time=payload.end_time,
        status="scheduled",
        scheduled_by=current_user.id,
        notes=payload.notes,
    )
    db.add(shift)
    return schemas.StaffShiftResponse(
        shift_id=shift.shift_id,
        property_id=shift.property_id,
        staff_id=shift.staff_id,
        shift_date=shift.shift_date,
        shift_type=shift.shift_type,
        status=shift.status,
        start_time=shift.start_time,
        end_time=shift.end_time,
    )


async def get_shifts(
    db: AsyncSession,
    property_id: uuid.UUID,
    shift_date: Optional[date] = None,
    staff_id: Optional[uuid.UUID] = None,
) -> List[schemas.StaffShiftResponse]:
    filters = [StaffShift.property_id == property_id]
    if shift_date:
        filters.append(StaffShift.shift_date == shift_date)
    if staff_id:
        filters.append(StaffShift.staff_id == staff_id)

    q = await db.execute(
        select(StaffShift).where(*filters).order_by(StaffShift.shift_date.desc())
    )
    rows = q.scalars().all()
    return [
        schemas.StaffShiftResponse(
            shift_id=s.shift_id,
            property_id=s.property_id,
            staff_id=s.staff_id,
            shift_date=s.shift_date,
            shift_type=s.shift_type,
            status=s.status,
            start_time=s.start_time,
            end_time=s.end_time,
            created_at=s.created_at,
        )
        for s in rows
    ]


# ── Phase 4: Booking Oversight ─────────────────────────────────────────────────

async def list_bookings(
    db: AsyncSession,
    property_id: uuid.UUID,
    status_filter: Optional[str] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    skip: int = 0,
    limit: int = 50,
) -> List[schemas.BookingListItem]:
    from app.infra.models import Guest
    filters = [Booking.property_id == property_id]
    if status_filter:
        filters.append(Booking.booking_status == status_filter)
    if from_date:
        filters.append(Booking.check_in_date >= from_date)
    if to_date:
        filters.append(Booking.check_out_date <= to_date)

    q = await db.execute(
        select(Booking, Guest, Room)
        .join(Guest, Guest.guest_id == Booking.guest_id)
        .join(Room, Room.room_id == Booking.room_id)
        .where(*filters)
        .order_by(Booking.check_in_date.desc())
        .offset(skip)
        .limit(limit)
    )
    rows = q.all()
    return [
        schemas.BookingListItem(
            booking_id=b.booking_id,
            room_id=b.room_id,
            room_number=r.room_number,
            guest_id=b.guest_id,
            guest_name=g.full_name,
            guest_mobile=g.mobile,
            check_in_date=b.check_in_date,
            check_out_date=b.check_out_date,
            adults=b.adults,
            children=b.children,
            booking_status=b.booking_status,
            payment_status=b.payment_status,
            booking_source=b.booking_source,
            total_payable=float(b.total_payable) if b.total_payable else None,
        )
        for b, g, r in rows
    ]


async def get_booking_detail(
    db: AsyncSession, booking_id: uuid.UUID
) -> schemas.BookingListItem:
    from app.infra.models import Guest
    q = await db.execute(
        select(Booking, Guest, Room)
        .join(Guest, Guest.guest_id == Booking.guest_id)
        .join(Room, Room.room_id == Booking.room_id)
        .where(Booking.booking_id == booking_id)
    )
    row = q.first()
    if not row:
        raise HTTPException(status_code=404, detail="Booking not found")
    b, g, r = row
    return schemas.BookingListItem(
        booking_id=b.booking_id,
        room_id=b.room_id,
        room_number=r.room_number,
        guest_id=b.guest_id,
        guest_name=g.full_name,
        guest_mobile=g.mobile,
        check_in_date=b.check_in_date,
        check_out_date=b.check_out_date,
        adults=b.adults,
        children=b.children,
        booking_status=b.booking_status,
        payment_status=b.payment_status,
        booking_source=b.booking_source,
        total_payable=float(b.total_payable) if b.total_payable else None,
    )


async def modify_booking(
    db: AsyncSession,
    booking_id: uuid.UUID,
    payload: schemas.BookingModifyRequest,
    current_user: User,
) -> schemas.BookingListItem:
    booking_res = await db.execute(
        select(Booking).where(Booking.booking_id == booking_id)
    )
    booking = booking_res.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    old_snapshot = {
        "booking_status": booking.booking_status,
        "notes": booking.notes,
        "check_in_date": str(booking.check_in_date),
        "check_out_date": str(booking.check_out_date),
    }

    if payload.notes is not None:
        booking.notes = payload.notes
    if payload.booking_status is not None:
        booking.booking_status = payload.booking_status
    if payload.check_in_date is not None:
        booking.check_in_date = payload.check_in_date
    if payload.check_out_date is not None:
        booking.check_out_date = payload.check_out_date

    await _write_audit_log(
        db,
        property_id=booking.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="BOOKING_MODIFIED",
        target_entity="bookings",
        target_record_id=booking_id,
        old_value=old_snapshot,
        new_value={
            "booking_status": booking.booking_status,
            "notes": booking.notes,
        },
    )

    return await get_booking_detail(db, booking_id)


async def change_room(
    db: AsyncSession,
    booking_id: uuid.UUID,
    payload: schemas.ChangeRoomRequest,
    current_user: User,
) -> Dict[str, Any]:
    booking_res = await db.execute(
        select(Booking).where(Booking.booking_id == booking_id)
    )
    booking = booking_res.scalars().first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Validate new room belongs to same property
    room_res = await db.execute(
        select(Room).where(
            Room.room_id == payload.new_room_id,
            Room.property_id == booking.property_id,
        )
    )
    new_room = room_res.scalars().first()
    if not new_room:
        raise HTTPException(status_code=404, detail="Room not found in this property")

    old_room_id = booking.room_id
    booking.room_id = payload.new_room_id

    await _write_audit_log(
        db,
        property_id=booking.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="ROOM_CHANGED",
        target_entity="bookings",
        target_record_id=booking_id,
        old_value={"room_id": str(old_room_id)},
        new_value={"room_id": str(payload.new_room_id), "room_number": new_room.room_number},
    )

    return {
        "message": "Room changed successfully.",
        "booking_id": str(booking_id),
        "new_room_id": str(payload.new_room_id),
        "new_room_number": new_room.room_number,
    }


# ── Phase 5: Check-in Monitoring ──────────────────────────────────────────────

async def get_checkin_feed(
    db: AsyncSession, property_id: uuid.UUID, status_filter: Optional[str] = None
) -> List[schemas.CheckInFeedItem]:
    from app.infra.models import Guest
    filters = [CheckIn.property_id == property_id]
    if status_filter:
        filters.append(CheckIn.status == status_filter)

    q = await db.execute(
        select(CheckIn, Guest, Room)
        .join(Guest, Guest.guest_id == CheckIn.guest_id)
        .join(Room, Room.room_id == CheckIn.room_id)
        .where(*filters)
        .order_by(CheckIn.checked_in_at.desc())
        .limit(100)
    )
    rows = q.all()
    return [
        schemas.CheckInFeedItem(
            checkin_id=ci.checkin_id,
            booking_id=ci.booking_id,
            room_id=ci.room_id,
            room_number=r.room_number,
            guest_id=ci.guest_id,
            guest_name=g.full_name,
            checked_in_at=ci.checked_in_at,
            status=ci.status,
        )
        for ci, g, r in rows
    ]


async def get_checkout_feed(
    db: AsyncSession, property_id: uuid.UUID
) -> List[schemas.CheckOutFeedItem]:
    q = await db.execute(
        select(CheckOut, Room)
        .join(Room, Room.room_id == CheckOut.room_id)
        .where(CheckOut.property_id == property_id)
        .order_by(CheckOut.checkout_time.desc())
        .limit(100)
    )
    rows = q.all()
    return [
        schemas.CheckOutFeedItem(
            checkout_id=co.checkout_id,
            checkin_id=co.checkin_id,
            booking_id=co.booking_id,
            room_id=co.room_id,
            room_number=r.room_number,
            checkout_time=co.checkout_time,
            checkout_status=co.checkout_status,
            payment_status=co.payment_status,
        )
        for co, r in rows
    ]


async def get_room_readiness(
    db: AsyncSession, property_id: uuid.UUID
) -> List[schemas.RoomReadinessItem]:
    today = date.today()
    q = await db.execute(
        select(Room).where(Room.property_id == property_id).order_by(Room.room_number)
    )
    rooms = q.scalars().all()

    # Get active blocks
    blocks_q = await db.execute(
        select(RoomBlock.room_id, RoomBlock.reason).where(
            RoomBlock.property_id == property_id,
            RoomBlock.is_active == True,
            RoomBlock.from_date <= today,
            RoomBlock.to_date >= today,
        )
    )
    blocked = {r: reason for r, reason in blocks_q.all()}

    return [
        schemas.RoomReadinessItem(
            room_id=r.room_id,
            room_number=r.room_number,
            occupancy_status=r.occupancy_status or "vacant",
            housekeeping_status=r.housekeeping_status or "clean",
            is_blocked=r.room_id in blocked,
            block_reason=blocked.get(r.room_id),
        )
        for r in rooms
    ]


# ── Phase 6: Housekeeping Dispatch ────────────────────────────────────────────

async def assign_housekeeping(
    db: AsyncSession,
    payload: schemas.AssignCleaningRequest,
    current_user: User,
) -> schemas.HousekeepingProgressItem:
    """Assign a cleaning or laundry task to a staff member."""
    # Validate room belongs to property
    room_res = await db.execute(
        select(Room).where(
            Room.room_id == payload.room_id,
            Room.property_id == payload.property_id,
        )
    )
    room = room_res.scalars().first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    # Validate staff is active and in this property
    staff_res = await db.execute(
        select(User).where(
            User.id == payload.assigned_staff_id,
            User.property_id == payload.property_id,
            User.status == "ACTIVE",
        )
    )
    staff = staff_res.scalars().first()
    if not staff:
        raise HTTPException(status_code=422, detail="Staff not found or inactive")

    task = HousekeepingTask(
        property_id=payload.property_id,
        room_id=payload.room_id,
        assigned_staff_id=payload.assigned_staff_id,
        status="pending",
        priority=payload.priority or "medium",
        remarks=payload.remarks,
    )
    # HousekeepingTask doesn't have task_type in base model; store in remarks prefix
    db.add(task)

    await _create_in_app_notification(
        db,
        recipient_id=payload.assigned_staff_id,
        title="Cleaning Task Assigned",
        message=f"You have been assigned a {payload.task_type} task for Room {room.room_number}.",
        payload={"task_id": str(task.task_id), "room_number": room.room_number},
    )

    await _write_audit_log(
        db,
        property_id=payload.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="HK_TASK_ASSIGNED",
        target_entity="housekeeping_tasks",
        target_record_id=task.task_id,
        new_value={"room_id": str(payload.room_id), "assigned_to": str(payload.assigned_staff_id)},
    )

    return schemas.HousekeepingProgressItem(
        task_id=task.task_id,
        room_id=task.room_id,
        room_number=room.room_number,
        task_type=payload.task_type,
        status=task.status,
        priority=task.priority,
        assigned_staff_id=task.assigned_staff_id,
        assigned_staff_name=staff.name,
    )


async def reassign_housekeeping(
    db: AsyncSession,
    task_id: uuid.UUID,
    payload: schemas.ReassignTaskRequest,
    current_user: User,
) -> schemas.HousekeepingProgressItem:
    task_res = await db.execute(
        select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    )
    task = task_res.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Housekeeping task not found")

    staff_res = await db.execute(
        select(User).where(
            User.id == payload.new_staff_id,
            User.property_id == task.property_id,
            User.status == "ACTIVE",
        )
    )
    staff = staff_res.scalars().first()
    if not staff:
        raise HTTPException(status_code=422, detail="Staff not found or inactive in this property")

    old_staff = task.assigned_staff_id
    task.assigned_staff_id = payload.new_staff_id

    room_res = await db.execute(select(Room).where(Room.room_id == task.room_id))
    room = room_res.scalars().first()

    await _create_in_app_notification(
        db,
        recipient_id=payload.new_staff_id,
        title="Task Reassigned to You",
        message=f"A housekeeping task for Room {room.room_number if room else ''} has been assigned to you.",
        payload={"task_id": str(task_id)},
    )

    await _write_audit_log(
        db,
        property_id=task.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="HK_TASK_REASSIGNED",
        target_entity="housekeeping_tasks",
        target_record_id=task_id,
        old_value={"assigned_staff_id": str(old_staff)},
        new_value={"assigned_staff_id": str(payload.new_staff_id)},
    )

    return schemas.HousekeepingProgressItem(
        task_id=task.task_id,
        room_id=task.room_id,
        room_number=room.room_number if room else None,
        status=task.status,
        priority=task.priority,
        assigned_staff_id=task.assigned_staff_id,
        assigned_staff_name=staff.name,
    )


async def get_housekeeping_progress(
    db: AsyncSession, property_id: uuid.UUID, status_filter: Optional[str] = None
) -> List[schemas.HousekeepingProgressItem]:
    filters = [HousekeepingTask.property_id == property_id]
    if status_filter:
        filters.append(HousekeepingTask.status == status_filter)

    q = await db.execute(
        select(HousekeepingTask, Room)
        .join(Room, Room.room_id == HousekeepingTask.room_id)
        .where(*filters)
        .order_by(HousekeepingTask.created_at.asc())
        .limit(200)
    )
    rows = q.all()

    # Batch load staff names
    staff_ids = {t.assigned_staff_id for t, _ in rows if t.assigned_staff_id}
    staff_map: Dict[uuid.UUID, str] = {}
    if staff_ids:
        sq = await db.execute(select(User).where(User.id.in_(staff_ids)))
        for s in sq.scalars().all():
            staff_map[s.id] = s.name

    return [
        schemas.HousekeepingProgressItem(
            task_id=t.task_id,
            room_id=t.room_id,
            room_number=r.room_number,
            status=t.status,
            priority=t.priority,
            assigned_staff_id=t.assigned_staff_id,
            assigned_staff_name=staff_map.get(t.assigned_staff_id),
            created_at=t.created_at,
            completed_at=t.completed_at,
        )
        for t, r in rows
    ]


async def inspect_housekeeping_task(
    db: AsyncSession,
    task_id: uuid.UUID,
    payload: schemas.InspectionRequest,
    current_user: User,
) -> Dict[str, Any]:
    task_res = await db.execute(
        select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    )
    task = task_res.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    old_status = task.status
    task.checklist_status = {
        **(task.checklist_status or {}),
        "inspection_result": payload.inspection_result,
        "inspection_remarks": payload.inspection_remarks,
        "inspected_by": str(current_user.id),
        "inspected_at": datetime.utcnow().isoformat(),
    }

    if payload.inspection_result == "pass":
        task.status = "inspected"
    else:
        task.status = "pending"  # Re-open for re-cleaning

    await _write_audit_log(
        db,
        property_id=task.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="HK_TASK_INSPECTED",
        target_entity="housekeeping_tasks",
        target_record_id=task_id,
        old_value={"status": old_status},
        new_value={"status": task.status, "inspection_result": payload.inspection_result},
    )

    return {"message": "Inspection recorded.", "task_id": str(task_id), "result": payload.inspection_result}


async def close_housekeeping_task(
    db: AsyncSession,
    task_id: uuid.UUID,
    payload: schemas.CloseTaskRequest,
    current_user: User,
) -> Dict[str, Any]:
    task_res = await db.execute(
        select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    )
    task = task_res.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    old_status = task.status
    task.status = "closed"
    task.completed_at = datetime.now(timezone.utc)
    if payload.remarks:
        task.remarks = payload.remarks

    # When housekeeping closes, mark room as available (clean)
    room_res = await db.execute(select(Room).where(Room.room_id == task.room_id))
    room = room_res.scalars().first()
    if room:
        room.housekeeping_status = "clean"

    await _write_audit_log(
        db,
        property_id=task.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="HK_TASK_CLOSED",
        target_entity="housekeeping_tasks",
        target_record_id=task_id,
        old_value={"status": old_status},
        new_value={"status": "closed"},
    )

    return {"message": "Task closed. Room marked clean.", "task_id": str(task_id)}


# ── Phase 7: Maintenance ───────────────────────────────────────────────────────

async def create_maintenance_issue(
    db: AsyncSession,
    payload: schemas.MaintenanceCreateRequest,
    current_user: User,
) -> schemas.MaintenanceTicketItem:
    room_res = await db.execute(
        select(Room).where(
            Room.room_id == payload.room_id,
            Room.property_id == payload.property_id,
        )
    )
    room = room_res.scalars().first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    ticket = MaintenanceTicket(
        property_id=payload.property_id,
        room_id=payload.room_id,
        reported_by=current_user.id,
        assigned_to=payload.assigned_to,
        category=payload.category,
        priority=payload.priority,
        issue_description=payload.issue_description,
        status="open",
    )
    db.add(ticket)

    # Notify assignee if provided
    if payload.assigned_to:
        await _create_in_app_notification(
            db,
            recipient_id=payload.assigned_to,
            title="Maintenance Ticket Assigned",
            message=f"A {payload.category} maintenance issue has been assigned to you for Room {room.room_number}.",
            priority="high",
            payload={"ticket_id": str(ticket.ticket_id)},
        )

    await _write_audit_log(
        db,
        property_id=payload.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="MAINTENANCE_CREATED",
        target_entity="maintenance_tickets",
        target_record_id=ticket.ticket_id,
        new_value={"category": payload.category, "room_id": str(payload.room_id)},
    )

    return schemas.MaintenanceTicketItem(
        ticket_id=ticket.ticket_id,
        room_id=ticket.room_id,
        room_number=room.room_number,
        property_id=ticket.property_id,
        category=ticket.category,
        priority=ticket.priority,
        issue_description=ticket.issue_description,
        status=ticket.status,
        assigned_to=ticket.assigned_to,
        reported_by=ticket.reported_by,
    )


async def list_maintenance_tickets(
    db: AsyncSession,
    property_id: uuid.UUID,
    status_filter: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
) -> List[schemas.MaintenanceTicketItem]:
    filters = [MaintenanceTicket.property_id == property_id]
    if status_filter:
        filters.append(MaintenanceTicket.status == status_filter)

    q = await db.execute(
        select(MaintenanceTicket, Room)
        .join(Room, Room.room_id == MaintenanceTicket.room_id)
        .where(*filters)
        .order_by(MaintenanceTicket.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    rows = q.all()

    # Batch staff names
    staff_ids = set()
    for t, _ in rows:
        if t.assigned_to:
            staff_ids.add(t.assigned_to)
        if t.reported_by:
            staff_ids.add(t.reported_by)
    staff_map: Dict[uuid.UUID, str] = {}
    if staff_ids:
        sq = await db.execute(select(User).where(User.id.in_(staff_ids)))
        for s in sq.scalars().all():
            staff_map[s.id] = s.name

    return [
        schemas.MaintenanceTicketItem(
            ticket_id=t.ticket_id,
            room_id=t.room_id,
            room_number=r.room_number,
            property_id=t.property_id,
            category=t.category,
            priority=t.priority,
            issue_description=t.issue_description,
            status=t.status,
            assigned_to=t.assigned_to,
            assigned_to_name=staff_map.get(t.assigned_to) if t.assigned_to else None,
            reported_by=t.reported_by,
            reported_by_name=staff_map.get(t.reported_by) if t.reported_by else None,
            created_at=t.created_at,
            resolved_at=t.resolved_at,
        )
        for t, r in rows
    ]


async def assign_maintenance_technician(
    db: AsyncSession,
    ticket_id: uuid.UUID,
    payload: schemas.MaintenanceAssignRequest,
    current_user: User,
) -> schemas.MaintenanceTicketItem:
    ticket_res = await db.execute(
        select(MaintenanceTicket).where(MaintenanceTicket.ticket_id == ticket_id)
    )
    ticket = ticket_res.scalars().first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Maintenance ticket not found")

    # Validate technician
    tech_res = await db.execute(
        select(User).where(
            User.id == payload.assigned_to,
            User.property_id == ticket.property_id,
            User.status == "ACTIVE",
        )
    )
    tech = tech_res.scalars().first()
    if not tech:
        raise HTTPException(status_code=422, detail="Technician not found in this property")

    old_assigned = ticket.assigned_to
    ticket.assigned_to = payload.assigned_to
    ticket.status = "assigned"

    await _create_in_app_notification(
        db,
        recipient_id=payload.assigned_to,
        title="Maintenance Ticket Assigned",
        message=f"Maintenance ticket (ID: {str(ticket_id)[:8]}) has been assigned to you.",
        priority="high",
        payload={"ticket_id": str(ticket_id)},
    )

    await _write_audit_log(
        db,
        property_id=ticket.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="MAINTENANCE_ASSIGNED",
        target_entity="maintenance_tickets",
        target_record_id=ticket_id,
        old_value={"assigned_to": str(old_assigned)} if old_assigned else None,
        new_value={"assigned_to": str(payload.assigned_to)},
    )

    room_res = await db.execute(select(Room).where(Room.room_id == ticket.room_id))
    room = room_res.scalars().first()

    return schemas.MaintenanceTicketItem(
        ticket_id=ticket.ticket_id,
        room_id=ticket.room_id,
        room_number=room.room_number if room else None,
        property_id=ticket.property_id,
        category=ticket.category,
        priority=ticket.priority,
        issue_description=ticket.issue_description,
        status=ticket.status,
        assigned_to=ticket.assigned_to,
        assigned_to_name=tech.name,
        reported_by=ticket.reported_by,
        created_at=ticket.created_at,
    )


async def update_maintenance_ticket(
    db: AsyncSession,
    ticket_id: uuid.UUID,
    payload: schemas.MaintenanceUpdateRequest,
    current_user: User,
) -> schemas.MaintenanceTicketItem:
    ticket_res = await db.execute(
        select(MaintenanceTicket).where(MaintenanceTicket.ticket_id == ticket_id)
    )
    ticket = ticket_res.scalars().first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Maintenance ticket not found")

    old_snapshot = {"status": ticket.status}
    if payload.status:
        ticket.status = payload.status
        if payload.status in ("resolved", "closed"):
            ticket.resolved_at = datetime.now(timezone.utc)
    if payload.assigned_to:
        ticket.assigned_to = payload.assigned_to
    if payload.priority:
        ticket.priority = payload.priority

    await _write_audit_log(
        db,
        property_id=ticket.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="MAINTENANCE_UPDATED",
        target_entity="maintenance_tickets",
        target_record_id=ticket_id,
        old_value=old_snapshot,
        new_value={"status": ticket.status},
    )

    return await _maintenance_ticket_to_schema(db, ticket)


async def close_maintenance_issue(
    db: AsyncSession, ticket_id: uuid.UUID, current_user: User
) -> Dict[str, Any]:
    ticket_res = await db.execute(
        select(MaintenanceTicket).where(MaintenanceTicket.ticket_id == ticket_id)
    )
    ticket = ticket_res.scalars().first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    old_status = ticket.status
    ticket.status = "closed"
    ticket.resolved_at = datetime.now(timezone.utc)

    # Auto-release room: mark as available
    room_res = await db.execute(select(Room).where(Room.room_id == ticket.room_id))
    room = room_res.scalars().first()
    if room:
        room.occupancy_status = "vacant"
        room.housekeeping_status = "clean"

    # Notify owner/receptionist
    await _create_in_app_notification(
        db,
        recipient_id=current_user.id,
        title="Maintenance Closed",
        message=f"Maintenance ticket for Room {room.room_number if room else ''} has been closed and room is now available.",
        payload={"ticket_id": str(ticket_id)},
    )

    await _write_audit_log(
        db,
        property_id=ticket.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="MAINTENANCE_CLOSED",
        target_entity="maintenance_tickets",
        target_record_id=ticket_id,
        old_value={"status": old_status},
        new_value={"status": "closed", "room_released": True},
    )

    return {
        "message": "Maintenance ticket closed. Room auto-released.",
        "ticket_id": str(ticket_id),
        "room_number": room.room_number if room else None,
    }


async def _maintenance_ticket_to_schema(
    db: AsyncSession, ticket: MaintenanceTicket
) -> schemas.MaintenanceTicketItem:
    room_res = await db.execute(select(Room).where(Room.room_id == ticket.room_id))
    room = room_res.scalars().first()
    return schemas.MaintenanceTicketItem(
        ticket_id=ticket.ticket_id,
        room_id=ticket.room_id,
        room_number=room.room_number if room else None,
        property_id=ticket.property_id,
        category=ticket.category,
        priority=ticket.priority,
        issue_description=ticket.issue_description,
        status=ticket.status,
        assigned_to=ticket.assigned_to,
        reported_by=ticket.reported_by,
        created_at=ticket.created_at,
        resolved_at=ticket.resolved_at,
    )


# ── Phase 8: Reports ───────────────────────────────────────────────────────────

async def get_operational_report(
    db: AsyncSession, property_id: uuid.UUID, from_date: date, to_date: date
) -> schemas.OperationalReportResponse:
    total_bookings = (await db.execute(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            Booking.check_in_date >= from_date,
            Booking.check_in_date <= to_date,
        )
    )).scalar() or 0

    confirmed = (await db.execute(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            Booking.check_in_date >= from_date,
            Booking.check_in_date <= to_date,
            Booking.booking_status == "confirmed",
        )
    )).scalar() or 0

    cancelled = (await db.execute(
        select(func.count(Booking.booking_id)).where(
            Booking.property_id == property_id,
            Booking.check_in_date >= from_date,
            Booking.check_in_date <= to_date,
            Booking.booking_status == "cancelled",
        )
    )).scalar() or 0

    total_checkins = (await db.execute(
        select(func.count(CheckIn.checkin_id)).where(
            CheckIn.property_id == property_id,
            CheckIn.checked_in_at >= datetime.combine(from_date, datetime.min.time()),
            CheckIn.checked_in_at <= datetime.combine(to_date, datetime.max.time()),
        )
    )).scalar() or 0

    total_checkouts = (await db.execute(
        select(func.count(CheckOut.checkout_id)).where(
            CheckOut.property_id == property_id,
        )
    )).scalar() or 0

    hk_completed = (await db.execute(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
            HousekeepingTask.status.in_(["completed", "closed"]),
        )
    )).scalar() or 0

    mt_resolved = (await db.execute(
        select(func.count(MaintenanceTicket.ticket_id)).where(
            MaintenanceTicket.property_id == property_id,
            MaintenanceTicket.status.in_(["resolved", "closed"]),
        )
    )).scalar() or 0

    mt_open = (await db.execute(
        select(func.count(MaintenanceTicket.ticket_id)).where(
            MaintenanceTicket.property_id == property_id,
            MaintenanceTicket.status.in_(["open", "assigned", "in_progress"]),
        )
    )).scalar() or 0

    total_rooms = (await db.execute(
        select(func.count(Room.room_id)).where(Room.property_id == property_id)
    )).scalar() or 1

    days = max((to_date - from_date).days, 1)
    occupancy_pct = round((total_checkins / (total_rooms * days)) * 100, 1)

    return schemas.OperationalReportResponse(
        property_id=property_id,
        from_date=from_date,
        to_date=to_date,
        total_bookings=total_bookings,
        confirmed_bookings=confirmed,
        cancelled_bookings=cancelled,
        total_check_ins=total_checkins,
        total_check_outs=total_checkouts,
        occupancy_percent=min(occupancy_pct, 100.0),
        housekeeping_tasks_completed=hk_completed,
        maintenance_tickets_resolved=mt_resolved,
        open_maintenance_tickets=mt_open,
    )


async def get_housekeeping_report(
    db: AsyncSession, property_id: uuid.UUID, from_date: date, to_date: date
) -> schemas.HousekeepingReportResponse:
    total = (await db.execute(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
        )
    )).scalar() or 0

    completed = (await db.execute(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
            HousekeepingTask.status.in_(["completed", "closed", "inspected"]),
        )
    )).scalar() or 0

    pending = (await db.execute(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
            HousekeepingTask.status.in_(["pending", "in_progress"]),
        )
    )).scalar() or 0

    inspection_pass = (await db.execute(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
            HousekeepingTask.status == "inspected",
        )
    )).scalar() or 0

    pass_rate = round((inspection_pass / completed) * 100, 1) if completed else 0.0

    return schemas.HousekeepingReportResponse(
        property_id=property_id,
        from_date=from_date,
        to_date=to_date,
        total_tasks=total,
        completed_tasks=completed,
        pending_tasks=pending,
        inspection_pass_rate=pass_rate,
    )


async def get_maintenance_report(
    db: AsyncSession, property_id: uuid.UUID, from_date: date, to_date: date
) -> schemas.MaintenanceReportResponse:
    total = (await db.execute(
        select(func.count(MaintenanceTicket.ticket_id)).where(
            MaintenanceTicket.property_id == property_id,
        )
    )).scalar() or 0

    open_t = (await db.execute(
        select(func.count(MaintenanceTicket.ticket_id)).where(
            MaintenanceTicket.property_id == property_id,
            MaintenanceTicket.status.in_(["open", "assigned", "in_progress"]),
        )
    )).scalar() or 0

    resolved = (await db.execute(
        select(func.count(MaintenanceTicket.ticket_id)).where(
            MaintenanceTicket.property_id == property_id,
            MaintenanceTicket.status.in_(["resolved", "closed"]),
        )
    )).scalar() or 0

    return schemas.MaintenanceReportResponse(
        property_id=property_id,
        from_date=from_date,
        to_date=to_date,
        total_tickets=total,
        open_tickets=open_t,
        resolved_tickets=resolved,
    )


async def get_staff_performance_report(
    db: AsyncSession, property_id: uuid.UUID, from_date: date, to_date: date
) -> schemas.StaffPerformanceReportResponse:
    q = await db.execute(
        select(StaffPerformance, User)
        .join(User, User.id == StaffPerformance.staff_id)
        .where(
            User.property_id == property_id,
            StaffPerformance.review_period_start >= from_date,
            StaffPerformance.review_period_end <= to_date,
        )
        .order_by(StaffPerformance.review_date.desc())
    )
    rows = q.all()

    metrics = [
        {
            "staff_id": str(p.staff_id),
            "staff_name": u.name,
            "rating": p.rating,
            "attendance_score": p.attendance_score,
            "task_completion_score": p.task_completion_score,
            "review_period": f"{p.review_period_start} to {p.review_period_end}",
        }
        for p, u in rows
    ]

    return schemas.StaffPerformanceReportResponse(
        property_id=property_id,
        from_date=from_date,
        to_date=to_date,
        staff_metrics=metrics,
    )


# ── Phase Room Blocks ──────────────────────────────────────────────────────────

async def create_room_block(
    db: AsyncSession,
    payload: schemas.RoomBlockCreate,
    current_user: User,
) -> schemas.RoomBlockResponse:
    # Validate room
    room_res = await db.execute(
        select(Room).where(
            Room.room_id == payload.room_id,
            Room.property_id == payload.property_id,
        )
    )
    room = room_res.scalars().first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    if payload.from_date > payload.to_date:
        raise HTTPException(status_code=422, detail="from_date must be before to_date")

    block = RoomBlock(
        property_id=payload.property_id,
        room_id=payload.room_id,
        blocked_by=current_user.id,
        from_date=payload.from_date,
        to_date=payload.to_date,
        reason=payload.reason,
        notes=payload.notes,
        is_active=True,
    )
    db.add(block)

    await _write_audit_log(
        db,
        property_id=payload.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="ROOM_BLOCKED",
        target_entity="room_blocks",
        target_record_id=block.block_id,
        new_value={
            "room_id": str(payload.room_id),
            "from_date": str(payload.from_date),
            "to_date": str(payload.to_date),
            "reason": payload.reason,
        },
    )

    return schemas.RoomBlockResponse(
        block_id=block.block_id,
        property_id=block.property_id,
        room_id=block.room_id,
        room_number=room.room_number,
        blocked_by=block.blocked_by,
        blocked_by_name=current_user.name,
        from_date=block.from_date,
        to_date=block.to_date,
        reason=block.reason,
        notes=block.notes,
        is_active=block.is_active,
    )


async def list_room_blocks(
    db: AsyncSession,
    property_id: uuid.UUID,
    active_only: bool = True,
) -> List[schemas.RoomBlockResponse]:
    filters = [RoomBlock.property_id == property_id]
    if active_only:
        filters.append(RoomBlock.is_active == True)

    q = await db.execute(
        select(RoomBlock, Room, User)
        .join(Room, Room.room_id == RoomBlock.room_id)
        .join(User, User.id == RoomBlock.blocked_by)
        .where(*filters)
        .order_by(RoomBlock.from_date.desc())
    )
    rows = q.all()
    return [
        schemas.RoomBlockResponse(
            block_id=b.block_id,
            property_id=b.property_id,
            room_id=b.room_id,
            room_number=r.room_number,
            blocked_by=b.blocked_by,
            blocked_by_name=u.name,
            from_date=b.from_date,
            to_date=b.to_date,
            reason=b.reason,
            notes=b.notes,
            is_active=b.is_active,
            created_at=b.created_at,
            released_at=b.released_at,
        )
        for b, r, u in rows
    ]


async def release_room_block(
    db: AsyncSession,
    block_id: uuid.UUID,
    current_user: User,
) -> Dict[str, Any]:
    block_res = await db.execute(
        select(RoomBlock).where(RoomBlock.block_id == block_id)
    )
    block = block_res.scalars().first()
    if not block:
        raise HTTPException(status_code=404, detail="Room block not found")

    block.is_active = False
    block.released_at = datetime.now(timezone.utc)
    block.released_by = current_user.id

    await _write_audit_log(
        db,
        property_id=block.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="ROOM_BLOCK_RELEASED",
        target_entity="room_blocks",
        target_record_id=block_id,
        old_value={"is_active": True},
        new_value={"is_active": False, "released_by": str(current_user.id)},
    )

    return {"message": "Room block released.", "block_id": str(block_id)}


# ── Manager Notes ──────────────────────────────────────────────────────────────

async def create_manager_note(
    db: AsyncSession,
    payload: schemas.ManagerNoteCreate,
    current_user: User,
) -> schemas.ManagerNoteResponse:
    note = ManagerNote(
        property_id=payload.property_id,
        created_by=current_user.id,
        note_type=payload.note_type,
        content=payload.content,
        room_id=payload.room_id,
        booking_id=payload.booking_id,
        is_pinned=payload.is_pinned or False,
        is_resolved=False,
    )
    db.add(note)

    await _write_audit_log(
        db,
        property_id=payload.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="NOTE_CREATED",
        target_entity="manager_notes",
        target_record_id=note.note_id,
        new_value={"note_type": payload.note_type},
    )

    return schemas.ManagerNoteResponse(
        note_id=note.note_id,
        property_id=note.property_id,
        created_by=note.created_by,
        created_by_name=current_user.name,
        note_type=note.note_type,
        content=note.content,
        is_pinned=note.is_pinned,
        is_resolved=note.is_resolved,
        room_id=note.room_id,
        booking_id=note.booking_id,
    )


async def list_manager_notes(
    db: AsyncSession,
    property_id: uuid.UUID,
    note_type: Optional[str] = None,
    is_resolved: Optional[bool] = None,
    skip: int = 0,
    limit: int = 50,
) -> List[schemas.ManagerNoteResponse]:
    filters = [ManagerNote.property_id == property_id]
    if note_type:
        filters.append(ManagerNote.note_type == note_type)
    if is_resolved is not None:
        filters.append(ManagerNote.is_resolved == is_resolved)

    q = await db.execute(
        select(ManagerNote, User)
        .join(User, User.id == ManagerNote.created_by)
        .where(*filters)
        .order_by(ManagerNote.is_pinned.desc(), ManagerNote.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    rows = q.all()
    return [
        schemas.ManagerNoteResponse(
            note_id=n.note_id,
            property_id=n.property_id,
            created_by=n.created_by,
            created_by_name=u.name,
            note_type=n.note_type,
            content=n.content,
            is_pinned=n.is_pinned,
            is_resolved=n.is_resolved,
            room_id=n.room_id,
            booking_id=n.booking_id,
            created_at=n.created_at,
            resolved_at=n.resolved_at,
        )
        for n, u in rows
    ]


async def resolve_manager_note(
    db: AsyncSession, note_id: uuid.UUID, current_user: User
) -> Dict[str, Any]:
    note_res = await db.execute(
        select(ManagerNote).where(ManagerNote.note_id == note_id)
    )
    note = note_res.scalars().first()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    note.is_resolved = True
    note.resolved_at = datetime.now(timezone.utc)
    note.resolved_by = current_user.id
    return {"message": "Note resolved.", "note_id": str(note_id)}


async def delete_manager_note(
    db: AsyncSession, note_id: uuid.UUID, current_user: User
) -> Dict[str, Any]:
    note_res = await db.execute(
        select(ManagerNote).where(ManagerNote.note_id == note_id)
    )
    note = note_res.scalars().first()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")

    # Only creator or manager can delete
    await db.delete(note)
    return {"message": "Note deleted.", "note_id": str(note_id)}


# ── Daily Checklists ──────────────────────────────────────────────────────────

DEFAULT_CHECKLIST_ITEMS = {
    "handover_received": False,
    "room_status_reviewed": False,
    "staff_briefed": False,
    "maintenance_reviewed": False,
    "housekeeping_reviewed": False,
    "bookings_reviewed": False,
    "guest_requests_reviewed": False,
    "safety_check_done": False,
}


async def create_checklist(
    db: AsyncSession,
    payload: schemas.ChecklistCreate,
    current_user: User,
) -> schemas.ChecklistResponse:
    items = payload.items or dict(DEFAULT_CHECKLIST_ITEMS)

    checklist = ManagerDailyChecklist(
        property_id=payload.property_id,
        manager_id=current_user.id,
        checklist_date=payload.checklist_date,
        shift=payload.shift,
        items=items,
        status="pending",
    )
    db.add(checklist)

    return schemas.ChecklistResponse(
        checklist_id=checklist.checklist_id,
        property_id=checklist.property_id,
        manager_id=checklist.manager_id,
        manager_name=current_user.name,
        checklist_date=checklist.checklist_date,
        shift=checklist.shift,
        items=checklist.items,
        status=checklist.status,
    )


async def update_checklist(
    db: AsyncSession,
    checklist_id: uuid.UUID,
    payload: schemas.ChecklistUpdateRequest,
    current_user: User,
) -> schemas.ChecklistResponse:
    cl_res = await db.execute(
        select(ManagerDailyChecklist).where(ManagerDailyChecklist.checklist_id == checklist_id)
    )
    cl = cl_res.scalars().first()
    if not cl:
        raise HTTPException(status_code=404, detail="Checklist not found")

    cl.items = {**(cl.items or {}), **payload.items}
    if payload.notes:
        cl.notes = payload.notes
    if payload.status:
        cl.status = payload.status
    if all(v for v in (cl.items or {}).values()):
        cl.status = "completed"
        cl.completed_at = datetime.now(timezone.utc)

    await _write_audit_log(
        db,
        property_id=cl.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="CHECKLIST_UPDATED",
        target_entity="manager_daily_checklists",
        target_record_id=checklist_id,
        new_value={"status": cl.status},
    )

    return schemas.ChecklistResponse(
        checklist_id=cl.checklist_id,
        property_id=cl.property_id,
        manager_id=cl.manager_id,
        checklist_date=cl.checklist_date,
        shift=cl.shift,
        items=cl.items,
        status=cl.status,
        notes=cl.notes,
        completed_at=cl.completed_at,
        created_at=cl.created_at,
    )


async def sign_off_checklist(
    db: AsyncSession,
    checklist_id: uuid.UUID,
    payload: schemas.ChecklistSignOffRequest,
    current_user: User,
) -> schemas.ChecklistResponse:
    cl_res = await db.execute(
        select(ManagerDailyChecklist).where(ManagerDailyChecklist.checklist_id == checklist_id)
    )
    cl = cl_res.scalars().first()
    if not cl:
        raise HTTPException(status_code=404, detail="Checklist not found")

    cl.status = "signed_off"
    cl.signed_off_by = current_user.id
    cl.signed_off_at = datetime.now(timezone.utc)
    if payload.notes:
        cl.notes = payload.notes

    await _write_audit_log(
        db,
        property_id=cl.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="CHECKLIST_SIGNED_OFF",
        target_entity="manager_daily_checklists",
        target_record_id=checklist_id,
        new_value={"status": "signed_off"},
    )

    return schemas.ChecklistResponse(
        checklist_id=cl.checklist_id,
        property_id=cl.property_id,
        manager_id=cl.manager_id,
        checklist_date=cl.checklist_date,
        shift=cl.shift,
        items=cl.items,
        status=cl.status,
        notes=cl.notes,
        signed_off_by=cl.signed_off_by,
        signed_off_at=cl.signed_off_at,
    )


async def list_checklists(
    db: AsyncSession,
    property_id: uuid.UUID,
    checklist_date: Optional[date] = None,
    shift: Optional[str] = None,
) -> List[schemas.ChecklistResponse]:
    filters = [ManagerDailyChecklist.property_id == property_id]
    if checklist_date:
        filters.append(ManagerDailyChecklist.checklist_date == checklist_date)
    if shift:
        filters.append(ManagerDailyChecklist.shift == shift)

    q = await db.execute(
        select(ManagerDailyChecklist, User)
        .join(User, User.id == ManagerDailyChecklist.manager_id)
        .where(*filters)
        .order_by(ManagerDailyChecklist.checklist_date.desc())
        .limit(100)
    )
    rows = q.all()
    return [
        schemas.ChecklistResponse(
            checklist_id=cl.checklist_id,
            property_id=cl.property_id,
            manager_id=cl.manager_id,
            manager_name=u.name,
            checklist_date=cl.checklist_date,
            shift=cl.shift,
            items=cl.items,
            status=cl.status,
            notes=cl.notes,
            completed_at=cl.completed_at,
            signed_off_by=cl.signed_off_by,
            signed_off_at=cl.signed_off_at,
            created_at=cl.created_at,
        )
        for cl, u in rows
    ]


# ── Service Requests ───────────────────────────────────────────────────────────

async def list_service_requests(
    db: AsyncSession,
    property_id: uuid.UUID,
    status_filter: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
) -> List[schemas.ServiceRequestListItem]:
    filters = [ServiceRequest.property_id == property_id]
    if status_filter:
        filters.append(ServiceRequest.status == status_filter)

    q = await db.execute(
        select(ServiceRequest).where(*filters)
        .order_by(ServiceRequest.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    rows = q.scalars().all()

    # Get room numbers
    room_ids = {r.room_id for r in rows if r.room_id}
    room_map: Dict[uuid.UUID, str] = {}
    if room_ids:
        rq = await db.execute(select(Room).where(Room.room_id.in_(room_ids)))
        for rm in rq.scalars().all():
            room_map[rm.room_id] = rm.room_number

    return [
        schemas.ServiceRequestListItem(
            request_id=sr.request_id,
            property_id=sr.property_id,
            room_id=sr.room_id,
            room_number=room_map.get(sr.room_id) if sr.room_id else None,
            request_category=sr.request_category,
            title=sr.title,
            priority=sr.priority,
            status=sr.status,
            assigned_to=sr.assigned_to,
            created_at=sr.created_at,
        )
        for sr in rows
    ]


async def assign_service_request(
    db: AsyncSession,
    request_id: uuid.UUID,
    payload: schemas.ServiceRequestAssignRequest,
    current_user: User,
) -> Dict[str, Any]:
    sr_res = await db.execute(
        select(ServiceRequest).where(ServiceRequest.request_id == request_id)
    )
    sr = sr_res.scalars().first()
    if not sr:
        raise HTTPException(status_code=404, detail="Service request not found")

    # Validate staff
    staff_res = await db.execute(
        select(User).where(
            User.id == payload.assigned_to,
            User.property_id == sr.property_id,
            User.status == "ACTIVE",
        )
    )
    staff = staff_res.scalars().first()
    if not staff:
        raise HTTPException(status_code=422, detail="Staff not found or inactive")

    sr.assigned_to = payload.assigned_to
    sr.assigned_at = datetime.now(timezone.utc)
    sr.status = "assigned"

    await _create_in_app_notification(
        db,
        recipient_id=payload.assigned_to,
        title="Service Request Assigned",
        message=f"Service request '{sr.title}' has been assigned to you.",
        payload={"request_id": str(request_id)},
    )

    await _write_audit_log(
        db,
        property_id=sr.property_id,
        user_id=current_user.id,
        module_name="manager",
        action_type="SERVICE_REQUEST_ASSIGNED",
        target_entity="service_requests",
        target_record_id=request_id,
        new_value={"assigned_to": str(payload.assigned_to)},
    )

    return {"message": "Service request assigned.", "request_id": str(request_id)}
