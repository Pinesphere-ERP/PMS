"""
Manager Module — Staff oversight, attendance, task assignment, maintenance overview.
"""
import uuid
from datetime import date, datetime, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func

from app.infra.database import get_db
from app.infra.models import (
    User, HousekeepingTask, MaintenanceTicket, Task, Booking, CheckIn, Room
)
from app.core.dependencies import get_current_user, assert_property_access

router = APIRouter()


# ──────────────────────────────────────────────────────────────────────────────
# Manager Dashboard KPIs
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/dashboard")
async def manager_dashboard(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Returns today's operational snapshot for the manager:
    - Active check-ins count
    - Pending housekeeping tasks
    - Open maintenance tickets
    - Staff task backlog
    """
    await assert_property_access(property_id, current_user, db)
    today = date.today()

    # Active check-ins
    checkin_count_q = await db.execute(
        select(func.count(CheckIn.checkin_id)).where(
            CheckIn.property_id == property_id,
            CheckIn.status == "active",
        )
    )
    active_checkins = checkin_count_q.scalar() or 0

    # Pending housekeeping tasks
    hk_pending_q = await db.execute(
        select(func.count(HousekeepingTask.task_id)).where(
            HousekeepingTask.property_id == property_id,
            HousekeepingTask.status.in_(["pending", "in_progress"]),
        )
    )
    pending_hk = hk_pending_q.scalar() or 0

    # Open maintenance tickets
    mt_q = await db.execute(
        select(func.count(MaintenanceTicket.ticket_id)).where(
            MaintenanceTicket.property_id == property_id,
            MaintenanceTicket.status.in_(["open", "in_progress"]),
        )
    )
    open_mt = mt_q.scalar() or 0

    # Pending general tasks
    tasks_q = await db.execute(
        select(func.count(Task.task_id)).where(
            Task.status == "pending",
        )
    )
    pending_tasks = tasks_q.scalar() or 0

    return {
        "date": str(today),
        "kpis": [
            {"name": "Active Check-ins", "value": str(active_checkins), "icon": "Users"},
            {"name": "Pending HK Tasks", "value": str(pending_hk), "icon": "BedDouble"},
            {"name": "Open Maintenance", "value": str(open_mt), "icon": "Wrench"},
            {"name": "Pending Tasks", "value": str(pending_tasks), "icon": "ClipboardList"},
        ],
    }


# ──────────────────────────────────────────────────────────────────────────────
# Staff Overview
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/staff")
async def list_property_staff(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all staff members assigned to this property."""
    await assert_property_access(property_id, current_user, db)
    stmt = select(User).where(User.property_id == property_id, User.status == "ACTIVE")
    result = await db.execute(stmt)
    staff = result.scalars().all()
    return [
        {
            "id": str(s.id),
            "name": s.name,
            "email": s.email,
            "mobile_number": s.mobile_number,
            "role_id": str(s.role_id) if s.role_id else None,
            "status": s.status,
        }
        for s in staff
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Task Assignment
# ──────────────────────────────────────────────────────────────────────────────

class TaskAssignPayload(BaseModel):
    task_id: uuid.UUID
    assigned_to: uuid.UUID
    property_id: uuid.UUID  # Manager must declare property context; server verifies both task and staff belong here
    due_at: Optional[datetime] = None
    priority: Optional[str] = None  # normal, high, emergency

@router.post("/assign-task")
async def assign_task(
    payload: TaskAssignPayload,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Manager assigns or reassigns a task to a staff member."""
    # T-05 fix: manager must have access to the declared property
    await assert_property_access(payload.property_id, current_user, db)

    stmt = select(Task).where(Task.task_id == payload.task_id)
    result = await db.execute(stmt)
    task = result.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # T-05 fix: task must belong to the same property the manager declared
    if task.property_id != payload.property_id:
        raise HTTPException(
            status_code=403,
            detail="Task does not belong to this property. You cannot assign tasks across properties."
        )

    # T-05 fix: assigned staff must belong to the same property — prevents
    # Sunita Rao (A1) from assigning a task to Ritu Verma (B1's housekeeping staff)
    staff_stmt = select(User).where(
        User.id == payload.assigned_to,
        User.property_id == payload.property_id,
        User.status == "ACTIVE",
    )
    staff_res = await db.execute(staff_stmt)
    staff_member = staff_res.scalars().first()
    if not staff_member:
        raise HTTPException(
            status_code=422,
            detail=(
                "The selected staff member does not belong to this property or is not active. "
                "Cross-property staff assignment is not permitted (§23)."
            ),
        )

    task.assigned_to = payload.assigned_to
    if payload.due_at:
        task.due_at = payload.due_at
    if payload.priority:
        task.priority = payload.priority
    task.status = "pending"

    await db.commit()
    return {"message": "Task assigned successfully.", "task_id": str(task.task_id)}


# ──────────────────────────────────────────────────────────────────────────────
# Maintenance Overview
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/maintenance")
async def get_maintenance_overview(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Open and in-progress maintenance tickets with priority ordering."""
    await assert_property_access(property_id, current_user, db)
    stmt = (
        select(MaintenanceTicket)
        .where(
            MaintenanceTicket.property_id == property_id,
            MaintenanceTicket.status.in_(["open", "in_progress"]),
        )
        .order_by(MaintenanceTicket.priority.desc(), MaintenanceTicket.created_at.asc())
    )
    result = await db.execute(stmt)
    tickets = result.scalars().all()
    return [
        {
            "ticket_id": str(t.ticket_id),
            "title": t.title,
            "status": t.status,
            "priority": t.priority,
            "assigned_to": str(t.assigned_to) if t.assigned_to else None,
            "created_at": t.created_at.isoformat() if t.created_at else None,
        }
        for t in tickets
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Housekeeping Overview
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/housekeeping")
async def get_housekeeping_overview(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Pending and in-progress housekeeping tasks for this property."""
    await assert_property_access(property_id, current_user, db)
    stmt = (
        select(HousekeepingTask)
        .where(
            HousekeepingTask.property_id == property_id,
            HousekeepingTask.status.in_(["pending", "in_progress"]),
        )
        .order_by(HousekeepingTask.created_at.asc())
    )
    result = await db.execute(stmt)
    tasks = result.scalars().all()
    return [
        {
            "task_id": str(t.task_id),
            "room_id": str(t.room_id) if t.room_id else None,
            "task_type": t.task_type,
            "status": t.status,
            "priority": t.priority,
            "assigned_to": str(t.assigned_to) if t.assigned_to else None,
        }
        for t in tasks
    ]
