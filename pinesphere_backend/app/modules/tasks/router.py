import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.database import get_db
from app.infra.models import Task, TaskLog, User
from app.core.dependencies import get_current_user, assert_property_access, get_current_role
from app.modules.tasks.schemas import TaskCreate, TaskResponse, TaskStatusUpdate

router = APIRouter()


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    payload: TaskCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a task scoped to a specific property. Caller must have access to that property."""
    # F-02 fix: enforce property access before creating the task
    await assert_property_access(payload.property_id, current_user, db)

    try:
        room_id = uuid.UUID(payload.room_id) if payload.room_id else None
        booking_id = uuid.UUID(payload.booking_id) if payload.booking_id else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room_id or booking_id format")

    new_task = Task(
        task_id=uuid.uuid4(),
        property_id=payload.property_id,  # F-02 fix: store property_id on task
        task_type=payload.task_type,
        priority=payload.priority,
        room_id=room_id,
        booking_id=booking_id,
        description=payload.description,
        due_at=payload.due_at,
        status="pending"
    )

    db.add(new_task)

    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=new_task.task_id,
        user_id=current_user.id,
        old_status=None,
        new_status="pending",
        notes="Task created"
    )
    db.add(log)

    await db.commit()
    await db.refresh(new_task)
    return new_task


@router.get("", response_model=List[TaskResponse])
async def list_tasks(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope tasks by property (required for non-super-admin)"),
    task_type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    assigned_to_me: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List tasks. Non-super-admin callers must supply property_id.
    Tasks are always filtered to the caller's authorised property — cross-property
    visibility is NEVER permitted regardless of query parameters.
    """
    role = await get_current_role(current_user, db)

    if role.role_code == "SUPER_ADMIN":
        # Super admin may request an unscoped view (all properties), but can also
        # scope by property_id for operational clarity.
        if property_id is not None:
            await assert_property_access(property_id, current_user, db)
    else:
        # All other roles must supply property_id and must have access to it.
        if property_id is None:
            raise HTTPException(
                status_code=400,
                detail="property_id is required. Tasks are property-scoped and cannot be listed globally."
            )
        await assert_property_access(property_id, current_user, db)

    stmt = select(Task)

    # F-02 fix: always apply property filter for non-super-admin
    if property_id is not None:
        stmt = stmt.where(Task.property_id == property_id)
    # Super admin with no property_id gets all tasks (intentional global view)

    if task_type:
        stmt = stmt.where(Task.task_type == task_type)
    if status:
        stmt = stmt.where(Task.status == status)
    if assigned_to_me:
        stmt = stmt.where(Task.assigned_to == current_user.id)

    result = await db.execute(stmt)
    return result.scalars().all()


@router.patch("/{task_id}/status", response_model=TaskResponse)
async def update_task_status(
    task_id: uuid.UUID,
    payload: TaskStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update task status. Caller must have access to the property that owns this task."""
    stmt = select(Task).where(Task.task_id == task_id)
    result = await db.execute(stmt)
    task = result.scalar_one_or_none()

    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # F-02 fix: enforce property access when mutating a task
    await assert_property_access(task.property_id, current_user, db)

    old_status = task.status
    task.status = payload.status

    if payload.status == "accepted" and task.assigned_to is None:
        task.assigned_to = current_user.id

    if payload.status == "completed":
        task.completed_at = datetime.utcnow()

    if payload.photos:
        task.photos = payload.photos
    if payload.remarks:
        task.remarks = payload.remarks

    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=task.task_id,
        user_id=current_user.id,
        old_status=old_status,
        new_status=payload.status,
        notes=payload.notes
    )

    db.add(task)
    db.add(log)
    await db.commit()
    await db.refresh(task)
    return task
