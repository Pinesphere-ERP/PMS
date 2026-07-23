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
    LostAndFoundResponse, HousekeepingDashboard,
    HousekeepingConfigCreate, HousekeepingConfigUpdate, HousekeepingConfigResponse,
    StartCleaningRequest, CompleteCleaningRequest,
)

from app.infra.models import HousekeepingConfig


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


async def start_cleaning(
    db: AsyncSession, task_id: uuid.UUID, req: StartCleaningRequest, current_user_id: uuid.UUID
) -> HousekeepingTaskResponse:
    task_stmt = select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    task_res = await db.execute(task_stmt)
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Housekeeping task not found")

    if task.status != "pending":
        raise HTTPException(status_code=400, detail=f"Cannot start cleaning from status {task.status}")

    task.status = "in_progress"
    task.started_at = datetime.utcnow()
    task.started_by = current_user_id

    room_stmt = select(Room).where(Room.room_id == task.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room.housekeeping_status = "cleaning"

    await AuditLogger.log(
        db,
        property_id=task.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="start_cleaning",
        target_entity="housekeeping_task",
        target_record_id=task.task_id,
        new_value={"status": "in_progress", "started_at": str(task.started_at)},
    )
    await db.commit()
    await db.refresh(task)
    return await _enrich_task(db, task)


async def complete_cleaning(
    db: AsyncSession, task_id: uuid.UUID, req: CompleteCleaningRequest, current_user_id: uuid.UUID
) -> HousekeepingTaskResponse:
    task_stmt = select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    task_res = await db.execute(task_stmt)
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Housekeeping task not found")

    if task.status != "in_progress":
        raise HTTPException(status_code=400, detail=f"Cannot complete task from status {task.status}")

    # Validate against config
    config_stmt = select(HousekeepingConfig).where(HousekeepingConfig.property_id == task.property_id)
    config_res = await db.execute(config_stmt)
    config = config_res.scalar_one_or_none()

    if config:
        if config.require_before_photo and not req.before_photo:
            raise HTTPException(status_code=400, detail="Before photo is required by property config.")
        if config.require_after_photo and not req.after_photo:
            raise HTTPException(status_code=400, detail="After photo is required by property config.")

    task.status = "completed"
    task.completed_at = datetime.utcnow()
    if task.started_at:
        task.duration = int((task.completed_at - task.started_at).total_seconds() / 60)
    
    if req.checklist_status:
        task.checklist_status = req.checklist_status
    if req.before_photo:
        task.before_photo = req.before_photo
    if req.after_photo:
        task.after_photo = req.after_photo
    if req.remarks:
        task.remarks = req.remarks

    room_stmt = select(Room).where(Room.room_id == task.room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room.housekeeping_status = "clean"

    await AuditLogger.log(
        db,
        property_id=task.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="complete_cleaning",
        target_entity="housekeeping_task",
        target_record_id=task.task_id,
        new_value={"status": "completed", "duration": task.duration},
    )
    await db.commit()
    await db.refresh(task)
    return await _enrich_task(db, task)


async def report_damage(
    db: AsyncSession, task_id: uuid.UUID, req: MaintenanceTicketCreate, current_user_id: uuid.UUID
) -> MaintenanceTicketResponse:
    task_stmt = select(HousekeepingTask).where(HousekeepingTask.task_id == task_id)
    task_res = await db.execute(task_stmt)
    task = task_res.scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Housekeeping task not found")

    # Set housekeeping_task_id on request implicitly
    req.housekeeping_task_id = task.task_id
    ticket = await create_maintenance_ticket(db, req, current_user_id)
    return await get_maintenance_ticket_detail(db, ticket.ticket_id)


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
        booking_id=task.booking_id,
        guest_id=task.guest_id,
        created_by=task.created_by,
        assigned_staff_id=task.assigned_staff_id,
        status=task.status,
        priority=task.priority,
        started_at=task.started_at,
        started_by=task.started_by,
        duration=task.duration,
        checklist_status=task.checklist_status,
        remarks=task.remarks,
        before_photo=task.before_photo,
        after_photo=task.after_photo,
        completed_at=task.completed_at,
        inspected_by=task.inspected_by,
        inspection_result=task.inspection_result,
        inspection_remarks=task.inspection_remarks,
        inspected_at=task.inspected_at,
        synced_at=task.synced_at,
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
        housekeeping_task_id=req.housekeeping_task_id,
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
        housekeeping_task_id=ticket.housekeeping_task_id,
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
    
    await AuditLogger.log(
        db,
        property_id=room.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="create_lost_found",
        target_entity="lost_and_found",
        target_record_id=item.item_id,
        new_value={
            "room_id": str(req.room_id),
            "description": req.description,
            "status": "stored",
        },
    )
    await db.commit()
    await db.refresh(item)
    return item


async def update_lost_found_status(
    db: AsyncSession, item_id: uuid.UUID, req: LostAndFoundUpdate, current_user_id: uuid.UUID
) -> LostAndFound:
    item_stmt = select(LostAndFound).where(LostAndFound.item_id == item_id)
    item_res = await db.execute(item_stmt)
    item = item_res.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Lost & found item not found")

    old_status = item.status
    item.status = req.status
    
    await AuditLogger.log(
        db,
        property_id=item.property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="update_lost_found_status",
        target_entity="lost_and_found",
        target_record_id=item.item_id,
        old_value={"status": old_status},
        new_value={"status": item.status},
    )
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


# ─── Configs ─────────────────────────────────────────────────────

async def get_housekeeping_config(
    db: AsyncSession, property_id: uuid.UUID
) -> HousekeepingConfigResponse:
    stmt = select(HousekeepingConfig).where(HousekeepingConfig.property_id == property_id)
    res = await db.execute(stmt)
    config = res.scalar_one_or_none()
    
    if not config:
        # Create default if missing
        config = HousekeepingConfig(property_id=property_id)
        db.add(config)
        await db.commit()
        await db.refresh(config)
        
    return HousekeepingConfigResponse.model_validate(config, from_attributes=True)


async def update_housekeeping_config(
    db: AsyncSession, property_id: uuid.UUID, req: HousekeepingConfigUpdate, current_user_id: uuid.UUID
) -> HousekeepingConfigResponse:
    stmt = select(HousekeepingConfig).where(HousekeepingConfig.property_id == property_id)
    res = await db.execute(stmt)
    config = res.scalar_one_or_none()
    
    if not config:
        config = HousekeepingConfig(property_id=property_id)
        db.add(config)
        
    old_values = {
        "require_before_photo": config.require_before_photo,
        "require_after_photo": config.require_after_photo,
        "default_checklist": config.default_checklist,
    }
    
    update_data = req.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(config, field, value)
        
    await AuditLogger.log(
        db,
        property_id=property_id,
        user_id=current_user_id,
        module_name="housekeeping",
        action_type="update_config",
        target_entity="housekeeping_configs",
        target_record_id=config.id,
        old_value=old_values,
        new_value=update_data,
    )
    await db.commit()
    await db.refresh(config)
    return HousekeepingConfigResponse.model_validate(config, from_attributes=True)


# ─── Cloud Storage Abstraction ─────────────────────────────────────

import abc
import logging

logger = logging.getLogger(__name__)


class CloudStorageService(abc.ABC):
    """Abstract base for cloud image storage. Swap implementation for S3/GCS."""

    @abc.abstractmethod
    async def upload_images(self, files: list) -> list[str]:
        """Upload image files and return their cloud URLs."""
        ...

    @abc.abstractmethod
    async def delete_images(self, urls: list[str]) -> None:
        """Delete images by their cloud URLs."""
        ...


class PlaceholderCloudStorage(CloudStorageService):
    """
    Placeholder implementation — returns fake URLs.
    Replace with real S3/GCS/Azure Blob integration later.
    The interface is designed so swapping requires zero business logic changes.
    """

    async def upload_images(self, files: list) -> list[str]:
        logger.info(f"[PlaceholderCloud] Would upload {len(files)} images")
        return [f"https://cloud.placeholder.pinesphere.com/housekeeping/{uuid.uuid4()}.jpg" for _ in files]

    async def delete_images(self, urls: list[str]) -> None:
        logger.info(f"[PlaceholderCloud] Would delete {len(urls)} images: {urls}")


# Singleton — swap this for a real implementation later
cloud_storage = PlaceholderCloudStorage()


# ─── Housekeeping Room Status Service ──────────────────────────────

from app.infra.models import HousekeepingRoomStatus, Notification, Role
from app.modules.housekeeping import repository as hk_repo
from app.modules.housekeeping.schemas import (
    HousekeepingRoomCardResponse,
    HousekeepingRoomDetailResponse,
    CleaningCompleteRequest,
    CleaningScheduleRequest,
    HousekeepingStatusUpdate,
    HousekeepingNotificationResponse,
)
from app.modules.notifications.service import NotificationDispatchService


async def get_housekeeper_rooms(
    db: AsyncSession, user: "User"
) -> List[HousekeepingRoomCardResponse]:
    """Get all rooms for the housekeeper's assigned property."""
    property_id = user.property_id
    if not property_id:
        raise HTTPException(status_code=403, detail="No property assigned")

    # Auto-sync: ensure housekeeping_room_status is populated
    records = await hk_repo.get_rooms_by_property(db, property_id)
    if not records:
        await hk_repo.sync_rooms_for_property(db, property_id, user.id)
        await db.flush()
        records = await hk_repo.get_rooms_by_property(db, property_id)

    return [
        HousekeepingRoomCardResponse.model_validate(r, from_attributes=True)
        for r in records
    ]


async def get_housekeeper_room_detail(
    db: AsyncSession, room_id: uuid.UUID, user: "User"
) -> HousekeepingRoomDetailResponse:
    """Get detailed housekeeping status for a single room."""
    record = await hk_repo.get_room_status_or_404(db, room_id)
    # Verify property access
    if record.property_id != user.property_id:
        # Check if user has broader access (owner/admin)
        from app.core.dependencies import get_current_role
        role = await get_current_role(user, db)
        if role.role_code not in ("SUPER_ADMIN", "OWNER"):
            raise HTTPException(status_code=403, detail="Access denied to this room")
    return HousekeepingRoomDetailResponse.model_validate(record, from_attributes=True)


async def complete_cleaning(
    db: AsyncSession,
    room_id: uuid.UUID,
    req: CleaningCompleteRequest,
    user: "User",
) -> HousekeepingRoomDetailResponse:
    """Mark cleaning as completed: update status, replace image URLs."""
    record = await hk_repo.get_room_status_or_404(db, room_id)

    # Verify property access
    if record.property_id != user.property_id:
        raise HTTPException(status_code=403, detail="Access denied")

    # Delete old images from cloud (placeholder)
    if record.image_urls:
        await cloud_storage.delete_images(record.image_urls)

    # Store new image URLs
    await hk_repo.update_image_urls(db, room_id, req.image_urls, user.id)

    # Update status to clean
    await hk_repo.update_clean_status(db, room_id, "clean", user.id)

    # Also update the Room table's housekeeping_status
    room_stmt = select(Room).where(Room.room_id == room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room.housekeeping_status = "clean"

    await AuditLogger.log(
        db,
        property_id=record.property_id,
        user_id=user.id,
        module_name="housekeeping",
        action_type="complete_cleaning",
        target_entity="housekeeping_room_status",
        target_record_id=record.id,
        new_value={
            "clean_status": "clean",
            "image_urls": req.image_urls,
            "room_number": record.room_number,
        },
    )

    await db.commit()
    await db.refresh(record)
    return HousekeepingRoomDetailResponse.model_validate(record, from_attributes=True)


async def schedule_cleaning(
    db: AsyncSession,
    room_id: uuid.UUID,
    req: CleaningScheduleRequest,
    user: "User",
) -> HousekeepingRoomDetailResponse:
    """Schedule cleaning for later: update estimated time and status."""
    record = await hk_repo.get_room_status_or_404(db, room_id)

    if record.property_id != user.property_id:
        raise HTTPException(status_code=403, detail="Access denied")

    await hk_repo.set_estimated_cleaning_time(
        db, room_id, req.estimated_cleaning_time, user.id
    )

    # Also update Room table
    room_stmt = select(Room).where(Room.room_id == room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        room.housekeeping_status = "scheduled"

    await AuditLogger.log(
        db,
        property_id=record.property_id,
        user_id=user.id,
        module_name="housekeeping",
        action_type="schedule_cleaning",
        target_entity="housekeeping_room_status",
        target_record_id=record.id,
        new_value={
            "clean_status": "scheduled",
            "estimated_cleaning_time": str(req.estimated_cleaning_time),
            "room_number": record.room_number,
        },
    )

    await db.commit()
    await db.refresh(record)
    return HousekeepingRoomDetailResponse.model_validate(record, from_attributes=True)


async def update_housekeeping_status(
    db: AsyncSession,
    room_id: uuid.UUID,
    req: HousekeepingStatusUpdate,
    user: "User",
) -> HousekeepingRoomDetailResponse:
    """Update clean status (and optionally priority) for a room."""
    record = await hk_repo.get_room_status_or_404(db, room_id)

    old_status = record.clean_status
    record.clean_status = req.clean_status
    record.updated_by = user.id
    if req.priority is not None:
        record.priority = req.priority
    if req.clean_status == "clean":
        record.last_cleaned_at = datetime.utcnow()
    if req.clean_status == "in_progress":
        record.estimated_cleaning_time = None

    # Sync to Room table
    room_stmt = select(Room).where(Room.room_id == room_id)
    room_res = await db.execute(room_stmt)
    room = room_res.scalar_one_or_none()
    if room:
        status_map = {
            "clean": "clean",
            "cleaning_requested": "dirty",
            "in_progress": "cleaning",
            "not_cleaned": "dirty",
            "scheduled": "scheduled",
            "verified": "clean",
        }
        room.housekeeping_status = status_map.get(req.clean_status, "dirty")

    # Trigger notifications for statuses that require housekeeping attention
    if req.clean_status in ("not_cleaned", "cleaning_requested"):
        await _notify_housekeepers(db, record)

    await AuditLogger.log(
        db,
        property_id=record.property_id,
        user_id=user.id,
        module_name="housekeeping",
        action_type="update_housekeeping_status",
        target_entity="housekeeping_room_status",
        target_record_id=record.id,
        old_value={"clean_status": old_status},
        new_value={"clean_status": req.clean_status, "priority": req.priority},
    )

    await db.commit()
    await db.refresh(record)
    return HousekeepingRoomDetailResponse.model_validate(record, from_attributes=True)


async def get_housekeeper_notifications(
    db: AsyncSession, user: "User"
) -> List[HousekeepingNotificationResponse]:
    """Get pending housekeeping notifications for the logged-in housekeeper."""
    query = (
        select(Notification)
        .where(
            Notification.recipient_id == user.id,
            Notification.status == "unread",
        )
        .order_by(Notification.created_at.desc())
    )
    result = await db.execute(query)
    notifications = result.scalars().all()
    return [
        HousekeepingNotificationResponse.model_validate(n, from_attributes=True)
        for n in notifications
    ]


async def sync_room_statuses(
    db: AsyncSession, property_id: uuid.UUID, user_id: Optional[uuid.UUID] = None
) -> int:
    """Sync housekeeping_room_status from the rooms table for a property."""
    count = await hk_repo.sync_rooms_for_property(db, property_id, user_id)
    await db.commit()
    return count


# ─── Internal: Notification Helper ─────────────────────────────────

async def _notify_housekeepers(
    db: AsyncSession, record: HousekeepingRoomStatus
) -> None:
    """Send in-app notification to all housekeepers of the property."""
    # Find all housekeeping users for this property
    housekeeper_role_query = select(Role).where(
        Role.property_id == record.property_id,
        Role.role_code == "HOUSEKEEPING",
    )
    role_res = await db.execute(housekeeper_role_query)
    hk_role = role_res.scalar_one_or_none()

    if not hk_role:
        # Try system-level housekeeping role (no property_id)
        housekeeper_role_query = select(Role).where(
            Role.role_code == "HOUSEKEEPING",
            Role.property_id.is_(None),
        )
        role_res = await db.execute(housekeeper_role_query)
        hk_role = role_res.scalar_one_or_none()

    if not hk_role:
        logger.warning(f"No HOUSEKEEPING role found for property {record.property_id}")
        return

    housekeepers_query = select(User).where(
        User.property_id == record.property_id,
        User.role_id == hk_role.id,
        User.status == "ACTIVE",
    )
    hk_result = await db.execute(housekeepers_query)
    housekeepers = hk_result.scalars().all()

    if not housekeepers:
        logger.info(f"No active housekeepers for property {record.property_id}")
        return

    notification_service = NotificationDispatchService(db)
    for hk in housekeepers:
        await notification_service.dispatch(
            recipient_id=hk.id,
            title="Room Cleaning Required",
            message=f"Room {record.room_number} requires cleaning.",
            channel="in_app",
            priority="high",
            payload={
                "type": "housekeeping",
                "room_id": str(record.room_id),
                "room_number": record.room_number,
                "clean_status": record.clean_status,
            },
        )
    logger.info(
        f"Notified {len(housekeepers)} housekeepers for room {record.room_number}"
    )
