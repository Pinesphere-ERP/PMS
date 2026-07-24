import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.core.dependencies import assert_property_access, assert_resource_property_access, get_current_user, require_resource_property_access
from app.infra.models import HousekeepingTask, LostAndFound, MaintenanceTicket, Room, User
from app.modules.housekeeping.schemas import (
    HousekeepingTaskCreate, HousekeepingTaskUpdate, HousekeepingTaskInspect,
    HousekeepingTaskResponse, StartCleaningRequest, CompleteCleaningRequest,
    HousekeepingConfigCreate, HousekeepingConfigUpdate, HousekeepingConfigResponse,
    MaintenanceTicketCreate, MaintenanceTicketUpdate, MaintenanceTicketResponse,
    LostAndFoundCreate, LostAndFoundUpdate, LostAndFoundResponse,
    HousekeepingDashboard,
    HousekeepingRoomCardResponse, HousekeepingRoomDetailResponse,
    CleaningCompleteRequest, CleaningScheduleRequest, HousekeepingStatusUpdate,
    HousekeepingNotificationResponse,
)
from app.modules.housekeeping import service

router = APIRouter()


# ─── Housekeeping Tasks ────────────────────────────────────────────

@router.post("/tasks", response_model=HousekeepingTaskResponse, status_code=status.HTTP_201_CREATED)
async def create_housekeeping_task(
    req: HousekeepingTaskCreate,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[uuid.UUID] = None,
    current_user: User = Depends(get_current_user),
):
    """Create a new housekeeping task. Manual creation is restricted."""
    raise HTTPException(status_code=403, detail="Manual creation of housekeeping tasks is not allowed.")


