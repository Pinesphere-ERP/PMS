import uuid
from datetime import datetime
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from fastapi import HTTPException, status

from app.infra.models import (
    HousekeepingTask, MaintenanceTicket, LostAndFound,
    Room, User
)
from app.modules.audit.logger import AuditLogger
from app.modules.housekeeping.schemas import (
    HousekeepingTaskCreate, HousekeepingTaskUpdate, HousekeepingTaskInspect,
    MaintenanceTicketCreate, MaintenanceTicketUpdate,
    LostAndFoundCreate, LostAndFoundUpdate,
    HousekeepingTaskResponse, MaintenanceTicketResponse,
    LostAndFoundResponse, HousekeepingDashboard
)


# ─── Housekeeping Tasks ────────────────────────────────────────────

async def create_task(
    db: AsyncSession, req: HousekeepingTaskCreate, current_user_id: uuid.UUID
) -> HousekeepingTask:
    room_stmt = select(Room).where(Room.room_id == req.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    task = HousekeepingTask(
        room_id=req.room_id,
        property_id=room.property_id,
        assigned_staff_id=req.assigned_staff_id,
        status="pending",
        priority=req.priority or "medium",
        remarks=req.remarks,
    )
    db.add(task)
    await db.flush()

    if room.housekeeping_status != "dirty":
        room.housekeeping_status = "dirty"

    await AuditLogger.log(
        db,
        property_id=room.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="create_task",
        target_entity="housekeeping_task",
        target_record_id=task.task_id,
        new_value={
            "room_id": str(req.room_id),
            "assigned_staff_id": str(req.assigned_staff_id) if req.assigned_staff_id else None,
            "priority": req.priority,
            "remarks": req.remarks,
        },
    )
    await db.commit()
    await db.refresh(task)
    return task


async def update_task(
    db: AsyncSession, task_id: uuid.UUID, req: HousekeepingTaskUpdate, current_user_id: uuid.UUID
) -> HousekeepingTask:
    task_stmt = select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    task_res = await db.execute(task_stmt)
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Housekeeping task not found")

    old_status = task.status

    update_data = req.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(task, field, value)

    room_stmt = select(Room).where(Room.room_id == task.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()

    if room:
        if task.status == "in_progress" and old_status != "in_progress":
            room.housekeeping_status = "cleaning"
        elif task.status == "completed" and old_status != "completed":
            task.completed_at = datetime.utcnow()
            room.housekeeping_status = "clean"

    await AuditLogger.log(
        db,
        property_id=task.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="update_task",
        target_entity="housekeeping_task",
        target_record_id=task.task_id,
        old_value={"status": old_status},
        new_value={"status": task.status, **update_data},
    )
    await db.commit()
    await db.refresh(task)
    return task


async def inspect_task(
    db: AsyncSession, task_id: uuid.UUID, req: HousekeepingTaskInspect, current_user_id: uuid.UUID
) -> HousekeepingTask:
    task_stmt = select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    task_res = await db.execute(task_stmt)
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Housekeeping task not found")

    task.inspection_result = req.inspection_result
    task.inspection_remarks = req.inspection_remarks
    task.inspected_by = req.inspected_by
    task.inspected_at = datetime.utcnow()

    room_stmt = select(Room).where(Room.room_id == task.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()

    if req.inspection_result == "pass":
        task.status = "inspected"
        if room:
            room.housekeeping_status = "clean"
    else:
        task.status = "pending"

    await AuditLogger.log(
        db,
        property_id=task.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="inspect_task",
        target_entity="housekeeping_task",
        target_record_id=task.task_id,
        new_value={
            "inspection_result": req.inspection_result,
            "inspection_remarks": req.inspection_remarks,
            "inspected_by": str(req.inspected_by),
            "new_status": task.status,
        },
    )
    await db.commit()
    await db.refresh(task)
    return task


async def get_tasks(
    db: AsyncSession,
    property_id: Optional[uuid.UUID] = None,
    status_filter: Optional[str] = None,
    staff_id: Optional[uuid.UUID] = None,
) -> List[HousekeepingTaskResponse]:
    query = select(HousekeepingTask)
    if property_id:
        query = query.where(HousekeepingTask.property_id == property_id)
    if status_filter:
        query = query.where(HousekeepingTask.status == status_filter)
    if staff_id:
        query = query.where(HousekeepingTask.assigned_staff_id == staff_id)

    query = query.order_by(HousekeepingTask.created_at.desc())
    res = await db.execute(query)
    tasks = res.scalars().all()

    return [await _enrich_task(db, t) for t in tasks]


async def get_task_detail(db: AsyncSession, task_id: uuid.UUID) -> HousekeepingTaskResponse:
    task_stmt = select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    task_res = await db.execute(task_stmt)
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Housekeeping task not found")

    return await _enrich_task(db, task)


async def _enrich_task(db: AsyncSession, task: HousekeepingTask) -> HousekeepingTaskResponse:
    room_number = None
    assigned_staff_name = None

    room_stmt = select(Room).where(Room.room_id == task.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room_number = room.room_number

    if task.assigned_staff_id:
        user_stmt = select(User).where(User.id == task.assigned_staff_id)
        user_res = await db.execute(user_stmt)
        user = user_res.scalar_one_or_none()
        if user:
            assigned_staff_name = user.name

    return HousekeepingTaskResponse(
        task_id=task.task_id,
        room_id=task.room_id,
        property_id=task.property_id,
        assigned_staff_id=task.assigned_staff_id,
        status=task.status,
        priority=task.priority,
        checklist_status=task.checklist_status,
        remarks=task.remarks,
        before_photo=task.before_photo,
        after_photo=task.after_photo,
        completed_at=task.completed_at,
        inspected_by=task.inspected_by,
        inspection_result=task.inspection_result,
        inspection_remarks=task.inspection_remarks,
        inspected_at=task.inspected_at,
        created_at=task.created_at,
        updated_at=task.updated_at,
        room_number=room_number,
        assigned_staff_name=assigned_staff_name,
    )


# ─── Maintenance Tickets ───────────────────────────────────────────

async def create_maintenance_ticket(
    db: AsyncSession, req: MaintenanceTicketCreate, current_user_id: uuid.UUID
) -> MaintenanceTicket:
    room_stmt = select(Room).where(Room.room_id == req.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    ticket = MaintenanceTicket(
        room_id=req.room_id,
        property_id=room.property_id,
        reported_by=current_user_id,
        assigned_to=req.assigned_to,
        category=req.category,
        priority=req.priority or "medium",
        issue_description=req.issue_description,
        status="open",
        photo_url=req.photo_url,
        created_at_ts=datetime.utcnow(),
    )
    db.add(ticket)
    await db.flush()

    room.maintenance_status = "maintenance_needed"
    if room.housekeeping_status != "maintenance":
        room.housekeeping_status = "maintenance"

    await AuditLogger.log(
        db,
        property_id=room.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="create_maintenance_ticket",
        target_entity="maintenance_ticket",
        target_record_id=ticket.ticket_id,
        new_value={
            "room_id": str(req.room_id),
            "category": req.category,
            "priority": req.priority,
            "issue_description": req.issue_description,
            "assigned_to": str(req.assigned_to) if req.assigned_to else None,
        },
    )
    await db.commit()
    await db.refresh(ticket)
    return ticket


async def update_maintenance_ticket(
    db: AsyncSession, ticket_id: uuid.UUID, req: MaintenanceTicketUpdate, current_user_id: uuid.UUID
) -> MaintenanceTicket:
    ticket_stmt = select(MaintenanceTicket).where(MaintenanceTicket.ticket_id == ticket_id)
    ticket_res = await db.execute(ticket_stmt)
    ticket = ticket_res.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Maintenance ticket not found")

    old_status = ticket.status
    old_assigned = ticket.assigned_to

    update_data = req.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(ticket, field, value)

    if ticket.status == "resolved" and old_status != "resolved":
        ticket.resolved_at = datetime.utcnow()
        room_stmt = select(Room).where(Room.room_id == ticket.room_id)
        room_res = await db.execute(room_stmt)
        room = room_res.scalar_one_or_none()
        if room:
            room.maintenance_status = "good"
            if room.housekeeping_status == "maintenance":
                room.housekeeping_status = "clean"

    await AuditLogger.log(
        db,
        property_id=ticket.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="update_maintenance_ticket",
        target_entity="maintenance_ticket",
        target_record_id=ticket.ticket_id,
        old_value={"status": old_status, "assigned_to": str(old_assigned) if old_assigned else None},
        new_value={"status": ticket.status, "assigned_to": str(ticket.assigned_to) if ticket.assigned_to else None, **update_data},
    )
    await db.commit()
    await db.refresh(ticket)
    return ticket


async def get_maintenance_tickets(
    db: AsyncSession,
    property_id: Optional[uuid.UUID] = None,
    status_filter: Optional[str] = None,
    category_filter: Optional[str] = None,
) -> List[MaintenanceTicketResponse]:
    query = select(MaintenanceTicket)
    if property_id:
        query = query.where(MaintenanceTicket.property_id == property_id)
    if status_filter:
        query = query.where(MaintenanceTicket.status == status_filter)
    if category_filter:
        query = query.where(MaintenanceTicket.category == category_filter)

    query = query.order_by(MaintenanceTicket.created_at.desc())
    res = await db.execute(query)
    tickets = res.scalars().all()

    return [await _enrich_ticket(db, t) for t in tickets]


async def get_maintenance_ticket_detail(db: AsyncSession, ticket_id: uuid.UUID) -> MaintenanceTicketResponse:
    ticket_stmt = select(MaintenanceTicket).where(MaintenanceTicket.ticket_id == ticket_id)
    ticket_res = await db.execute(ticket_stmt)
    ticket = ticket_res.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Maintenance ticket not found")

    return await _enrich_ticket(db, ticket)


async def _enrich_ticket(db: AsyncSession, ticket: MaintenanceTicket) -> MaintenanceTicketResponse:
    room_number = None
    reported_by_name = None
    assigned_to_name = None

    room_stmt = select(Room).where(Room.room_id == ticket.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room_number = room.room_number

    if ticket.reported_by:
        user_stmt = select(User).where(User.id == ticket.reported_by)
        user_res = await db.execute(user_stmt)
        user = user_res.scalar_one_or_none()
        if user:
            reported_by_name = user.name

    if ticket.assigned_to:
        user_stmt = select(User).where(User.id == ticket.assigned_to)
        user_res = await db.execute(user_stmt)
        user = user_res.scalar_one_or_none()
        if user:
            assigned_to_name = user.name

    return MaintenanceTicketResponse(
        ticket_id=ticket.ticket_id,
        room_id=ticket.room_id,
        property_id=ticket.property_id,
        reported_by=ticket.reported_by,
        assigned_to=ticket.assigned_to,
        category=ticket.category,
        priority=ticket.priority,
        issue_description=ticket.issue_description,
        status=ticket.status,
        repair_cost=ticket.repair_cost,
        created_at_ts=ticket.created_at_ts,
        resolved_at=ticket.resolved_at,
        photo_url=ticket.photo_url,
        created_at=ticket.created_at,
        updated_at=ticket.updated_at,
        room_number=room_number,
        reported_by_name=reported_by_name,
        assigned_to_name=assigned_to_name,
    )


# ─── Lost & Found ──────────────────────────────────────────────────

async def create_lost_found(
    db: AsyncSession, req: LostAndFoundCreate, current_user_id: uuid.UUID
) -> LostAndFound:
    room_stmt = select(Room).where(Room.room_id == req.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    item = LostAndFound(
        room_id=req.room_id,
        property_id=room.property_id,
        description=req.description,
        found_by=current_user_id,
        status="stored",
        photo=req.photo,
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item


async def update_lost_found_status(
    db: AsyncSession, item_id: uuid.UUID, req: LostAndFoundUpdate
) -> LostAndFound:
    item_stmt = select(LostAndFound).where(LostAndFound.item_id == item_id)
    item_res = await db.execute(item_stmt)
    item = item_res.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Lost & found item not found")

    item.status = req.status
    await db.commit()
    await db.refresh(item)
    return item


async def get_lost_found_items(
    db: AsyncSession,
    property_id: Optional[uuid.UUID] = None,
    status_filter: Optional[str] = None,
) -> List[LostAndFoundResponse]:
    query = select(LostAndFound)
    if property_id:
        query = query.where(LostAndFound.property_id == property_id)
    if status_filter:
        query = query.where(LostAndFound.status == status_filter)

    query = query.order_by(LostAndFound.created_at.desc())
    res = await db.execute(query)
    items = res.scalars().all()

    return [await _enrich_lost_found(db, item) for item in items]


async def _enrich_lost_found(db: AsyncSession, item: LostAndFound) -> LostAndFoundResponse:
    room_number = None
    found_by_name = None

    room_stmt = select(Room).where(Room.room_id == item.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room_number = room.room_number

    if item.found_by:
        user_stmt = select(User).where(User.id == item.found_by)
        user_res = await db.execute(user_stmt)
        user = user_res.scalar_one_or_none()
        if user:
            found_by_name = user.name

    return LostAndFoundResponse(
        item_id=item.item_id,
        room_id=item.room_id,
        property_id=item.property_id,
        description=item.description,
        found_by=item.found_by,
        status=item.status,
        photo=item.photo,
        created_at=item.created_at,
        updated_at=item.updated_at,
        room_number=room_number,
        found_by_name=found_by_name,
    )


# ─── Dashboard ─────────────────────────────────────────────────────

async def get_housekeeping_dashboard(
    db: AsyncSession, property_id: uuid.UUID
) -> HousekeepingDashboard:
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

    pending_stmt = select(func.count(HousekeepingTask.task_id)).where(
        HousekeepingTask.property_id == property_id,
        HousekeepingTask.status == "pending",
    )
    in_progress_stmt = select(func.count(HousekeepingTask.task_id)).where(
        HousekeepingTask.property_id == property_id,
        HousekeepingTask.status == "in_progress",
    )
    completed_today_stmt = select(func.count(HousekeepingTask.task_id)).where(
        HousekeepingTask.property_id == property_id,
        HousekeepingTask.status == "completed",
        HousekeepingTask.completed_at >= today_start,
    )
    inspection_pending_stmt = select(func.count(HousekeepingTask.task_id)).where(
        HousekeepingTask.property_id == property_id,
        HousekeepingTask.status == "completed",
    )
    maintenance_open_stmt = select(func.count(MaintenanceTicket.ticket_id)).where(
        MaintenanceTicket.property_id == property_id,
        MaintenanceTicket.status.in_(["open", "in_progress"]),
    )

    pending_res = await db.execute(pending_stmt)
    in_progress_res = await db.execute(in_progress_stmt)
    completed_today_res = await db.execute(completed_today_stmt)
    inspection_pending_res = await db.execute(inspection_pending_stmt)
    maintenance_open_res = await db.execute(maintenance_open_stmt)

    return HousekeepingDashboard(
        pending_count=pending_res.scalar() or 0,
        in_progress_count=in_progress_res.scalar() or 0,
        completed_today_count=completed_today_res.scalar() or 0,
        inspection_pending_count=inspection_pending_res.scalar() or 0,
        maintenance_open_count=maintenance_open_res.scalar() or 0,
    )
