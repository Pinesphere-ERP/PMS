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
