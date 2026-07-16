import uuid
import logging
from datetime import datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, insert, delete
from fastapi import HTTPException, status
import json

from .schemas import SyncPushRequest, SyncPushResponse, SyncPullRequest, SyncPullResponse, SyncPayload
from app.infra import models

logger = logging.getLogger(__name__)

# Map string entity types from the mobile app to actual SQLAlchemy models
ENTITY_MAP = {
    "Property": models.Property,
    "Room": models.Room,
    "RoomCategory": models.RoomCategory,
    "Guest": models.Guest,
    "Booking": models.Booking,
    "CheckIn": models.CheckIn,
    "CheckOut": models.CheckOut,
    "Payment": models.Payment,
    "HousekeepingTask": models.HousekeepingTask,
    "MaintenanceTicket": models.MaintenanceTicket,
    "User": models.User,
    "Role": models.Role,
    "RolePermission": models.RolePermission
}

PUSH_ALLOWED_ENTITIES = {
    "Room", "RoomCategory", "Guest", "Booking", 
    "CheckIn", "CheckOut", "Payment", 
    "HousekeepingTask", "MaintenanceTicket"
}

class SyncService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def push(self, request: SyncPushRequest) -> SyncPushResponse:
        accepted_ids = []
        conflicts = []
        failed_ids = []

        active_property_id = request.property_id
        now_utc = datetime.now(timezone.utc)
        # Allow 5 minutes of clock skew
        max_future_ts = now_utc + timedelta(minutes=5)

        for record in request.records:
            # 1. Whitelist validation
            model = ENTITY_MAP.get(record.entity_type)
            if not model or record.entity_type not in PUSH_ALLOWED_ENTITIES:
                logger.warning(f"Sync reject: Entity type {record.entity_type} not allowed for push")
                failed_ids.append(record.entity_id)
                continue

            # 2. Property ownership validation
            payload_property_id_str = record.payload.get("property_id")
            if hasattr(model, "property_id"):
                if not payload_property_id_str:
                    logger.warning(f"Sync reject: Missing property_id in payload for {record.entity_type} {record.entity_id}")
                    failed_ids.append(record.entity_id)
                    continue
                try:
                    payload_property_id = uuid.UUID(str(payload_property_id_str))
                except ValueError:
                    logger.warning(f"Sync reject: Invalid property_id UUID for {record.entity_type} {record.entity_id}")
                    failed_ids.append(record.entity_id)
                    continue

                if payload_property_id != active_property_id:
                    logger.warning(f"Sync reject: Cross-property update attempt for {record.entity_type} {record.entity_id} (payload: {payload_property_id}, active: {active_property_id})")
                    failed_ids.append(record.entity_id)
                    continue

            # 3. Timestamp validation
            record_ts = record.updated_at.replace(tzinfo=timezone.utc) if not record.updated_at.tzinfo else record.updated_at
            if record_ts > max_future_ts:
                logger.warning(f"Sync reject: Future timestamp {record_ts} for {record.entity_type} {record.entity_id}")
                failed_ids.append(record.entity_id)
                continue

            try:
                # Find existing record if any
                pk_col = getattr(model, "id", None)
                if not pk_col:
                    # Some models use specific PK names, e.g. room_id
                    pk_name = [c.name for c in model.__table__.primary_key][0]
                    pk_col = getattr(model, pk_name)

                try:
                    entity_uuid = uuid.UUID(record.entity_id)
                except ValueError:
                    entity_uuid = record.entity_id

                existing_result = await self.db.execute(select(model).filter(pk_col == entity_uuid))
                existing = existing_result.scalars().first()

                if existing:
                    # LWW (Last Write Wins) Conflict Resolution
                    if hasattr(existing, "updated_at") and existing.updated_at:
                        existing_ts = existing.updated_at.replace(tzinfo=timezone.utc) if not existing.updated_at.tzinfo else existing.updated_at
                        
                        if existing_ts > record_ts:
                            logger.info(f"Sync conflict: {record.entity_type} {record.entity_id} - Server TS {existing_ts} > Client TS {record_ts}")
                            conflicts.append({
                                "entity_type": record.entity_type,
                                "entity_id": record.entity_id,
                                "server_updated_at": existing_ts.isoformat()
                            })
                            continue

                if record.operation == "CREATE":
                    if not existing:
                        new_instance = model(**record.payload)
                        # Ensure PK is set
                        setattr(new_instance, pk_col.name, entity_uuid)
                        self.db.add(new_instance)
                
                elif record.operation == "UPDATE":
                    if existing:
                        for key, value in record.payload.items():
                            if hasattr(existing, key) and key != pk_col.name:
                                setattr(existing, key, value)
                    else:
                        # Upsert if missing
                        new_instance = model(**record.payload)
                        setattr(new_instance, pk_col.name, entity_uuid)
                        self.db.add(new_instance)

                elif record.operation == "DELETE":
                    if existing:
                        await self.db.delete(existing)

                accepted_ids.append(record.entity_id)

            except Exception as e:
                logger.error(f"Sync error for {record.entity_type} {record.entity_id}: {str(e)}")
                failed_ids.append(record.entity_id)

        await self.db.commit()

        logger.info(f"Sync push complete: {len(accepted_ids)} accepted, {len(conflicts)} conflicts, {len(failed_ids)} failed")

        return SyncPushResponse(
            accepted_ids=accepted_ids,
            conflicts=conflicts,
            failed_ids=failed_ids
        )

    async def pull(self, request: SyncPullRequest) -> SyncPullResponse:
        records_to_send = []
        pull_ts = request.last_sync_timestamp.replace(tzinfo=None) # Depending on DB tz settings

        for entity_type, model in ENTITY_MAP.items():
            if not hasattr(model, "updated_at"):
                continue

            # For platform models (in public schema), they might still use property_id
            # For tenant models, the session is already scoped via search_path
            filters = [model.updated_at > pull_ts]
            if hasattr(model, "property_id"):
                filters.append(model.property_id == request.property_id)

            query = select(model).filter(*filters)
            result = await self.db.execute(query)
            changed_rows = result.scalars().all()

            pk_name = [c.name for c in model.__table__.primary_key][0]

            for row in changed_rows:
                # Convert row to dict. Exclude internal SQLAlchemy state
                payload = {c.name: getattr(row, c.name) for c in model.__table__.columns}
                
                # Format dates/uuids for JSON payload
                for k, v in payload.items():
                    if isinstance(v, uuid.UUID):
                        payload[k] = str(v)
                    elif isinstance(v, datetime):
                        payload[k] = v.isoformat()

                records_to_send.append(SyncPayload(
                    entity_type=entity_type,
                    entity_id=str(getattr(row, pk_name)),
                    operation="UPDATE", # Client will upsert
                    payload=payload,
                    updated_at=row.updated_at,
                    device_timestamp=datetime.utcnow()
                ))

        logger.info(f"Sync pull complete: Sent {len(records_to_send)} records to client")

        return SyncPullResponse(
            records=records_to_send,
            server_timestamp=datetime.utcnow()
        )
