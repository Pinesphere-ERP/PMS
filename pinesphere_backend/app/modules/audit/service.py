from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import Tuple, List
import uuid

from app.infra.models import AuditLog
from .schemas import AuditLogResponse

class AuditService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_audit_logs(self, property_id: uuid.UUID = None, skip: int = 0, limit: int = 20) -> Tuple[List[AuditLog], int]:
        query = select(AuditLog)
        
        # If a property is specified, filter by it. Super admins might request all.
        if property_id:
            query = query.filter(AuditLog.property_id == property_id)
            
        # Get total count
        count_query = select(func.count(AuditLog.id))
        if property_id:
            count_query = count_query.filter(AuditLog.property_id == property_id)
            
        total_result = await self.db.execute(count_query)
        total = total_result.scalar() or 0
        
        # Get paginated results
        query = query.order_by(AuditLog.timestamp.desc()).offset(skip).limit(limit)
        result = await self.db.execute(query)
        logs = result.scalars().all()
        
        return logs, total
import hashlib
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import select, func, desc, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session

from app.infra.models import AuditLog


GENESIS_HASH = "0" * 64


def _compute_entry_hash(
    previous_hash: str,
    timestamp: datetime,
    user_id: Optional[uuid.UUID],
    action_type: str,
    new_value: Optional[dict],
    old_value: Optional[dict],
) -> str:
    parts = [
        previous_hash or GENESIS_HASH,
        timestamp.isoformat() if timestamp else "",
        str(user_id) if user_id else "",
        action_type or "",
        str(old_value) if old_value else "",
        str(new_value) if new_value else "",
    ]
    raw = "||".join(parts)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


async def _get_previous_hash(
    db: AsyncSession,
    property_id: Optional[uuid.UUID],
) -> str:
    if property_id:
        stmt = select(AuditLog.entry_hash).where(AuditLog.property_id == property_id)
    else:
        stmt = select(AuditLog.entry_hash).where(AuditLog.property_id.is_(None))

    stmt = stmt.order_by(desc(AuditLog.timestamp)).limit(1)
    result = await db.execute(stmt)
    row = result.scalar_one_or_none()
    return row or GENESIS_HASH


async def log_entry(
    db: AsyncSession,
    *,
    property_id: Optional[uuid.UUID] = None,
    user_id: Optional[uuid.UUID] = None,
    device_id: Optional[str] = None,
    module_name: str,
    action_type: str,
    target_entity: str,
    target_record_id: uuid.UUID,
    old_value: Optional[dict] = None,
    new_value: Optional[dict] = None,
    ip_address: Optional[str] = None,
    timestamp: Optional[datetime] = None,
) -> AuditLog:
    ts = timestamp or datetime.utcnow()
    prev_hash = await _get_previous_hash(db, property_id)
    entry_hash = _compute_entry_hash(prev_hash, ts, user_id, action_type, new_value, old_value)

    entry = AuditLog(
        log_id=uuid.uuid4(),
        property_id=property_id,
        user_id=user_id,
        device_id=device_id,
        timestamp=ts,
        module_name=module_name,
        action_type=action_type,
        target_entity=target_entity,
        target_record_id=target_record_id,
        old_value_snapshot=old_value,
        new_value_snapshot=new_value,
        ip_address=ip_address,
        previous_log_hash=prev_hash,
        entry_hash=entry_hash,
    )
    db.add(entry)
    return entry


