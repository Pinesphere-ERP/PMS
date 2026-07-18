"""
Security Dashboard — Incidents, device blacklist, KPIs, and account management.
"""
import uuid
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func

from app.infra.database import get_db
from app.infra.models import SecurityIncident, DeviceBlacklist, User, Device, SecurityCamera, Watchlist
from app.core.dependencies import get_current_user, require_super_admin, assert_property_access

router = APIRouter()


# ──────────────────────────────────────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────────────────────────────────────

class IncidentCreate(BaseModel):
    incident_type: str  # brute_force, blacklisted_device, unauthorized_access, data_anomaly
    severity: str = "medium"  # low, medium, high, critical
    property_id: Optional[uuid.UUID] = None
    user_id: Optional[uuid.UUID] = None
    device_uid: Optional[str] = None
    ip_address: Optional[str] = None
    description: Optional[str] = None

class BlacklistCreate(BaseModel):
    device_uid: str
    reason: str

class SecurityCameraCreate(BaseModel):
    name: str
    location: str
    ip_address: Optional[str] = None
    status: str = "online"

class WatchlistCreate(BaseModel):
    person_name: Optional[str] = None
    id_number: Optional[str] = None
    reason: str


# ──────────────────────────────────────────────────────────────────────────────
# KPI Dashboard
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/kpis", dependencies=[Depends(require_super_admin)])
async def get_security_kpis(db: AsyncSession = Depends(get_db)):
    """Global security KPIs for the Super Admin security dashboard."""
    total_q = await db.execute(select(func.count(SecurityIncident.id)))
    total = total_q.scalar() or 0

    open_q = await db.execute(
        select(func.count(SecurityIncident.id)).where(SecurityIncident.status == "open")
    )
    open_count = open_q.scalar() or 0

    critical_q = await db.execute(
        select(func.count(SecurityIncident.id)).where(
            SecurityIncident.severity == "critical",
            SecurityIncident.status == "open",
        )
    )
    critical = critical_q.scalar() or 0

    blacklist_q = await db.execute(
        select(func.count(DeviceBlacklist.id)).where(DeviceBlacklist.lifted_at.is_(None))
    )
    blacklisted = blacklist_q.scalar() or 0

    return {
        "kpis": [
            {"name": "Total Incidents", "value": str(total), "icon": "ShieldAlert", "color": "text-red-600", "bg": "bg-red-50"},
            {"name": "Open Incidents", "value": str(open_count), "icon": "AlertTriangle", "color": "text-orange-600", "bg": "bg-orange-50"},
            {"name": "Critical (Open)", "value": str(critical), "icon": "Flame", "color": "text-red-700", "bg": "bg-red-100"},
            {"name": "Blacklisted Devices", "value": str(blacklisted), "icon": "Ban", "color": "text-purple-600", "bg": "bg-purple-50"},
        ]
    }


