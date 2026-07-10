import uuid
from datetime import date, datetime
from typing import Optional
from sqlalchemy import (
    String, Boolean, Integer, Text, DateTime, Date, Numeric, ForeignKey, UniqueConstraint, REAL
)
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID as PGUUID

from app.infra.database import Base, TimestampMixin, SyncMixin

class StaffAttendance(Base, TimestampMixin, SyncMixin):
    __tablename__ = "staff_attendance"
    __table_args__ = (
        UniqueConstraint('staff_id', 'attendance_date', name='uq_staff_attendance_date'),
        {'extend_existing': True}
    )
    
    attendance_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    attendance_date: Mapped[date] = mapped_column(Date, nullable=False)
    check_in_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    check_out_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(20), nullable=False) # Present / Absent / Half-Day / On-Leave / Holiday
    check_in_method: Mapped[Optional[str]] = mapped_column(String(20)) # Biometric / PIN / Manual / Face
    check_in_lat: Mapped[Optional[float]] = mapped_column(REAL)
    check_in_lng: Mapped[Optional[float]] = mapped_column(REAL)
    marked_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))
    remarks: Mapped[Optional[str]] = mapped_column(Text)
    sync_status: Mapped[str] = mapped_column(String(20), default='synced')


class LeaveType(Base):
    __tablename__ = "leave_types"
    __table_args__ = {'extend_existing': True}
    
    leave_type_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"))
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    max_days_per_year: Mapped[Optional[int]] = mapped_column(Integer)
    is_paid: Mapped[bool] = mapped_column(default=True)


class StaffLeave(Base, SyncMixin):
    __tablename__ = "staff_leave"
    __table_args__ = {'extend_existing': True}
    
    leave_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    leave_type_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("leave_types.leave_type_id", ondelete="RESTRICT"), nullable=False)
    from_date: Mapped[date] = mapped_column(Date, nullable=False)
    to_date: Mapped[date] = mapped_column(Date, nullable=False)
    total_days: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[Optional[str]] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default='Pending') # Pending / Approved / Rejected / Cancelled
    applied_on: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    approved_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))
    approved_on: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    rejection_reason: Mapped[Optional[str]] = mapped_column(Text)
    sync_status: Mapped[str] = mapped_column(String(20), default='synced')


class StaffSalary(Base):
    __tablename__ = "staff_salary"
    __table_args__ = (
        UniqueConstraint('staff_id', 'salary_month', 'salary_year', name='uq_staff_salary_month_year'),
        {'extend_existing': True}
    )
    
    salary_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    salary_month: Mapped[int] = mapped_column(Integer, nullable=False)
    salary_year: Mapped[int] = mapped_column(Integer, nullable=False)
    basic_salary: Mapped[float] = mapped_column(REAL, nullable=False)
    allowances: Mapped[float] = mapped_column(REAL, default=0.0)
    overtime_amount: Mapped[float] = mapped_column(REAL, default=0.0)
    deductions: Mapped[float] = mapped_column(REAL, default=0.0)
    advance_deducted: Mapped[float] = mapped_column(REAL, default=0.0)
    net_salary: Mapped[float] = mapped_column(REAL, nullable=False)
    payment_status: Mapped[str] = mapped_column(String(20), default='Pending')
    payment_date: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    payment_mode: Mapped[Optional[str]] = mapped_column(String(50))
    generated_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))
    remarks: Mapped[Optional[str]] = mapped_column(Text)


class StaffPerformance(Base):
    __tablename__ = "staff_performance"
    __table_args__ = {'extend_existing': True}
    
    performance_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    review_period_start: Mapped[date] = mapped_column(Date, nullable=False)
    review_period_end: Mapped[date] = mapped_column(Date, nullable=False)
    rating: Mapped[float] = mapped_column(REAL, nullable=False)
    attendance_score: Mapped[Optional[float]] = mapped_column(REAL)
    task_completion_score: Mapped[Optional[float]] = mapped_column(REAL)
    remarks: Mapped[Optional[str]] = mapped_column(Text)
    reviewed_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=False)
    review_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class StaffTask(Base, TimestampMixin, SyncMixin):
    __tablename__ = "staff_tasks"
    __table_args__ = {'extend_existing': True}
    
    task_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=False)
    assigned_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    task_title: Mapped[str] = mapped_column(String(255), nullable=False)
    task_description: Mapped[Optional[str]] = mapped_column(Text)
    related_module: Mapped[Optional[str]] = mapped_column(String(50))
    related_record_id: Mapped[Optional[uuid.UUID]] = mapped_column(PGUUID(as_uuid=True))
    priority: Mapped[str] = mapped_column(String(20), default='Medium')
    status: Mapped[str] = mapped_column(String(20), default='Pending')
    due_date: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    completion_notes: Mapped[Optional[str]] = mapped_column(Text)
    completion_photo_url: Mapped[Optional[str]] = mapped_column(Text)


class StaffDocument(Base):
    __tablename__ = "staff_documents"
    __table_args__ = {'extend_existing': True}
    
    document_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    document_type: Mapped[str] = mapped_column(String(50), nullable=False)
    document_number: Mapped[Optional[str]] = mapped_column(String(50))
    file_url: Mapped[Optional[str]] = mapped_column(Text)
    is_verified: Mapped[bool] = mapped_column(default=False)
    verified_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    verified_on: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


class StaffSession(Base):
    __tablename__ = "staff_sessions"
    __table_args__ = {'extend_existing': True}
    
    session_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("devices.id", ondelete="RESTRICT"), nullable=False)
    login_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    logout_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    login_method: Mapped[Optional[str]] = mapped_column(String(50))
    is_active: Mapped[bool] = mapped_column(default=True)
    ip_address: Mapped[Optional[str]] = mapped_column(String(45))