async def query_logs(
    db: AsyncSession,
    *,
    property_id: Optional[uuid.UUID] = None,
    module_name: Optional[str] = None,
    action_type: Optional[str] = None,
    target_entity: Optional[str] = None,
    target_record_id: Optional[uuid.UUID] = None,
    user_id: Optional[uuid.UUID] = None,
    since: Optional[datetime] = None,
    until: Optional[datetime] = None,
    skip: int = 0,
    limit: int = 50,
) -> tuple[list[AuditLog], int]:
    filters = []
    if property_id is not None:
        filters.append(AuditLog.property_id == property_id)
    if module_name is not None:
        filters.append(AuditLog.module_name == module_name)
    if action_type is not None:
        filters.append(AuditLog.action_type == action_type)
    if target_entity is not None:
        filters.append(AuditLog.target_entity == target_entity)
    if target_record_id is not None:
        filters.append(AuditLog.target_record_id == target_record_id)
    if user_id is not None:
        filters.append(AuditLog.user_id == user_id)
    if since is not None:
        filters.append(AuditLog.timestamp >= since)
    if until is not None:
        filters.append(AuditLog.timestamp <= until)

    where = and_(*filters) if filters else True

    stmt = (
        select(AuditLog)
        .where(where)
        .order_by(desc(AuditLog.timestamp))
        .offset(skip)
        .limit(limit)
    )
    result = await db.execute(stmt)
    logs = list(result.scalars().all())

    count_stmt = select(func.count(AuditLog.log_id)).where(where)
    count_result = await db.execute(count_stmt)
    total = count_result.scalar() or 0

    return logs, total


async def verify_chain(
    db: AsyncSession,
    *,
    property_id: Optional[uuid.UUID] = None,
) -> dict:
    if property_id:
        stmt = select(AuditLog).where(AuditLog.property_id == property_id)
    else:
        stmt = select(AuditLog).where(AuditLog.property_id.is_(None))

    stmt = stmt.order_by(AuditLog.timestamp)
    result = await db.execute(stmt)
    entries = list(result.scalars().all())

    if not entries:
        return {
            "valid": True,
            "total_entries": 0,
            "verified_entries": 0,
            "first_break_log_id": None,
            "first_break_timestamp": None,
            "message": "No entries to verify",
        }

    prev_hash = GENESIS_HASH
    for entry in entries:
        expected_hash = _compute_entry_hash(
            prev_hash,
            entry.timestamp,
            entry.user_id,
            entry.action_type,
            entry.new_value_snapshot,
            entry.old_value_snapshot,
        )
        if entry.entry_hash != expected_hash:
            return {
                "valid": False,
                "total_entries": len(entries),
                "verified_entries": entries.index(entry),
                "first_break_log_id": entry.log_id,
                "first_break_timestamp": entry.timestamp,
                "message": f"Chain broken at log {entry.log_id} ({entry.timestamp})",
            }
        prev_hash = entry.entry_hash

    return {
        "valid": True,
        "total_entries": len(entries),
        "verified_entries": len(entries),
        "first_break_log_id": None,
        "first_break_timestamp": None,
        "message": f"Chain intact: {len(entries)} entries verified",
    }


def log_entry_sync(
    db: Session,
    *,
    property_id: Optional[uuid.UUID] = None,
    user_id: Optional[uuid.UUID] = None,
    device_id: Optional[str] = None,
    module_name: str,
    action_type: str,
    target_entity: str,
    target_record_id: uuid.UUID,
    old_value: Optional[dict] = None,
    new_value: Optional[dict] = None,
    ip_address: Optional[str] = None,
    timestamp: Optional[datetime] = None,
) -> AuditLog:
    ts = timestamp or datetime.utcnow()
    if property_id:
        stmt = select(AuditLog.entry_hash).where(AuditLog.property_id == property_id)
    else:
        stmt = select(AuditLog.entry_hash).where(AuditLog.property_id.is_(None))

    stmt = stmt.order_by(desc(AuditLog.timestamp)).limit(1)
    result = db.execute(stmt)
    prev_hash = result.scalar_one_or_none() or GENESIS_HASH

    entry_hash = _compute_entry_hash(prev_hash, ts, user_id, action_type, new_value, old_value)

    entry = AuditLog(
        log_id=uuid.uuid4(),
        property_id=property_id,
        user_id=user_id,
        device_id=device_id,
        timestamp=ts,
        module_name=module_name,
        action_type=action_type,
        target_entity=target_entity,
        target_record_id=target_record_id,
        old_value_snapshot=old_value,
        new_value_snapshot=new_value,
        ip_address=ip_address,
        previous_log_hash=prev_hash,
        entry_hash=entry_hash,
    )
    db.add(entry)
    return entry
