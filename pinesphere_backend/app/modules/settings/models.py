import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import String, Text, Boolean, Integer, DateTime, ForeignKey, Index, text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PGUUID

from app.infra.database import Base, TimestampMixin, SyncMixin


class SystemConfiguration(Base, TimestampMixin):
    """Global SaaS-level configuration values managed by Super Admin.
    Cloud-only; never synced to devices.
    """
    __tablename__ = "system_configurations"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    config_key: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    config_value: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    updated_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))


class PropertySetting(Base, TimestampMixin, SyncMixin):
    """Per-property operational rules (check-in time, GST, currency, etc.).
    Synced to devices via the existing outbox pattern.
    """
    __tablename__ = "property_settings"
    __table_args__ = (
        Index(
            "uq_property_settings_active_key",
            "property_id", "setting_key",
            unique=True,
            postgresql_where=text("is_deleted = FALSE"),
            sqlite_where=text("is_deleted = FALSE"),
        ),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False, index=True
    )
    setting_key: Mapped[str] = mapped_column(String(100), nullable=False)
    setting_value: Mapped[str] = mapped_column(Text, nullable=False)
    value_type: Mapped[str] = mapped_column(String(20), nullable=False, default="string")
    description: Mapped[Optional[str]] = mapped_column(Text)
    updated_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
