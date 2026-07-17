from typing import Optional
from pydantic import BaseModel, ConfigDict
import uuid
from datetime import datetime

class NotificationResponse(BaseModel):
    notification_id: uuid.UUID
    recipient_id: uuid.UUID
    title: str
    message: str
    channel: str
    priority: str
    status: str
    read_at: Optional[datetime]
    payload: Optional[dict]
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
