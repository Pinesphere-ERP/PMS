import uuid
from datetime import date, datetime, time
from typing import Optional
from sqlalchemy import (
    String, Boolean, Integer, SmallInteger, Text, DateTime, Date, Time,
    Numeric, ForeignKey, Enum, UniqueConstraint, Index, JSON, BIGINT
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB

from app.infra.database import Base, TimestampMixin, SyncMixin

# ── A. Owners & Access ────────────────────────────────────────────────────────

class Owner(Base, TimestampMixin):
    __tablename__ = "owners"
    __table_args__ = {'extend_existing': True}
    owner_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    designation: Mapped[Optional[str]] = mapped_column(String(50))
    mobile_number: Mapped[str] = mapped_column(String(15), unique=True, nullable=False)
    mobile_verified: Mapped[bool] = mapped_column(default=False)
    alternate_contact: Mapped[Optional[str]] = mapped_column(String(15))
    email: Mapped[str] = mapped_column(String(150), unique=True, nullable=False)
    email_verified: Mapped[bool] = mapped_column(default=False)
    pan_number: Mapped[Optional[str]] = mapped_column(String(10))
    aadhaar_number: Mapped[Optional[str]] = mapped_column(String(20))
    selfie_url: Mapped[Optional[str]] = mapped_column(Text)
    password_hash: Mapped[Optional[str]] = mapped_column(Text)


class Business(Base, TimestampMixin):
    __tablename__ = "businesses"
    __table_args__ = {'extend_existing': True}
    business_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("owners.owner_id"), nullable=False)
    business_type: Mapped[Optional[str]] = mapped_column(String(30))
    business_name: Mapped[str] = mapped_column(String(200), nullable=False)
    business_reg_number: Mapped[Optional[str]] = mapped_column(String(50))
    gst_number: Mapped[Optional[str]] = mapped_column(String(15))
    gst_certificate_url: Mapped[Optional[str]] = mapped_column(Text)
    pan_number: Mapped[Optional[str]] = mapped_column(String(10))


# ── B. Properties ─────────────────────────────────────────────────────────────

class Property(Base, TimestampMixin):
    __tablename__ = "properties"
    __table_args__ = {'extend_existing': True}
    property_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.business_id"), nullable=False)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("owners.owner_id"), nullable=False)
    property_name: Mapped[str] = mapped_column(String(200), nullable=False)
    property_type: Mapped[Optional[str]] = mapped_column(String(30))
    star_category: Mapped[Optional[int]] = mapped_column(SmallInteger)
    year_established: Mapped[Optional[int]] = mapped_column(SmallInteger)
    total_floors: Mapped[Optional[int]] = mapped_column(SmallInteger)
    total_rooms: Mapped[Optional[int]] = mapped_column(Integer)
    description: Mapped[Optional[str]] = mapped_column(Text)
    primary_device_id: Mapped[Optional[uuid.UUID]] = mapped_column(PGUUID(as_uuid=True))
    whatsapp_number: Mapped[Optional[str]] = mapped_column(String(15))
    onboarding_status: Mapped[str] = mapped_column(String(20), default='draft')
    created_by_admin_id: Mapped[Optional[uuid.UUID]] = mapped_column(PGUUID(as_uuid=True))


# ── C. Roles & Permissions ────────────────────────────────────────────────────

class Role(Base, TimestampMixin):
    __tablename__ = "roles"
    __table_args__ = (
        UniqueConstraint('property_id', 'role_code', name='uq_roles_property_role_code'),
        {'extend_existing': True}
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"))
    role_code: Mapped[str] = mapped_column(String(40), nullable=False)
    role_name: Mapped[str] = mapped_column(String(80), nullable=False)
    is_system_role: Mapped[bool] = mapped_column(default=True)
    description: Mapped[Optional[str]] = mapped_column(Text)


class Permission(Base):
    __tablename__ = "permissions"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    permission_code: Mapped[str] = mapped_column(String(60), nullable=False, unique=True)
    module_name: Mapped[str] = mapped_column(String(60), nullable=False)


class RolePermission(Base):
    __tablename__ = "role_permissions"
    __table_args__ = (
        UniqueConstraint('role_id', 'permission_id', name='uq_role_permissions'),
        {'extend_existing': True}
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("roles.id", ondelete="CASCADE"), nullable=False)
    permission_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("permissions.id", ondelete="CASCADE"), nullable=False)
    access_level: Mapped[str] = mapped_column(String(20), nullable=False)