@router.get("/tasks", response_model=List[HousekeepingTaskResponse])
async def list_housekeeping_tasks(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property ID"),
    status: Optional[str] = Query(None, description="Filter by status (pending, in_progress, completed, inspected)"),
    staff_id: Optional[uuid.UUID] = Query(None, description="Filter by assigned staff ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List housekeeping tasks with optional filters."""
    property_id = property_id or current_user.property_id
    if not property_id:
        raise HTTPException(status_code=403, detail="Property scope required")
    await assert_property_access(property_id, current_user, db)
    return await service.get_tasks(db, property_id=property_id, status_filter=status, staff_id=staff_id)


@router.get("/tasks/{task_id}", response_model=HousekeepingTaskResponse, dependencies=[Depends(require_resource_property_access(HousekeepingTask, HousekeepingTask.task_id, "task_id"))])
async def get_housekeeping_task_detail(
    task_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get housekeeping task detail."""
    return await service.get_task_detail(db, task_id)


@router.patch("/tasks/{task_id}", response_model=HousekeepingTaskResponse, dependencies=[Depends(require_resource_property_access(HousekeepingTask, HousekeepingTask.task_id, "task_id"))])
async def update_housekeeping_task(
    task_id: uuid.UUID,
    req: HousekeepingTaskUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update housekeeping task fields."""
    return await service.update_task(db, task_id, req, current_user.id)


@router.post("/tasks/{task_id}/start", response_model=HousekeepingTaskResponse, dependencies=[Depends(require_resource_property_access(HousekeepingTask, HousekeepingTask.task_id, "task_id"))])
async def start_housekeeping_task(
    task_id: uuid.UUID,
    req: StartCleaningRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Start a housekeeping task."""
    return await service.start_cleaning(db, task_id, req, current_user.id)


@router.post("/tasks/{task_id}/complete", response_model=HousekeepingTaskResponse, dependencies=[Depends(require_resource_property_access(HousekeepingTask, HousekeepingTask.task_id, "task_id"))])
async def complete_housekeeping_task(
    task_id: uuid.UUID,
    req: CompleteCleaningRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Complete a housekeeping task."""
    return await service.complete_cleaning(db, task_id, req, current_user.id)


@router.post("/tasks/{task_id}/damage", response_model=MaintenanceTicketResponse, dependencies=[Depends(require_resource_property_access(HousekeepingTask, HousekeepingTask.task_id, "task_id"))])
async def report_damage_task(
    task_id: uuid.UUID,
    req: MaintenanceTicketCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Report damage during a housekeeping task."""
    return await service.report_damage(db, task_id, req, current_user.id)


@router.post("/tasks/{task_id}/inspect", response_model=HousekeepingTaskResponse, dependencies=[Depends(require_resource_property_access(HousekeepingTask, HousekeepingTask.task_id, "task_id"))])
async def inspect_housekeeping_task(
    task_id: uuid.UUID,
    req: HousekeepingTaskInspect,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Inspect a completed housekeeping task (pass/fail)."""
    return await service.inspect_task(db, task_id, req, current_user.id)


# ─── Configs ───────────────────────────────────────────

@router.get("/config", response_model=HousekeepingConfigResponse)
async def get_housekeeping_config(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get housekeeping config for property."""
    property_id = property_id or current_user.property_id
    if not property_id:
        raise HTTPException(status_code=403, detail="Property scope required")
    await assert_property_access(property_id, current_user, db)
    return await service.get_housekeeping_config(db, property_id)


@router.put("/config", response_model=HousekeepingConfigResponse)
async def update_housekeeping_config(
    req: HousekeepingConfigUpdate,
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update housekeeping config for property."""
    property_id = property_id or current_user.property_id
    if not property_id:
        raise HTTPException(status_code=403, detail="Property scope required")
    await assert_property_access(property_id, current_user, db)
    return await service.update_housekeeping_config(db, property_id, req, current_user.id)


# ─── Maintenance Tickets ───────────────────────────────────────────

@router.post("/maintenance", response_model=MaintenanceTicketResponse, status_code=status.HTTP_201_CREATED)
async def create_maintenance_ticket(
    req: MaintenanceTicketCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new maintenance ticket."""
    await assert_resource_property_access(Room, Room.room_id, req.room_id, current_user, db)
    return await service.create_maintenance_ticket(db, req, current_user.id)


@router.get("/maintenance", response_model=List[MaintenanceTicketResponse])
async def list_maintenance_tickets(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property ID"),
    status: Optional[str] = Query(None, description="Filter by status (open, in_progress, resolved, closed)"),
    category: Optional[str] = Query(None, description="Filter by category (Electrical, AC, Plumbing, TV, Furniture)"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List maintenance tickets with optional filters."""
    property_id = property_id or current_user.property_id
    if not property_id:
        raise HTTPException(status_code=403, detail="Property scope required")
    await assert_property_access(property_id, current_user, db)
    return await service.get_maintenance_tickets(db, property_id=property_id, status_filter=status, category_filter=category)


@router.get("/maintenance/{ticket_id}", response_model=MaintenanceTicketResponse, dependencies=[Depends(require_resource_property_access(MaintenanceTicket, MaintenanceTicket.ticket_id, "ticket_id"))])
async def get_maintenance_ticket_detail(
    ticket_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get maintenance ticket detail."""
    return await service.get_maintenance_ticket_detail(db, ticket_id)


@router.patch("/maintenance/{ticket_id}", response_model=MaintenanceTicketResponse, dependencies=[Depends(require_resource_property_access(MaintenanceTicket, MaintenanceTicket.ticket_id, "ticket_id"))])
async def update_maintenance_ticket(
    ticket_id: uuid.UUID,
    req: MaintenanceTicketUpdate,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[uuid.UUID] = None,
    current_user: User = Depends(get_current_user),
):
    """Update maintenance ticket fields."""
    return await service.update_maintenance_ticket(db, ticket_id, req, current_user_id)


# ─── Lost & Found ──────────────────────────────────────────────────

@router.post("/lost-found", response_model=LostAndFoundResponse, status_code=status.HTTP_201_CREATED)
async def create_lost_found_item(
    req: LostAndFoundCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a lost & found item."""
    await assert_resource_property_access(Room, Room.room_id, req.room_id, current_user, db)
    return await service.create_lost_found(db, req, current_user.id)


@router.get("/lost-found", response_model=List[LostAndFoundResponse])
async def list_lost_found_items(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property ID"),
    status: Optional[str] = Query(None, description="Filter by status (stored, returned, disposed)"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List lost & found items with optional filters."""
    property_id = property_id or current_user.property_id
    if not property_id:
        raise HTTPException(status_code=403, detail="Property scope required")
    await assert_property_access(property_id, current_user, db)
    return await service.get_lost_found_items(db, property_id=property_id, status_filter=status)


@router.patch("/lost-found/{item_id}", response_model=LostAndFoundResponse, dependencies=[Depends(require_resource_property_access(LostAndFound, LostAndFound.item_id, "item_id"))])
async def update_lost_found_item_status(
    item_id: uuid.UUID,
    req: LostAndFoundUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update lost & found item status (stored, returned, disposed)."""
    return await service.update_lost_found_status(db, item_id, req, current_user.id)


# ─── Dashboard ─────────────────────────────────────────────────────

@router.get("/dashboard", response_model=HousekeepingDashboard)
async def get_housekeeping_dashboard(
    property_id: uuid.UUID = Query(..., description="Property ID for dashboard scope"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get housekeeping dashboard summary stats."""
    await assert_property_access(property_id, current_user, db)
    return await service.get_housekeeping_dashboard(db, property_id)


# ─── Housekeeping Room Status ──────────────────────────────────────

@router.get("/rooms", response_model=List[HousekeepingRoomCardResponse])
async def list_housekeeping_rooms(
    property_id: Optional[uuid.UUID] = Query(None, description="Property ID"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all rooms with their current housekeeping status."""
    property_id = property_id or current_user.property_id
    if not property_id:
        raise HTTPException(status_code=403, detail="Property scope required")
    await assert_property_access(property_id, current_user, db)
    return await service.get_housekeeper_rooms(db, property_id, current_user)


@router.get("/rooms/{room_id}", response_model=HousekeepingRoomDetailResponse)
async def get_room_housekeeping_detail(
    room_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get detailed housekeeping status for a single room."""
    return await service.get_housekeeper_room_detail(db, room_id, current_user)


@router.post("/rooms/{room_id}/complete", response_model=HousekeepingRoomDetailResponse)
async def complete_room_housekeeping(
    room_id: uuid.UUID,
    req: CleaningCompleteRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Mark room-level cleaning as complete with photos (room status dashboard flow)."""
    return await service.complete_room_cleaning(db, room_id, req, current_user)


@router.post("/rooms/{room_id}/schedule", response_model=HousekeepingRoomDetailResponse)
async def schedule_room_cleaning(
    room_id: uuid.UUID,
    req: CleaningScheduleRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Schedule cleaning for a room at a specific time."""
    return await service.schedule_cleaning(db, room_id, req, current_user)


@router.patch("/rooms/{room_id}/status", response_model=HousekeepingRoomDetailResponse)
async def update_room_housekeeping_status(
    room_id: uuid.UUID,
    req: HousekeepingStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update the clean status for a room (supports priority escalation)."""
    return await service.update_housekeeping_status(db, room_id, req, current_user)


@router.get("/notifications", response_model=List[HousekeepingNotificationResponse])
async def get_housekeeping_notifications(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get pending housekeeping notifications for the logged-in housekeeper."""
    return await service.get_housekeeper_notifications(db, current_user)
