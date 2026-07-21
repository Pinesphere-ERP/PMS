"""
Manager Module — Database Models

These are the manager-specific tables referenced in the PRD:
  - manager_notes
  - room_blocks
  - manager_daily_checklists
  - staff_shifts
"""

import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    String, Text, Boolean, Date, DateTime, ForeignKey,
    UniqueConstraint, Index, JSON, Integer
)
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB

from sqlalchemy.ext.compiler import compiles

@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite_mgr(type_, compiler, **kw):
    return "JSON"

@compiles(PGUUID, "sqlite")
def compile_uuid_sqlite_mgr(type_, compiler, **kw):
    return "CHAR(32)"

from app.infra.database import Base, TimestampMixin, SyncMixin


# ── ManagerNote ───────────────────────────────────────────────────────────────

class ManagerNote(Base, TimestampMixin, SyncMixin):
    """
    Operational notes created by a manager for a property.
    Used to record shift observations, instructions, or flagged issues.
    """
    __tablename__ = "manager_notes"
    __table_args__ = (
        Index("ix_manager_notes_property", "property_id"),
        Index("ix_manager_notes_created_by", "created_by"),
        {'extend_existing': True},
    )

    note_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False
    )
    created_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=False
    )
    # Optional: pin note to a room or booking
    room_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("rooms.room_id", ondelete="SET NULL"), nullable=True
    )
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("bookings.booking_id", ondelete="SET NULL"), nullable=True
    )
    note_type: Mapped[str] = mapped_column(
        String(30), default="general", nullable=False
    )  # general, shift_handover, maintenance, guest, housekeeping
    content: Mapped[str] = mapped_column(Text, nullable=False)
    is_pinned: Mapped[bool] = mapped_column(Boolean, default=False)
    is_resolved: Mapped[bool] = mapped_column(Boolean, default=False)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    resolved_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )


# ── RoomBlock ─────────────────────────────────────────────────────────────────

class RoomBlock(Base, TimestampMixin, SyncMixin):
    """
    Manager-created room blocks that prevent bookings for a date range.
    Reasons: maintenance, renovation, VIP hold, inspection, etc.
    """
    __tablename__ = "room_blocks"
    __table_args__ = (
        Index("ix_room_blocks_property", "property_id"),
        Index("ix_room_blocks_room_dates", "room_id", "from_date", "to_date"),
        {'extend_existing': True},
    )

    block_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False
    )
    room_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("rooms.room_id", ondelete="CASCADE"), nullable=False
    )
    blocked_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=False
    )
    from_date: Mapped[date] = mapped_column(Date, nullable=False)
    to_date: Mapped[date] = mapped_column(Date, nullable=False)
    reason: Mapped[str] = mapped_column(String(30), nullable=False)
    # maintenance, renovation, vip_hold, inspection, deep_cleaning, other
    notes: Mapped[Optional[str]] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    released_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    released_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )


# ── ManagerDailyChecklist ─────────────────────────────────────────────────────

class ManagerDailyChecklist(Base, TimestampMixin, SyncMixin):
    """
    Daily operational checklist completed by a manager.
    Captures shift start/end tasks and sign-off.
    """
    __tablename__ = "manager_daily_checklists"
    __table_args__ = (
        UniqueConstraint(
            "property_id", "manager_id", "checklist_date", "shift",
            name="uq_manager_checklist_date_shift"
        ),
        Index("ix_manager_daily_checklists_property", "property_id"),
        {'extend_existing': True},
    )

    checklist_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False
    )
    manager_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=False
    )
    checklist_date: Mapped[date] = mapped_column(Date, nullable=False)
    shift: Mapped[str] = mapped_column(String(20), default="morning")
    # morning, afternoon, evening, night
    items: Mapped[Optional[dict]] = mapped_column(JSONB, default=dict)
    # {"front_desk_briefed": true, "housekeeping_briefed": false, ...}
    status: Mapped[str] = mapped_column(String(20), default="pending")
    # pending, in_progress, completed, signed_off
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    signed_off_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    signed_off_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


# ── StaffShift ────────────────────────────────────────────────────────────────

class StaffShift(Base, TimestampMixin, SyncMixin):
    """
    Shift schedule for staff members. Manager uses this to determine
    which staff are currently on shift for task assignment validation.
    """
    __tablename__ = "staff_shifts"
    __table_args__ = (
        Index("ix_staff_shifts_property", "property_id"),
        Index("ix_staff_shifts_staff_date", "staff_id", "shift_date"),
        {'extend_existing': True},
    )

    shift_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False
    )
    staff_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    shift_date: Mapped[date] = mapped_column(Date, nullable=False)
    shift_type: Mapped[str] = mapped_column(String(20), nullable=False)
    # morning, afternoon, evening, night, full_day
    start_time: Mapped[Optional[str]] = mapped_column(String(10))  # HH:MM
    end_time: Mapped[Optional[str]] = mapped_column(String(10))    # HH:MM
    status: Mapped[str] = mapped_column(String(20), default="scheduled")
    # scheduled, active, completed, absent
    scheduled_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    notes: Mapped[Optional[str]] = mapped_column(Text)
