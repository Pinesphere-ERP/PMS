"""
Security Guard Module — Visitor registry, vehicle log, and incident reports.
All incident reports are immutable once created.
"""
import uuid
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.database import get_db
from app.infra.models import VisitorLog, VehicleLog, PropertyIncidentReport, User
from app.core.dependencies import get_current_user, assert_property_access

router = APIRouter()


# ──────────────────────────────────────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────────────────────────────────────

class VisitorLogCreate(BaseModel):
    property_id: uuid.UUID
    visitor_name: str
    visitor_mobile: Optional[str] = None
    host_user_id: Optional[uuid.UUID] = None
    host_room: Optional[str] = None
    purpose: Optional[str] = None
    id_type: Optional[str] = None
    id_number: Optional[str] = None
    photo_url: Optional[str] = None

class VehicleLogCreate(BaseModel):
    property_id: uuid.UUID
    plate_number: str
    vehicle_type: Optional[str] = None
    driver_name: Optional[str] = None
    notes: Optional[str] = None

class IncidentReportCreate(BaseModel):
    property_id: uuid.UUID
    incident_type: str  # theft, altercation, fire, medical, damage, other
    location: Optional[str] = None
    description: str
    severity: str = "medium"  # low, medium, high, critical
    witness_name: Optional[str] = None
    photo_url: Optional[str] = None


# ──────────────────────────────────────────────────────────────────────────────
# Visitor Log
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/visitors", status_code=status.HTTP_201_CREATED)
async def log_visitor_entry(
    payload: VisitorLogCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Record a visitor entry. Returns visitor log ID."""
    await assert_property_access(payload.property_id, current_user, db)
    log = VisitorLog(
        id=uuid.uuid4(),
        property_id=payload.property_id,
        visitor_name=payload.visitor_name,
        visitor_mobile=payload.visitor_mobile,
        host_user_id=payload.host_user_id,
        host_room=payload.host_room,
        purpose=payload.purpose,
        id_type=payload.id_type,
        id_number=payload.id_number,
        photo_url=payload.photo_url,
        logged_by=current_user.id,
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return {"id": str(log.id), "message": "Visitor entry logged."}


@router.post("/visitors/{visitor_id}/exit")
async def log_visitor_exit(
    visitor_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Record the exit time for a visitor."""
    await assert_property_access(property_id, current_user, db)
    stmt = select(VisitorLog).where(VisitorLog.id == visitor_id, VisitorLog.property_id == property_id)
    result = await db.execute(stmt)
    log = result.scalars().first()
    if not log:
        raise HTTPException(status_code=404, detail="Visitor log not found")
    if log.exit_at:
        raise HTTPException(status_code=409, detail="Visitor has already exited")
    log.exit_at = datetime.utcnow()
    await db.commit()
    return {"message": "Visitor exit recorded."}


@router.get("/visitors")
async def list_visitors(
    property_id: uuid.UUID = Query(...),
    active_only: bool = Query(False),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List today's visitor log entries."""
    await assert_property_access(property_id, current_user, db)
    stmt = select(VisitorLog).where(VisitorLog.property_id == property_id).order_by(VisitorLog.entry_at.desc())
    if active_only:
        stmt = stmt.where(VisitorLog.exit_at.is_(None))
    result = await db.execute(stmt)
    logs = result.scalars().all()
    return [
        {
            "id": str(l.id),
            "visitor_name": l.visitor_name,
            "visitor_mobile": l.visitor_mobile,
            "host_room": l.host_room,
            "purpose": l.purpose,
            "entry_at": l.entry_at.isoformat() if l.entry_at else None,
            "exit_at": l.exit_at.isoformat() if l.exit_at else None,
            "is_inside": l.exit_at is None,
        }
        for l in logs
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Vehicle Log
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/vehicles", status_code=status.HTTP_201_CREATED)
async def log_vehicle_entry(
    payload: VehicleLogCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Record a vehicle entry at the property gate."""
    await assert_property_access(payload.property_id, current_user, db)
    log = VehicleLog(
        id=uuid.uuid4(),
        property_id=payload.property_id,
        plate_number=payload.plate_number.upper().strip(),
        vehicle_type=payload.vehicle_type,
        driver_name=payload.driver_name,
        notes=payload.notes,
        logged_by=current_user.id,
    )
    db.add(log)
    await db.commit()
    return {"id": str(log.id), "message": "Vehicle entry logged."}


@router.post("/vehicles/{vehicle_log_id}/exit")
async def log_vehicle_exit(
    vehicle_log_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = select(VehicleLog).where(VehicleLog.id == vehicle_log_id, VehicleLog.property_id == property_id)
    result = await db.execute(stmt)
    log = result.scalars().first()
    if not log:
        raise HTTPException(status_code=404, detail="Vehicle log not found")
    log.exit_at = datetime.utcnow()
    await db.commit()
    return {"message": "Vehicle exit recorded."}


@router.get("/vehicles")
async def list_vehicles(
    property_id: uuid.UUID = Query(...),
    active_only: bool = Query(False),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = select(VehicleLog).where(VehicleLog.property_id == property_id).order_by(VehicleLog.entry_at.desc())
    if active_only:
        stmt = stmt.where(VehicleLog.exit_at.is_(None))
    result = await db.execute(stmt)
    return [
        {
            "id": str(l.id),
            "plate_number": l.plate_number,
            "vehicle_type": l.vehicle_type,
            "driver_name": l.driver_name,
            "entry_at": l.entry_at.isoformat() if l.entry_at else None,
            "exit_at": l.exit_at.isoformat() if l.exit_at else None,
            "is_inside": l.exit_at is None,
        }
        for l in result.scalars().all()
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Incident Reports (IMMUTABLE — no UPDATE endpoint)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/incidents", status_code=status.HTTP_201_CREATED)
async def file_incident_report(
    payload: IncidentReportCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    File an immutable incident report. Once created, it cannot be edited.
    Amendments must be filed as new reports referencing the original.
    """
    await assert_property_access(payload.property_id, current_user, db)
    report = PropertyIncidentReport(
        id=uuid.uuid4(),
        property_id=payload.property_id,
        reported_by=current_user.id,
        incident_type=payload.incident_type,
        location=payload.location,
        description=payload.description,
        severity=payload.severity,
        witness_name=payload.witness_name,
        photo_url=payload.photo_url,
    )
    db.add(report)
    await db.commit()
    return {
        "id": str(report.id),
        "message": "Incident report filed. This report is immutable and cannot be edited.",
    }


@router.get("/incidents")
async def list_incident_reports(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = (
        select(PropertyIncidentReport)
        .where(PropertyIncidentReport.property_id == property_id)
        .order_by(PropertyIncidentReport.created_at.desc())
    )
    result = await db.execute(stmt)
    return [
        {
            "id": str(r.id),
            "incident_type": r.incident_type,
            "location": r.location,
            "description": r.description,
            "severity": r.severity,
            "reported_by": str(r.reported_by),
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in result.scalars().all()
    ]