# ── D. Users & Devices ────────────────────────────────────────────────────────

class User(Base, TimestampMixin, SyncMixin):
    __tablename__ = "users"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"))
    role_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("roles.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    mobile_number: Mapped[Optional[str]] = mapped_column(String(15))
    email: Mapped[Optional[str]] = mapped_column(String(120))
    password_hash: Mapped[Optional[str]] = mapped_column(String(255))
    pin_hash: Mapped[Optional[str]] = mapped_column(String(255))
    biometric_enabled: Mapped[bool] = mapped_column(default=False)
    is_primary_owner: Mapped[bool] = mapped_column(default=False)
    status: Mapped[str] = mapped_column(String(20), default="ACTIVE")
    failed_login_attempts: Mapped[int] = mapped_column(SmallInteger, default=0)
    profile_photo_url: Mapped[Optional[str]] = mapped_column(Text)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    is_pending_sync: Mapped[bool] = mapped_column(default=False)


class Device(Base, TimestampMixin):
    __tablename__ = "devices"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_uid: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    primary_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    device_name: Mapped[Optional[str]] = mapped_column(String(80))
    os_type: Mapped[Optional[str]] = mapped_column(String(20), default='android')
    status: Mapped[Optional[str]] = mapped_column(String(20), default='pending_approval')


# ── E. Rooms ──────────────────────────────────────────────────────────────────

class RoomCategory(Base, TimestampMixin):
    __tablename__ = "room_categories"
    __table_args__ = {'extend_existing': True}
    room_category_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    room_name: Mapped[Optional[str]] = mapped_column(String(100))
    number_of_rooms: Mapped[Optional[int]] = mapped_column(Integer)
    base_price: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))


class Room(Base, TimestampMixin):
    __tablename__ = "rooms"
    __table_args__ = {'extend_existing': True}
    room_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_category_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("room_categories.room_category_id"), nullable=False)
    room_number: Mapped[str] = mapped_column(String(20), nullable=False)
    housekeeping_status: Mapped[Optional[str]] = mapped_column(String(20), default='clean')
    occupancy_status: Mapped[Optional[str]] = mapped_column(String(20), default='vacant')


# ── F. Guests & Bookings ──────────────────────────────────────────────────────

class Guest(Base, TimestampMixin):
    __tablename__ = "guests"
    __table_args__ = {'extend_existing': True}
    guest_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    mobile: Mapped[Optional[str]] = mapped_column(String(15))
    email: Mapped[Optional[str]] = mapped_column(String(150))


class Booking(Base, TimestampMixin, SyncMixin):
    __tablename__ = "bookings"
    __table_args__ = {'extend_existing': True}
    booking_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    guest_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("guests.guest_id"), nullable=False)
    booking_type: Mapped[Optional[str]] = mapped_column(String(20), default='walkin')
    booking_source: Mapped[Optional[str]] = mapped_column(String(30))
    check_in_date: Mapped[date] = mapped_column(Date, nullable=False)
    check_out_date: Mapped[date] = mapped_column(Date, nullable=False)
    adults: Mapped[int] = mapped_column(Integer, default=1)
    children: Mapped[int] = mapped_column(Integer, default=0)
    room_rent: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    deposit: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    discount: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    taxes: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    total_payable: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    advance_paid: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    pending_amount: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    booking_status: Mapped[Optional[str]] = mapped_column(String(20), default='confirmed')
    payment_status: Mapped[Optional[str]] = mapped_column(String(20), default='pending')
    sync_status: Mapped[Optional[str]] = mapped_column(String(20), default='synced')
    notes: Mapped[Optional[str]] = mapped_column(Text)


class CheckIn(Base, TimestampMixin, SyncMixin):
    __tablename__ = "check_ins"
    __table_args__ = {'extend_existing': True}
    checkin_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    booking_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bookings.booking_id"), nullable=False)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    guest_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("guests.guest_id"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    staff_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    deposit: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    advance_paid: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    id_verified: Mapped[bool] = mapped_column(default=False)
    checked_in_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(20), default='active')
    special_requests: Mapped[Optional[str]] = mapped_column(Text)


