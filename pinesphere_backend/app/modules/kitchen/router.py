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

@router.post("/orders", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_kitchen_order(
    payload: TaskCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new kitchen order."""
    await assert_property_access(payload.property_id, current_user, db)

    try:
        room_id = uuid.UUID(payload.room_id) if payload.room_id else None
        booking_id = uuid.UUID(payload.booking_id) if payload.booking_id else None
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room_id or booking_id format")

    new_task = Task(
        task_id=uuid.uuid4(),
        property_id=payload.property_id,
        task_type="food",  # Enforce task_type
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
        notes="Kitchen order created"
    )
    db.add(log)

    await db.commit()
    await db.refresh(new_task)
    return new_task


@router.get("/orders", response_model=List[TaskResponse])
async def list_kitchen_orders(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope tasks by property (required)"),
    status: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List kitchen orders."""
    if property_id is None:
        raise HTTPException(status_code=400, detail="property_id is required.")
    await assert_property_access(property_id, current_user, db)

    stmt = select(Task).where(
        Task.property_id == property_id,
        Task.task_type == "food"
    )

    if status:
        stmt = stmt.where(Task.status == status)

    result = await db.execute(stmt)
    return result.scalars().all()


@router.patch("/orders/{task_id}/status", response_model=TaskResponse)
async def update_kitchen_order_status(
    task_id: uuid.UUID,
    payload: TaskStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update kitchen order status."""
    stmt = select(Task).where(Task.task_id == task_id, Task.task_type == "food")
    result = await db.execute(stmt)
    task = result.scalar_one_or_none()

    if not task:
        raise HTTPException(status_code=404, detail="Kitchen order not found")

    await assert_property_access(task.property_id, current_user, db)

    old_status = task.status
    task.status = payload.status

    if payload.status == "accepted" and task.assigned_to is None:
        task.assigned_to = current_user.id

    if payload.status in ["completed", "ready", "delivered"]:
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