# ──────────────────────────────────────────────────────────────────────────────
# Incidents
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/incidents", dependencies=[Depends(require_super_admin)])
async def list_incidents(
    status_filter: Optional[str] = Query(None, alias="status"),
    severity: Optional[str] = Query(None),
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(SecurityIncident).order_by(SecurityIncident.created_at.desc()).limit(limit)
    if status_filter:
        stmt = stmt.where(SecurityIncident.status == status_filter)
    if severity:
        stmt = stmt.where(SecurityIncident.severity == severity)
    result = await db.execute(stmt)
    incidents = result.scalars().all()
    return [
        {
            "id": str(i.id),
            "incident_type": i.incident_type,
            "severity": i.severity,
            "status": i.status,
            "property_id": str(i.property_id) if i.property_id else None,
            "user_id": str(i.user_id) if i.user_id else None,
            "device_uid": i.device_uid,
            "ip_address": i.ip_address,
            "description": i.description,
            "created_at": i.created_at.isoformat() if i.created_at else None,
            "resolved_at": i.resolved_at.isoformat() if i.resolved_at else None,
        }
        for i in incidents
    ]


@router.post("/incidents", status_code=status.HTTP_201_CREATED)
async def create_incident(
    req: IncidentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a security incident (auto-created by system or manually by admin)."""
    incident = SecurityIncident(
        id=uuid.uuid4(),
        incident_type=req.incident_type,
        severity=req.severity,
        property_id=req.property_id,
        user_id=req.user_id,
        device_uid=req.device_uid,
        ip_address=req.ip_address,
        description=req.description,
        status="open",
    )
    db.add(incident)
    await db.commit()
    return {"id": str(incident.id), "message": "Incident recorded."}


@router.post("/incidents/{incident_id}/resolve", dependencies=[Depends(require_super_admin)])
async def resolve_incident(
    incident_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    stmt = select(SecurityIncident).where(SecurityIncident.id == incident_id)
    result = await db.execute(stmt)
    incident = result.scalars().first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    incident.status = "resolved"
    incident.resolved_at = datetime.utcnow()
    incident.resolved_by = current_user.id
    await db.commit()
    return {"message": "Incident resolved."}


# ──────────────────────────────────────────────────────────────────────────────
# Device Blacklist
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/blacklist", dependencies=[Depends(require_super_admin)], status_code=status.HTTP_201_CREATED)
async def blacklist_device(
    req: BlacklistCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add a device UID to the global blacklist."""
    # Check if already blacklisted
    existing = await db.execute(
        select(DeviceBlacklist).where(DeviceBlacklist.device_uid == req.device_uid, DeviceBlacklist.lifted_at.is_(None))
    )
    if existing.scalars().first():
        raise HTTPException(status_code=409, detail="Device already blacklisted.")

    entry = DeviceBlacklist(
        id=uuid.uuid4(),
        device_uid=req.device_uid,
        reason=req.reason,
        blacklisted_by=current_user.id,
    )
    db.add(entry)
    await db.commit()
    return {"message": f"Device {req.device_uid} blacklisted."}


@router.delete("/blacklist/{entry_id}", dependencies=[Depends(require_super_admin)])
async def lift_blacklist(
    entry_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Lift a device blacklist entry."""
    stmt = select(DeviceBlacklist).where(DeviceBlacklist.id == entry_id)
    result = await db.execute(stmt)
    entry = result.scalars().first()
    if not entry:
        raise HTTPException(status_code=404, detail="Blacklist entry not found")
    entry.lifted_at = datetime.utcnow()
    await db.commit()
    return {"message": "Blacklist entry lifted."}


@router.get("/blacklist", dependencies=[Depends(require_super_admin)])
async def list_blacklisted_devices(db: AsyncSession = Depends(get_db)):
    stmt = select(DeviceBlacklist).where(DeviceBlacklist.lifted_at.is_(None))
    result = await db.execute(stmt)
    return [
        {
            "id": str(e.id),
            "device_uid": e.device_uid,
            "reason": e.reason,
            "blacklisted_at": e.blacklisted_at.isoformat() if e.blacklisted_at else None,
        }
        for e in result.scalars().all()
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Security Cameras
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/cameras", status_code=status.HTTP_201_CREATED)
async def create_camera(
    req: SecurityCameraCreate,
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    camera = SecurityCamera(
        id=uuid.uuid4(),
        property_id=property_id,
        name=req.name,
        location=req.location,
        ip_address=req.ip_address,
        status=req.status,
    )
    db.add(camera)
    await db.commit()
    return {"id": str(camera.id), "message": "Camera added."}

@router.get("/cameras")
async def list_cameras(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = select(SecurityCamera).where(SecurityCamera.property_id == property_id, SecurityCamera.is_active == True)
    result = await db.execute(stmt)
    return [
        {
            "id": str(c.id),
            "name": c.name,
            "location": c.location,
            "ip_address": c.ip_address,
            "status": c.status,
        }
        for c in result.scalars().all()
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Watchlist
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/watchlist", status_code=status.HTTP_201_CREATED)
async def add_to_watchlist(
    req: WatchlistCreate,
    property_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if property_id:
        await assert_property_access(property_id, current_user, db)
    entry = Watchlist(
        id=uuid.uuid4(),
        property_id=property_id,
        person_name=req.person_name,
        id_number=req.id_number,
        reason=req.reason,
        created_by=current_user.id,
    )
    db.add(entry)
    await db.commit()
    return {"id": str(entry.id), "message": "Added to watchlist."}

@router.get("/watchlist")
async def get_watchlist(
    property_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    stmt = select(Watchlist).where(Watchlist.is_active == True)
    if property_id:
        await assert_property_access(property_id, current_user, db)
        stmt = stmt.where(Watchlist.property_id == property_id)
    result = await db.execute(stmt)
    return [
        {
            "id": str(w.id),
            "person_name": w.person_name,
            "id_number": w.id_number,
            "reason": w.reason,
            "property_id": str(w.property_id) if w.property_id else None,
        }
        for w in result.scalars().all()
    ]