class CheckOut(Base, TimestampMixin, SyncMixin):
    __tablename__ = "check_outs"
    __table_args__ = {'extend_existing': True}
    checkout_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    checkin_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("check_ins.checkin_id"), nullable=False)
    booking_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bookings.booking_id"), nullable=False)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    staff_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    checkout_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    total_amount: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    advance_paid: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    remaining_balance: Mapped[Optional[float]] = mapped_column(Numeric(10, 2), default=0)
    payment_status: Mapped[str] = mapped_column(String(20), default='pending')
    checkout_status: Mapped[str] = mapped_column(String(20), default='pending')


class InvoiceItem(Base, TimestampMixin):
    __tablename__ = "invoice_items"
    __table_args__ = {'extend_existing': True}
    item_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("invoices.invoice_id"), nullable=False)
    description: Mapped[str] = mapped_column(String(200), nullable=False)
    category: Mapped[Optional[str]] = mapped_column(String(30))
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    unit_price: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    total_price: Mapped[float] = mapped_column(Numeric(10, 2), default=0)

    remarks: Mapped[Optional[str]] = mapped_column(Text)


# ── G. Audit ──────────────────────────────────────────────────────────────────

class AuditLog(Base):
    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("ix_audit_logs_property_timestamp", "property_id", "timestamp"),
        Index("ix_audit_logs_target", "target_entity", "target_record_id"),
        {'extend_existing': True},
    )
    log_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"))
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    device_id: Mapped[Optional[str]] = mapped_column(String(100))
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, index=True)
    module_name: Mapped[Optional[str]] = mapped_column(String(50), index=True)
    action_type: Mapped[Optional[str]] = mapped_column(String(50))
    target_entity: Mapped[Optional[str]] = mapped_column(String(50))
    target_record_id: Mapped[Optional[uuid.UUID]] = mapped_column(PGUUID(as_uuid=True))
    old_value_snapshot: Mapped[Optional[dict]] = mapped_column(JSONB)
    new_value_snapshot: Mapped[Optional[dict]] = mapped_column(JSONB)
    ip_address: Mapped[Optional[str]] = mapped_column(String(45))
    previous_log_hash: Mapped[Optional[str]] = mapped_column(String(64))
    entry_hash: Mapped[Optional[str]] = mapped_column(String(64))


# ── H. Housekeeping & Maintenance ─────────────────────────────────────────────

class RoomAssignment(Base, TimestampMixin):
    __tablename__ = "room_assignments"
    __table_args__ = {'extend_existing': True}
    assignment_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    booking_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bookings.booking_id"), nullable=False)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    guest_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("guests.guest_id"), nullable=False)
    assigned_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    unassigned_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    is_active: Mapped[bool] = mapped_column(default=True)


class HousekeepingTask(Base, TimestampMixin, SyncMixin):
    __tablename__ = "housekeeping_tasks"
    __table_args__ = {'extend_existing': True}
    task_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    assigned_staff_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(20), default='pending')
    priority: Mapped[str] = mapped_column(String(10), default='medium')
    checklist_status: Mapped[Optional[dict]] = mapped_column(JSONB)
    remarks: Mapped[Optional[str]] = mapped_column(Text)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


class MaintenanceTicket(Base, TimestampMixin, SyncMixin):
    __tablename__ = "maintenance_tickets"
    __table_args__ = {'extend_existing': True}
    ticket_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    reported_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    assigned_to: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    category: Mapped[str] = mapped_column(String(30), nullable=False)
    priority: Mapped[str] = mapped_column(String(10), default='medium')
    issue_description: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default='open')
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


class LostAndFound(Base, TimestampMixin):
    __tablename__ = "lost_and_found"
    __table_args__ = {'extend_existing': True}
    item_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    found_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(20), default='stored')
    photo: Mapped[Optional[str]] = mapped_column(Text)


# ── I. Property Payments (guest billing) ──────────────────────────────────────

class Invoice(Base, TimestampMixin):
    """Guest billing invoice (property-level, for check-out folio)."""
    __tablename__ = "invoices"
    __table_args__ = {'extend_existing': True}
    invoice_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id"))
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    guest_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("guests.guest_id"))
    invoice_number: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    plan: Mapped[Optional[str]] = mapped_column(String(50))          # for subscription invoices
    date: Mapped[date] = mapped_column(Date, nullable=False)
    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    gst: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    status: Mapped[str] = mapped_column(String(20), default="Pending")


