import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select

from app.infra.database import get_db
from app.modules.devices.schemas import (
    DeviceRegisterRequest, DeviceActivateRequest, DeviceActivateResponse,
    DeviceActionRequest, DeviceTransferRequest, DeviceSyncCheckinRequest,
    DeviceSyncCheckinResponse, DeviceResponse, DeviceDetailResponse,
    AuditLogEntryResponse, SyncLogEntryResponse
)
from app.modules.devices import service
from app.infra.models import Device

router = APIRouter()

@router.get("/kpis")
async def get_device_kpis(db: AsyncSession = Depends(get_db)):
    """Global KPI counts for device management console."""
    query = select(Device.status, func.count(Device.id)).group_by(Device.status)
    result = await db.execute(query)
    status_counts = {row[0]: row[1] for row in result.all()}
    total = sum(status_counts.values())
    return [
        { "name": "Total Registered Devices", "value": str(total), "icon": "Smartphone", "color": "text-pine-DEFAULT", "bg": "bg-pine-50" },
        { "name": "Pending Approval", "value": str(status_counts.get("pending_approval", 0)), "icon": "Clock", "color": "text-yellow-600", "bg": "bg-yellow-50" },
        { "name": "Active & Synced", "value": str(status_counts.get("active", 0)), "icon": "CheckCircle2", "color": "text-green-600", "bg": "bg-green-50" },
        { "name": "Locked / Disabled", "value": str(status_counts.get("locked", 0) + status_counts.get("disabled", 0)), "icon": "Lock", "color": "text-purple-600", "bg": "bg-purple-50" },
        { "name": "Offline (> 24h)", "value": "0", "icon": "WifiOff", "color": "text-amber-600", "bg": "bg-amber-50" },
        { "name": "Failed Syncs (24h)", "value": "0", "icon": "AlertTriangle", "color": "text-red-600", "bg": "bg-red-50" },
    ]

@router.get("/diagnostics")
async def get_device_diagnostics(db: AsyncSession = Depends(get_db)):
    """Return device list enriched with sync diagnostics for the diagnostics panel."""
    devices = await service.list_devices(db)
    return [
        {
            "id": str(d.id),
            "name": d.device_name or "Unnamed Device",
            "model": d.os_type or "Unknown",
            "uid": d.device_uid,
            "property": str(d.property_id),
            "battery": 0,
            "lastSync": "Unknown",
            "appVersion": "Unknown",
            "osVersion": d.os_type or "Unknown",
            "syncStatus": "SYNCED" if d.status == "active" else "OFFLINE",
            "approvalStatus": d.status,
            "syncAttempts": []
        }
        for d in devices
    ]

@router.get("/my")
async def get_my_devices(db: AsyncSession = Depends(get_db)):
    """Property-scoped device list (future: filtered by auth token's property)."""
    devices = await service.list_devices(db)
    return [
        {
            "id": str(d.id),
            "name": d.device_name or "Unnamed Device",
            "model": d.os_type or "Unknown",
            "uid": d.device_uid,
            "primaryUser": str(d.primary_user_id) if d.primary_user_id else "Unassigned",
            "status": d.status,
            "battery": 0,
            "lastSync": "Unknown",
            "appVersion": "Unknown",
        }
        for d in devices
    ]

