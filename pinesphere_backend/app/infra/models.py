import uuid
from datetime import date, datetime, time
from typing import Optional
from sqlalchemy import (
    String, Boolean, Integer, SmallInteger, Text, DateTime, Date, Time, Numeric, ForeignKey, Enum, UniqueConstraint, Index, JSON, BIGINT
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB

from app.infra.database import Base, TimestampMixin, SyncMixin

# A. Owners & Access

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

# B. Properties & Location

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
    primary_device_id: Mapped[Optional[uuid.UUID]] = mapped_column(PGUUID(as_uuid=True)) # Add FK later or allow null temporarily
    whatsapp_number: Mapped[Optional[str]] = mapped_column(String(15))
    onboarding_status: Mapped[str] = mapped_column(String(20), default='draft')
    created_by_admin_id: Mapped[Optional[uuid.UUID]] = mapped_column(PGUUID(as_uuid=True))

# Additional tables to fill out as much as possible

class Role(Base, TimestampMixin):
    __tablename__ = "roles"
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"))
    role_code: Mapped[str] = mapped_column(String(40), nullable=False)
    role_name: Mapped[str] = mapped_column(String(80), nullable=False)
    is_system_role: Mapped[bool] = mapped_column(default=True)
    description: Mapped[Optional[str]] = mapped_column(Text)

    __table_args__ = (
        UniqueConstraint('property_id', 'role_code', name='uq_roles_property_role_code'),
        {'extend_existing': True}
    )

class Permission(Base):
    __tablename__ = "permissions"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    permission_code: Mapped[str] = mapped_column(String(60), nullable=False, unique=True)
    module_name: Mapped[str] = mapped_column(String(60), nullable=False)

class RolePermission(Base):
    __tablename__ = "role_permissions"
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("roles.id", ondelete="CASCADE"), nullable=False)
    permission_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("permissions.id", ondelete="CASCADE"), nullable=False)
    access_level: Mapped[str] = mapped_column(String(20), nullable=False)

    __table_args__ = (
        UniqueConstraint('role_id', 'permission_id', name='uq_role_permissions'),
        {'extend_existing': True}
    )

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
    check_in_date: Mapped[date] = mapped_column(Date, nullable=False)
    check_out_date: Mapped[date] = mapped_column(Date, nullable=False)
    booking_status: Mapped[Optional[str]] = mapped_column(String(20), default='confirmed')
    amount: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    payment_status: Mapped[Optional[str]] = mapped_column(String(20))
    sync_status: Mapped[Optional[str]] = mapped_column(String(20), default='synced')

class AuditLog(Base):
    __tablename__ = "audit_logs"
    __table_args__ = {'extend_existing': True}
    log_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"))
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, index=True)
    module_name: Mapped[Optional[str]] = mapped_column(String(50), index=True)
    action_type: Mapped[Optional[str]] = mapped_column(String(50))
    target_entity: Mapped[Optional[str]] = mapped_column(String(50))
    target_record_id: Mapped[Optional[uuid.UUID]] = mapped_column(PGUUID(as_uuid=True))
    old_value_snapshot: Mapped[Optional[dict]] = mapped_column(JSONB)
    new_value_snapshot: Mapped[Optional[dict]] = mapped_column(JSONB)
    previous_log_hash: Mapped[Optional[str]] = mapped_column(String(64))
    entry_hash: Mapped[Optional[str]] = mapped_column(String(64))

# C. Payments & Billing

class Invoice(Base, TimestampMixin):
    __tablename__ = "invoices"
    __table_args__ = {'extend_existing': True}
    invoice_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    booking_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bookings.booking_id"), nullable=False)
    invoice_number: Mapped[Optional[str]] = mapped_column(String(50))
    grand_total: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))

class Payment(Base, TimestampMixin, SyncMixin):
    __tablename__ = "payments"
    __table_args__ = {'extend_existing': True}
    payment_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("invoices.invoice_id"))
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id"))
    transaction_id: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    reference_number: Mapped[Optional[str]] = mapped_column(String(100))
    payment_mode: Mapped[str] = mapped_column(String(20), nullable=False) # cash, upi, credit_card, debit_card, net_banking, wallet, split
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    upi_id: Mapped[Optional[str]] = mapped_column(String(100))
    bank_name: Mapped[Optional[str]] = mapped_column(String(100))
    card_last4: Mapped[Optional[str]] = mapped_column(String(4))
    collected_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    remarks: Mapped[Optional[str]] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default='pending') # pending, partially_paid, fully_paid, refunded, cancelled
    synced: Mapped[bool] = mapped_column(default=False)

class PaymentTransaction(Base, TimestampMixin):
    __tablename__ = "payment_transactions"
    __table_args__ = {'extend_existing': True}
    txn_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("payments.payment_id"), nullable=False)
    event: Mapped[str] = mapped_column(String(20), nullable=False) # created, captured, failed, refunded
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    meta_data: Mapped[Optional[dict]] = mapped_column(JSONB)

class SplitPayment(Base):
    __tablename__ = "split_payments"
    __table_args__ = {'extend_existing': True}
    split_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("payments.payment_id"), nullable=False)
    mode: Mapped[str] = mapped_column(String(20), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)

class Refund(Base):
    __tablename__ = "refunds"
    __table_args__ = {'extend_existing': True}
    refund_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("payments.payment_id"), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    reason: Mapped[Optional[str]] = mapped_column(Text)
    approved_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(20), default='requested') # requested, approved, rejected, completed
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    processed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

class Receipt(Base):
    __tablename__ = "receipts"
    __table_args__ = {'extend_existing': True}
    receipt_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("payments.payment_id"), nullable=False)
    receipt_number: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    pdf_path: Mapped[Optional[str]] = mapped_column(Text)
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

class CashRegister(Base):
    __tablename__ = "cash_registers"
    __table_args__ = {'extend_existing': True}
    register_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    staff_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    opening_balance: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    closing_balance: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    shift_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default='open') # open, closed
