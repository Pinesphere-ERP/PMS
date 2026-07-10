import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.modules.housekeeping.schemas import (
    HousekeepingTaskCreate, HousekeepingTaskUpdate, HousekeepingTaskInspect,
    HousekeepingTaskResponse,
    MaintenanceTicketCreate, MaintenanceTicketUpdate, MaintenanceTicketResponse,
    LostAndFoundCreate, LostAndFoundUpdate, LostAndFoundResponse,
    HousekeepingDashboard,
)
from app.modules.housekeeping import service

router = APIRouter()


# ─── Housekeeping Tasks ────────────────────────────────────────────

@router.post("/tasks", response_model=HousekeepingTaskResponse, status_code=status.HTTP_201_CREATED)
async def create_housekeeping_task(
    req: HousekeepingTaskCreate,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[uuid.UUID] = None,
):
    """Create a new housekeeping task."""
    return await service.create_task(db, req, current_user_id)


@router.get("/tasks", response_model=List[HousekeepingTaskResponse])
async def list_housekeeping_tasks(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property ID"),
    status: Optional[str] = Query(None, description="Filter by status (pending, in_progress, completed, inspected)"),
    staff_id: Optional[uuid.UUID] = Query(None, description="Filter by assigned staff ID"),
    db: AsyncSession = Depends(get_db),
):
    """List housekeeping tasks with optional filters."""
    return await service.get_tasks(db, property_id=property_id, status_filter=status, staff_id=staff_id)


@router.get("/tasks/{task_id}", response_model=HousekeepingTaskResponse)
async def get_housekeeping_task_detail(
    task_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get housekeeping task detail."""
    return await service.get_task_detail(db, task_id)


@router.patch("/tasks/{task_id}", response_model=HousekeepingTaskResponse)
async def update_housekeeping_task(
    task_id: uuid.UUID,
    req: HousekeepingTaskUpdate,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[uuid.UUID] = None,
):
    """Update housekeeping task fields."""
    return await service.update_task(db, task_id, req, current_user_id)


@router.post("/tasks/{task_id}/inspect", response_model=HousekeepingTaskResponse)
async def inspect_housekeeping_task(
    task_id: uuid.UUID,
    req: HousekeepingTaskInspect,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[uuid.UUID] = None,
):
    """Inspect a completed housekeeping task (pass/fail)."""
    return await service.inspect_task(db, task_id, req, current_user_id)


# ─── Maintenance Tickets ───────────────────────────────────────────

@router.post("/maintenance", response_model=MaintenanceTicketResponse, status_code=status.HTTP_201_CREATED)
async def create_maintenance_ticket(
    req: MaintenanceTicketCreate,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[uuid.UUID] = None,
):
    """Create a new maintenance ticket."""
    return await service.create_maintenance_ticket(db, req, current_user_id)


@router.get("/maintenance", response_model=List[MaintenanceTicketResponse])
async def list_maintenance_tickets(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property ID"),
    status: Optional[str] = Query(None, description="Filter by status (open, in_progress, resolved, closed)"),
    category: Optional[str] = Query(None, description="Filter by category (Electrical, AC, Plumbing, TV, Furniture)"),
    db: AsyncSession = Depends(get_db),
):
    """List maintenance tickets with optional filters."""
    return await service.get_maintenance_tickets(db, property_id=property_id, status_filter=status, category_filter=category)


@router.get("/maintenance/{ticket_id}", response_model=MaintenanceTicketResponse)
async def get_maintenance_ticket_detail(
    ticket_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get maintenance ticket detail."""
    return await service.get_maintenance_ticket_detail(db, ticket_id)


@router.patch("/maintenance/{ticket_id}", response_model=MaintenanceTicketResponse)
async def update_maintenance_ticket(
    ticket_id: uuid.UUID,
    req: MaintenanceTicketUpdate,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[uuid.UUID] = None,
):
    """Update maintenance ticket fields."""
    return await service.update_maintenance_ticket(db, ticket_id, req, current_user_id)


# ─── Lost & Found ──────────────────────────────────────────────────

@router.post("/lost-found", response_model=LostAndFoundResponse, status_code=status.HTTP_201_CREATED)
async def create_lost_found_item(
    req: LostAndFoundCreate,
    db: AsyncSession = Depends(get_db),
    current_user_id: Optional[uuid.UUID] = None,
):
    """Create a lost & found item."""
    return await service.create_lost_found(db, req, current_user_id)


@router.get("/lost-found", response_model=List[LostAndFoundResponse])
async def list_lost_found_items(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope by property ID"),
    status: Optional[str] = Query(None, description="Filter by status (stored, returned, disposed)"),
    db: AsyncSession = Depends(get_db),
):
    """List lost & found items with optional filters."""
    return await service.get_lost_found_items(db, property_id=property_id, status_filter=status)


@router.patch("/lost-found/{item_id}", response_model=LostAndFoundResponse)
async def update_lost_found_item_status(
    item_id: uuid.UUID,
    req: LostAndFoundUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Update lost & found item status (stored, returned, disposed)."""
    return await service.update_lost_found_status(db, item_id, req)


# ─── Dashboard ─────────────────────────────────────────────────────

@router.get("/dashboard", response_model=HousekeepingDashboard)
async def get_housekeeping_dashboard(
    property_id: uuid.UUID = Query(..., description="Property ID for dashboard scope"),
    db: AsyncSession = Depends(get_db),
):
    """Get housekeeping dashboard summary stats."""
    return await service.get_housekeeping_dashboard(db, property_id)