@router.post("/register", response_model=DeviceResponse, status_code=status.HTTP_201_CREATED)
async def register_device(
    req: DeviceRegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    """First-time device registration (requires internet)."""
    return await service.register_device(db, req)

@router.post("/sync-checkin", response_model=DeviceSyncCheckinResponse)
async def sync_checkin(
    req: DeviceSyncCheckinRequest,
    db: AsyncSession = Depends(get_db)
):
    """Called by the Flutter app on every sync cycle; also delivers queued remote commands."""
    return await service.sync_checkin(db, req)

@router.get("", response_model=List[DeviceResponse])
async def get_devices(
    property_id: Optional[uuid.UUID] = Query(None, description="Scope query by property ID"),
    status: Optional[str] = Query(None, description="Filter by status (pending_approval, active, locked, disabled, revoked)"),
    db: AsyncSession = Depends(get_db)
):
    """List registered devices (scoped by role: global for Super Admin, property-scoped for Owner)."""
    return await service.list_devices(db, property_id=property_id, status_filter=status)

@router.get("/{id}", response_model=DeviceDetailResponse)
async def get_device_detail(
    id: uuid.UUID,
    db: AsyncSession = Depends(get_db)
):
    """Device detail incl. session & sync history."""
    return await service.get_device_detail(db, id)

@router.post("/{id}/activate", response_model=DeviceActivateResponse)
async def activate_device(
    id: uuid.UUID,
    db: AsyncSession = Depends(get_db)
):
    """Issue license token after approval."""
    return await service.activate_device(db, id)

@router.post("/{id}/approve", response_model=DeviceResponse)
async def approve_device(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Approve pending device (enforces plan max_devices ceiling)."""
    action_req = req or DeviceActionRequest(action_type="approve")
    action_req.action_type = "approve"
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/reject", response_model=DeviceResponse)
async def reject_device(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Reject pending device request."""
    action_req = req or DeviceActionRequest(action_type="reject")
    action_req.action_type = "reject"
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/lock", response_model=DeviceResponse)
async def lock_device(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Temporary lock on device."""
    action_req = req or DeviceActionRequest(action_type="lock")
    action_req.action_type = "lock"
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/unlock", response_model=DeviceResponse)
async def unlock_device(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Remove lock from device."""
    action_req = req or DeviceActionRequest(action_type="unlock")
    action_req.action_type = "unlock"
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/disable", response_model=DeviceResponse)
async def disable_device(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Soft, longer-term disable (e.g. staff on leave)."""
    action_req = req or DeviceActionRequest(action_type="disable")
    action_req.action_type = "disable"
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/enable", response_model=DeviceResponse)
async def enable_device(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Re-enable a disabled device."""
    action_req = req or DeviceActionRequest(action_type="enable")
    action_req.action_type = "enable"
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/logout", response_model=DeviceResponse)
async def force_logout_device(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Force-end current device session."""
    action_req = req or DeviceActionRequest(action_type="logout")
    action_req.action_type = "logout"
    return await service.perform_device_action(db, id, action_req)

@router.patch("/{id}/rename", response_model=DeviceResponse)
async def rename_device(
    id: uuid.UUID,
    req: DeviceActionRequest,
    db: AsyncSession = Depends(get_db)
):
    """Cosmetic update to device display label."""
    req.action_type = "rename"
    return await service.perform_device_action(db, id, req)

@router.post("/{id}/transfer", response_model=DeviceResponse)
async def transfer_device(
    id: uuid.UUID,
    req: DeviceTransferRequest,
    db: AsyncSession = Depends(get_db)
):
    """Reassign primary user for this physical device."""
    action_req = DeviceActionRequest(
        action_type="transfer",
        reason=req.reason,
        transfer_to_user_id=req.to_user_id
    )
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/revoke", response_model=DeviceResponse)
async def revoke_device_license(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Revoke license; queues local data erase + login disable for next reconnect."""
    action_req = req or DeviceActionRequest(action_type="revoke")
    action_req.action_type = "revoke"
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/force-sync", response_model=DeviceResponse)
async def force_sync_device(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Support/Owner-triggered immediate sync check."""
    action_req = req or DeviceActionRequest(action_type="force-sync")
    action_req.action_type = "force-sync"
    return await service.perform_device_action(db, id, action_req)

@router.post("/{id}/sync", response_model=DeviceResponse)
async def trigger_sync(
    id: uuid.UUID,
    req: Optional[DeviceActionRequest] = None,
    db: AsyncSession = Depends(get_db)
):
    """Alias for force-sync from admin console."""
    action_req = req or DeviceActionRequest(action_type="force-sync")
    action_req.action_type = "force-sync"
    return await service.perform_device_action(db, id, action_req)

@router.get("/{id}/logs", response_model=List[AuditLogEntryResponse])
async def get_device_action_logs(
    id: uuid.UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get immutable device action timeline from audit logs."""
    return await service.get_device_logs(db, id)

@router.get("/{id}/sync-logs", response_model=List[SyncLogEntryResponse])
async def get_device_sync_logs(
    id: uuid.UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get sync history for this device."""
    return await service.get_sync_logs(db, id)
