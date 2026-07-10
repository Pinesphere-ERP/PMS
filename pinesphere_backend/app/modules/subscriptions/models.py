import uuid
from typing import Optional
from sqlalchemy import String, Integer, ForeignKey, Text, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PGUUID

from app.infra.database import Base, TimestampMixin

class SubscriptionPlan(Base, TimestampMixin):
    __tablename__ = "subscription_plans"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    device_limit: Mapped[int] = mapped_column(Integer, default=5)
    description: Mapped[Optional[str]] = mapped_column(Text)

class Subscription(Base, TimestampMixin):
    __tablename__ = "subscriptions"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    plan_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("subscription_plans.id", ondelete="RESTRICT"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="active")
    start_date: Mapped[Optional[DateTime]] = mapped_column(DateTime)
    end_date: Mapped[Optional[DateTime]] = mapped_column(DateTime)

class License(Base, TimestampMixin):
    __tablename__ = "licenses"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    subscription_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("subscriptions.id", ondelete="CASCADE"), nullable=False)
    license_key: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
