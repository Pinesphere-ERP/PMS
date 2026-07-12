import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session

from app.modules.audit import service as audit_service


class AuditLogger:
    @staticmethod
    async def log(
        db: AsyncSession,
        *,
        module_name: str,
        action_type: str,
        target_entity: str,
        target_record_id: uuid.UUID,
        property_id: Optional[uuid.UUID] = None,
        user_id: Optional[uuid.UUID] = None,
        device_id: Optional[str] = None,
        old_value: Optional[dict] = None,
        new_value: Optional[dict] = None,
        ip_address: Optional[str] = None,
        timestamp: Optional[datetime] = None,
    ):
        await audit_service.log_entry(
            db,
            property_id=property_id,
            user_id=user_id,
            device_id=device_id,
            module_name=module_name,
            action_type=action_type,
            target_entity=target_entity,
            target_record_id=target_record_id,
            old_value=old_value,
            new_value=new_value,
            ip_address=ip_address,
            timestamp=timestamp,
        )

    @staticmethod
    def log_sync(
        db: Session,
        *,
        module_name: str,
        action_type: str,
        target_entity: str,
        target_record_id: uuid.UUID,
        property_id: Optional[uuid.UUID] = None,
        user_id: Optional[uuid.UUID] = None,
        device_id: Optional[str] = None,
        old_value: Optional[dict] = None,
        new_value: Optional[dict] = None,
        ip_address: Optional[str] = None,
        timestamp: Optional[datetime] = None,
    ):
        audit_service.log_entry_sync(
            db,
            property_id=property_id,
            user_id=user_id,
            device_id=device_id,
            module_name=module_name,
            action_type=action_type,
            target_entity=target_entity,
            target_record_id=target_record_id,
            old_value=old_value,
            new_value=new_value,
            ip_address=ip_address,
            timestamp=timestamp,
        )
