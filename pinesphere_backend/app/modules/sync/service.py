import uuid
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, insert, delete
from fastapi import HTTPException, status
import json

from .schemas import SyncPushRequest, SyncPushResponse, SyncPullRequest, SyncPullResponse, SyncPayload
from app.infra import models

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
    "MaintenanceTicket": models.MaintenanceTicket
}

class SyncService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def push(self, request: SyncPushRequest) -> SyncPushResponse:
        accepted_ids = []
        conflicts = []
        failed_ids = []

        for record in request.records:
            model = ENTITY_MAP.get(record.entity_type)
            if not model:
                failed_ids.append(record.entity_id)
                continue

            try:
                # Find existing record if any
                pk_col = getattr(model, "id", None)
                if not pk_col:
                    # Some models use specific PK names, e.g. room_id
                    pk_name = [c.name for c in model.__table__.primary_key][0]
                    pk_col = getattr(model, pk_name)

                existing_result = await self.db.execute(select(model).filter(pk_col == record.entity_id))
                existing = existing_result.scalars().first()

                if existing:
                    # LWW (Last Write Wins) Conflict Resolution
                    # Assuming models have updated_at inherited from SyncMixin or TimestampMixin
                    if hasattr(existing, "updated_at") and existing.updated_at:
                        # Make timezone aware for comparison
                        existing_ts = existing.updated_at.replace(tzinfo=timezone.utc) if not existing.updated_at.tzinfo else existing.updated_at
                        record_ts = record.updated_at.replace(tzinfo=timezone.utc) if not record.updated_at.tzinfo else record.updated_at
                        
                        if existing_ts > record_ts:
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
                        setattr(new_instance, pk_col.name, record.entity_id)
                        self.db.add(new_instance)
                
                elif record.operation == "UPDATE":
                    if existing:
                        for key, value in record.payload.items():
                            if hasattr(existing, key) and key != pk_col.name:
                                setattr(existing, key, value)
                    else:
                        # Upsert if missing
                        new_instance = model(**record.payload)
                        setattr(new_instance, pk_col.name, record.entity_id)
                        self.db.add(new_instance)

                elif record.operation == "DELETE":
                    if existing:
                        await self.db.delete(existing)

                accepted_ids.append(record.entity_id)

            except Exception as e:
                print(f"Sync error for {record.entity_type} {record.entity_id}: {str(e)}")
                failed_ids.append(record.entity_id)

        await self.db.commit()

        return SyncPushResponse(
            accepted_ids=accepted_ids,
            conflicts=conflicts,
            failed_ids=failed_ids
        )

    async def pull(self, request: SyncPullRequest) -> SyncPullResponse:
        records_to_send = []
        pull_ts = request.last_sync_timestamp.replace(tzinfo=None) # Depending on DB tz settings

        for entity_type, model in ENTITY_MAP.items():
            if not hasattr(model, "updated_at") or not hasattr(model, "property_id"):
                continue

            query = select(model).filter(
                model.property_id == request.property_id,
                model.updated_at > pull_ts
            )
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

        return SyncPullResponse(
            records=records_to_send,
            server_timestamp=datetime.utcnow()
        )
