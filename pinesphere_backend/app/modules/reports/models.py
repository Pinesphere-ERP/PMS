import uuid
from datetime import date
from typing import Optional
from sqlalchemy import (
    String, Integer, Date, Numeric, Boolean, ForeignKey, UniqueConstraint, Text,
)
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB

from app.infra.database import Base, TimestampMixin


class DailyKPISnapshot(Base, TimestampMixin):
    """Immutable daily snapshot of property KPIs, used for cloud reporting and analytics."""
    __tablename__ = "daily_kpi_snapshots"
    __table_args__ = (
        UniqueConstraint("property_id", "snapshot_date", name="uq_daily_kpi_property_date"),
        {'extend_existing': True},
    )

    snapshot_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("properties.property_id"), nullable=False, index=True
    )
    snapshot_date: Mapped[date] = mapped_column(Date, nullable=False)

    occupied_rooms: Mapped[int] = mapped_column(Integer, default=0)
    vacant_rooms: Mapped[int] = mapped_column(Integer, default=0)
    revenue_room_rent: Mapped[float] = mapped_column(Numeric(14, 2), default=0)
    revenue_addons: Mapped[float] = mapped_column(Numeric(14, 2), default=0)
    expenses_amount: Mapped[float] = mapped_column(Numeric(14, 2), default=0)
    outstanding_payments: Mapped[float] = mapped_column(Numeric(14, 2), default=0)
    gst_collected: Mapped[float] = mapped_column(Numeric(14, 2), default=0)


class ReportTemplate(Base, TimestampMixin):
    """User-defined or system report templates stored per property."""
    __tablename__ = "report_templates"
    __table_args__ = {'extend_existing': True}

    template_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("properties.property_id"), nullable=True, index=True
    )
    report_name: Mapped[str] = mapped_column(String(150), nullable=False)
    report_type: Mapped[str] = mapped_column(String(50), nullable=False)
    configuration_json: Mapped[Optional[dict]] = mapped_column(JSONB)


class ScheduledReport(Base, TimestampMixin):
    """Scheduled delivery configuration for a report template."""
    __tablename__ = "scheduled_reports"
    __table_args__ = {'extend_existing': True}

    schedule_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    template_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("report_templates.template_id"), nullable=False, index=True
    )
    recipient_role: Mapped[str] = mapped_column(String(40), nullable=False)
    delivery_channel: Mapped[str] = mapped_column(String(20), nullable=False)
    frequency: Mapped[str] = mapped_column(String(20), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