class Payment(Base, TimestampMixin, SyncMixin):
    """Guest payment (property-level, recorded by front desk)."""
    __tablename__ = "payments"
    payment_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("invoices.invoice_id"))
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id"))
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    guest_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("guests.guest_id"))
    transaction_id: Mapped[Optional[str]] = mapped_column(String(60))
    payment_method: Mapped[str] = mapped_column(String(20), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    collected_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(20), default='pending')
    remarks: Mapped[Optional[str]] = mapped_column(Text)


# ── J. Admin Subscriptions & Billing ─────────────────────────────────────────

class Subscription(Base, TimestampMixin):
    """Admin-level property subscription (platform plan)."""
    __tablename__ = "subscriptions"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    plan: Mapped[str] = mapped_column(String(50), nullable=False)
    billing_cycle: Mapped[str] = mapped_column(String(20), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    expiry_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="Active")
    license_id: Mapped[Optional[str]] = mapped_column(String(100), unique=True)
    device_limit: Mapped[int] = mapped_column(Integer, default=5)
    registered_devices: Mapped[int] = mapped_column(Integer, default=0)


class PaymentTransaction(Base, TimestampMixin):
    """Admin-level payment record (Pinesphere platform subscription payment)."""
    __tablename__ = "payment_transactions"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    invoice_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("invoices.invoice_id"))
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    method: Mapped[Optional[str]] = mapped_column(String(50))
    status: Mapped[str] = mapped_column(String(20), default="Processing")
    bank_ref: Mapped[Optional[str]] = mapped_column(String(100))


class PendingDue(Base, TimestampMixin):
    """Tracks overdue/unpaid subscription amounts."""
    __tablename__ = "pending_dues"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    plan: Mapped[str] = mapped_column(String(50), nullable=False)
    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    amount_due: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    days_overdue: Mapped[int] = mapped_column(Integer, default=0)
    reminder_status: Mapped[Optional[str]] = mapped_column(String(100))


# ── K. Invoice Items (guest billing line items) ───────────────────────────────

class InvoiceItem(Base, TimestampMixin):
    __tablename__ = "invoice_items"
    __table_args__ = {'extend_existing': True}
    item_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("invoices.invoice_id"), nullable=False)
    description: Mapped[str] = mapped_column(String(200), nullable=False)
    category: Mapped[Optional[str]] = mapped_column(String(30))
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    unit_price: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    total_price: Mapped[float] = mapped_column(Numeric(10, 2), default=0)


# ── L. Split Payments ─────────────────────────────────────────────────────────

class SplitPayment(Base, TimestampMixin):
    __tablename__ = "split_payments"
    __table_args__ = {'extend_existing': True}
    split_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("payments.payment_id"), nullable=False)
    mode: Mapped[str] = mapped_column(String(20), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)


# ── M. Reports & Analytics ────────────────────────────────────────────────────

class DailyKPISnapshot(Base, TimestampMixin):
    """Immutable daily snapshot of property KPIs for cloud reporting."""
    __tablename__ = "daily_kpi_snapshots"
    __table_args__ = (
        UniqueConstraint("property_id", "snapshot_date", name="uq_daily_kpi_property_date"),
        {'extend_existing': True},
    )
    snapshot_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False, index=True)
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
    template_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"), nullable=True, index=True)
    report_name: Mapped[str] = mapped_column(String(150), nullable=False)
    report_type: Mapped[str] = mapped_column(String(50), nullable=False)
    configuration_json: Mapped[Optional[dict]] = mapped_column(JSONB)


class ScheduledReport(Base, TimestampMixin):
    """Scheduled delivery configuration for a report template."""
    __tablename__ = "scheduled_reports"
    __table_args__ = {'extend_existing': True}
    schedule_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    template_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("report_templates.template_id"), nullable=False, index=True)
    recipient_role: Mapped[str] = mapped_column(String(40), nullable=False)
    delivery_channel: Mapped[str] = mapped_column(String(20), nullable=False)
    frequency: Mapped[str] = mapped_column(String(20), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

# ── Settings (Module 15) ──
from app.modules.settings.models import SystemConfiguration, PropertySetting
