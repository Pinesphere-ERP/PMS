import uuid
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException

from app.infra.models import Room, Task, TaskLog

class RoomStateMachine:
    VALID_STATES = [
        "available", "reserved", "occupied", "needs_cleaning",
        "cleaning", "inspection", "maintenance", "out_of_service"
    ]

    @staticmethod
    async def transition_state(db: AsyncSession, room_id: uuid.UUID, new_state: str, user_id: Optional[uuid.UUID] = None) -> Room:
        if new_state not in RoomStateMachine.VALID_STATES:
            raise HTTPException(status_code=400, detail=f"Invalid room state: {new_state}")

        stmt = select(Room).where(Room.room_id == room_id)
        result = await db.execute(stmt)
        room = result.scalar_one_or_none()

        if not room:
            raise HTTPException(status_code=404, detail="Room not found")

        old_state = room.occupancy_status
        room.occupancy_status = new_state

        # Automation: If transitioning to 'needs_cleaning', automatically dispatch a housekeeping task
        if new_state == "needs_cleaning":
            await RoomStateMachine._dispatch_task(
                db, 
                room_id=room.room_id, 
                task_type="cleaning", 
                priority="normal",
                description="Automatic checkout cleaning",
                user_id=user_id
            )

        # Automation: If transitioning to 'maintenance', dispatch a maintenance task
        elif new_state == "maintenance":
            await RoomStateMachine._dispatch_task(
                db, 
                room_id=room.room_id, 
                task_type="maintenance", 
                priority="high",
                description="Room flagged for maintenance",
                user_id=user_id
            )

        db.add(room)
        await db.commit()
        await db.refresh(room)
        return room

    @staticmethod
    async def _dispatch_task(db: AsyncSession, room_id: uuid.UUID, task_type: str, priority: str, description: str, user_id: Optional[uuid.UUID] = None):
        new_task = Task(
            task_id=uuid.uuid4(),
            task_type=task_type,
            status="pending",
            priority=priority,
            room_id=room_id,
            description=description,
        )
        db.add(new_task)
        
        # Log the task creation
        task_log = TaskLog(
            log_id=uuid.uuid4(),
            task_id=new_task.task_id,
            user_id=user_id,
            old_status=None,
            new_status="pending",
            notes="Auto-dispatched from state transition"
        )
        db.add(task_log)
