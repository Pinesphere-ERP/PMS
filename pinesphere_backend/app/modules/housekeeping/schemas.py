from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import uuid


class HousekeepingTaskCreate(BaseModel):
    room_id: uuid.UUID
    assigned_staff_id: Optional[uuid.UUID] = None
    priority: str = "medium"
    remarks: Optional[str] = None


class HousekeepingTaskUpdate(BaseModel):
    status: Optional[str] = None
    assigned_staff_id: Optional[uuid.UUID] = None
    remarks: Optional[str] = None
    before_photo: Optional[str] = None
    after_photo: Optional[str] = None
    priority: Optional[str] = None


class HousekeepingTaskResponse(BaseModel):
    task_id: uuid.UUID
    room_id: uuid.UUID
    property_id: uuid.UUID
    assigned_staff_id: Optional[uuid.UUID] = None
    status: str
    priority: str
    checklist_status: Optional[Dict[str, Any]] = None
    remarks: Optional[str] = None
    before_photo: Optional[str] = None
    after_photo: Optional[str] = None
    completed_at: Optional[datetime] = None
    inspected_by: Optional[uuid.UUID] = None
    inspection_result: Optional[str] = None
    inspection_remarks: Optional[str] = None
    inspected_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    room_number: Optional[str] = None
    assigned_staff_name: Optional[str] = None

    class Config:
        from_attributes = True


class HousekeepingTaskInspect(BaseModel):
    inspection_result: str = Field(..., pattern=r"^(pass|fail)$")
    inspection_remarks: Optional[str] = None
    inspected_by: uuid.UUID


class MaintenanceTicketCreate(BaseModel):
    room_id: uuid.UUID
    category: str
    priority: str = "medium"
    issue_description: str
    assigned_to: Optional[uuid.UUID] = None
    photo_url: Optional[str] = None


class MaintenanceTicketUpdate(BaseModel):
    status: Optional[str] = None
    assigned_to: Optional[uuid.UUID] = None
    repair_cost: Optional[float] = None
    priority: Optional[str] = None


class MaintenanceTicketResponse(BaseModel):
    ticket_id: uuid.UUID
    room_id: uuid.UUID
    property_id: uuid.UUID
    reported_by: Optional[uuid.UUID] = None
    assigned_to: Optional[uuid.UUID] = None
    category: str
    priority: str
    issue_description: str
    status: str
    repair_cost: Optional[float] = None
    created_at_ts: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    photo_url: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    room_number: Optional[str] = None
    reported_by_name: Optional[str] = None
    assigned_to_name: Optional[str] = None

    class Config:
        from_attributes = True


class LostAndFoundCreate(BaseModel):
    room_id: uuid.UUID
    description: str
    photo: Optional[str] = None


class LostAndFoundUpdate(BaseModel):
    status: str = Field(..., pattern=r"^(stored|returned|disposed)$")


class LostAndFoundResponse(BaseModel):
    item_id: uuid.UUID
    room_id: uuid.UUID
    property_id: uuid.UUID
    description: str
    found_by: Optional[uuid.UUID] = None
    status: str
    photo: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    room_number: Optional[str] = None
    found_by_name: Optional[str] = None

    class Config:
        from_attributes = True


class HousekeepingDashboard(BaseModel):
    pending_count: int = 0
    in_progress_count: int = 0
    completed_today_count: int = 0
    inspection_pending_count: int = 0
    maintenance_open_count: int = 0


# ─── Housekeeping Room Status Schemas ──────────────────────────────

class HousekeepingRoomCardResponse(BaseModel):
    """Response for GET /housekeeping/rooms — room card data."""
    id: uuid.UUID
    property_id: uuid.UUID
    room_id: uuid.UUID
    room_number: str
    room_type: Optional[str] = None
    floor: Optional[str] = None
    description: Optional[str] = None
    occupancy_status: str = "vacant"
    clean_status: str = "clean"
    priority: Optional[str] = None
    last_cleaned_at: Optional[datetime] = None
    estimated_cleaning_time: Optional[datetime] = None
    image_urls: Optional[List[str]] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class HousekeepingRoomDetailResponse(HousekeepingRoomCardResponse):
    """Extended response for GET /housekeeping/rooms/{room_id}."""
    created_by: Optional[uuid.UUID] = None
    updated_by: Optional[uuid.UUID] = None


class CleaningCompleteRequest(BaseModel):
    """Request for POST /housekeeping/{room_id}/complete."""
    image_urls: List[str] = Field(
        default_factory=list,
        description="Cloud storage URLs of cleaning completion photos",
    )


class CleaningScheduleRequest(BaseModel):
    """Request for POST /housekeeping/{room_id}/schedule."""
    estimated_cleaning_time: datetime = Field(
        ..., description="When the housekeeper will complete cleaning"
    )


class HousekeepingStatusUpdate(BaseModel):
    """Request for PATCH /housekeeping/{room_id}/status."""
    clean_status: str = Field(
        ...,
        pattern=r"^(clean|cleaning_requested|in_progress|not_cleaned|scheduled|verified)$",
        description="New clean status value",
    )
    priority: Optional[str] = Field(
        None,
        pattern=r"^(low|medium|high|urgent)$",
        description="Priority level",
    )


class HousekeepingNotificationResponse(BaseModel):
    """Response for GET /housekeeping/notifications."""
    notification_id: uuid.UUID
    title: str
    message: str
    channel: str = "in_app"
    priority: str = "normal"
    status: str = "unread"
    payload: Optional[Dict[str, Any]] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
