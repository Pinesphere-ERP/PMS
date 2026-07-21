import uuid
from datetime import date, datetime, time
from typing import Optional
from sqlalchemy import (
    String, Boolean, Integer, SmallInteger, Text, DateTime, Date, Time,
    Numeric, ForeignKey, Enum, UniqueConstraint, Index, JSON, BIGINT, text, func
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB

from sqlalchemy.ext.compiler import compiles

@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"

@compiles(PGUUID, "sqlite")
def compile_uuid_sqlite(type_, compiler, **kw):
    return "CHAR(32)"

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
    properties: Mapped[list["Property"]] = relationship(back_populates="owner")


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

class Property(Base, TimestampMixin, SyncMixin):
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
    city: Mapped[Optional[str]] = mapped_column(String(100))
    cover_image: Mapped[Optional[str]] = mapped_column(String(500))
    owner: Mapped["Owner"] = relationship(back_populates="properties")


# ── C. Roles & Permissions ────────────────────────────────────────────────────


class PropertyAddress(Base, TimestampMixin):
    __tablename__ = "property_addresses"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False, unique=True)
    address: Mapped[Optional[str]] = mapped_column(Text)
    landmark: Mapped[Optional[str]] = mapped_column(String(200))
    city: Mapped[Optional[str]] = mapped_column(String(100))
    state: Mapped[Optional[str]] = mapped_column(String(100))
    country: Mapped[Optional[str]] = mapped_column(String(100))
    pincode: Mapped[Optional[str]] = mapped_column(String(20))
    latitude: Mapped[Optional[float]] = mapped_column(Numeric(10, 6))
    longitude: Mapped[Optional[float]] = mapped_column(Numeric(10, 6))
    google_maps_url: Mapped[Optional[str]] = mapped_column(Text)

class PropertyImage(Base, TimestampMixin):
    __tablename__ = "property_images"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    image_type: Mapped[str] = mapped_column(String(50), nullable=False)
    image_url: Mapped[str] = mapped_column(Text, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)

class PropertyDocument(Base, TimestampMixin):
    __tablename__ = "property_documents"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    document_type: Mapped[str] = mapped_column(String(50), nullable=False)
    document_number: Mapped[Optional[str]] = mapped_column(String(100))
    document_url: Mapped[str] = mapped_column(Text, nullable=False)
    verification_status: Mapped[str] = mapped_column(String(30), default='pending')
    verified_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    remarks: Mapped[Optional[str]] = mapped_column(Text)

class BankAccount(Base, TimestampMixin):
    __tablename__ = "bank_accounts"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    bank_name: Mapped[str] = mapped_column(String(150), nullable=False)
    account_holder_name: Mapped[str] = mapped_column(String(150), nullable=False)
    account_number: Mapped[str] = mapped_column(String(100), nullable=False)
    ifsc_code: Mapped[str] = mapped_column(String(20), nullable=False)
    upi_id: Mapped[Optional[str]] = mapped_column(String(100))
    cancelled_cheque_url: Mapped[Optional[str]] = mapped_column(Text)

class PropertyVerification(Base, TimestampMixin):
    __tablename__ = "property_verifications"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False, unique=True)
    mobile_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    pan_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    gst_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    bank_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    ownership_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    documents_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    photos_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    map_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verification_score: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(30), default='pending')
    review_required: Mapped[bool] = mapped_column(Boolean, default=True)
    verified_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    remarks: Mapped[Optional[str]] = mapped_column(Text)

class Amenity(Base, TimestampMixin):
    __tablename__ = "amenities"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    category: Mapped[Optional[str]] = mapped_column(String(50))
    icon_name: Mapped[Optional[str]] = mapped_column(String(50))

class PropertyAmenity(Base, TimestampMixin):
    __tablename__ = "property_amenities"
    __table_args__ = (
        UniqueConstraint('property_id', 'amenity_id', name='uq_property_amenity'),
        {'extend_existing': True}
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    amenity_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("amenities.id", ondelete="CASCADE"), nullable=False)



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
    description: Mapped[Optional[str]] = mapped_column(Text)


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
    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())


# ── D. Users & Devices ────────────────────────────────────────────────────────

class User(Base, TimestampMixin, SyncMixin):
    __tablename__ = "users"
    __table_args__ = (
        UniqueConstraint('mobile_number', name='uq_users_mobile_number'),
        UniqueConstraint('username', name='uq_users_username'),
        {'extend_existing': True}
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"))
    role_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("roles.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    mobile_number: Mapped[Optional[str]] = mapped_column(String(15))
    email: Mapped[Optional[str]] = mapped_column(String(120))
    username: Mapped[Optional[str]] = mapped_column(String(60))
    password_hash: Mapped[Optional[str]] = mapped_column(String(255))
    pin_hash: Mapped[Optional[str]] = mapped_column(String(255))
    biometric_enabled: Mapped[bool] = mapped_column(default=False)
    is_primary_owner: Mapped[bool] = mapped_column(default=False)
    status: Mapped[str] = mapped_column(String(20), default="ACTIVE")
    failed_login_attempts: Mapped[int] = mapped_column(SmallInteger, default=0)
    profile_photo_url: Mapped[Optional[str]] = mapped_column(Text)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    is_pending_sync: Mapped[bool] = mapped_column(default=False)
    
    # Relationships
    property_access: Mapped[list["UserPropertyAccess"]] = relationship("UserPropertyAccess", back_populates="user")

    @property
    def active_property_id_resolved(self) -> Optional[uuid.UUID]:
        """Returns the dynamically assigned active property or falls back to the default property."""
        return getattr(self, "active_property_id", self.property_id)

    @property
    def active_role_id_resolved(self) -> uuid.UUID:
        """Returns the dynamically assigned active role or falls back to the default role."""
        return getattr(self, "active_role_id", self.role_id)

class UserPropertyAccess(Base, TimestampMixin):
    __tablename__ = "user_property_access"
    __table_args__ = (
        UniqueConstraint('user_id', 'property_id', name='uq_user_property_access'),
        {'extend_existing': True}
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    role_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("roles.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="ACTIVE")
    
    user: Mapped["User"] = relationship("User", back_populates="property_access")


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


class UserDevice(Base):
    __tablename__ = "user_devices"
    __table_args__ = (
        UniqueConstraint('user_id', 'device_id', name='uq_user_devices_user_device'),
        {'extend_existing': True}
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("devices.id", ondelete="CASCADE"), nullable=False)
    is_primary_device: Mapped[bool] = mapped_column(default=True, nullable=False)
    linked_at: Mapped[datetime] = mapped_column(server_default=func.now(), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="ACTIVE", nullable=False)


class UserSession(Base):
    __tablename__ = "user_sessions"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("devices.id"), nullable=True)
    session_token: Mapped[str] = mapped_column(String(500), unique=True, nullable=False)
    is_offline_session: Mapped[bool] = mapped_column(default=False, nullable=False)
    issued_at: Mapped[datetime] = mapped_column(server_default=func.now(), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(nullable=False)
    revoked_at: Mapped[Optional[datetime]] = mapped_column(nullable=True)
    revoked_reason: Mapped[Optional[str]] = mapped_column(String(120), nullable=True)


class StaffInvitation(Base):
    __tablename__ = "staff_invitations"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    role_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("roles.id"), nullable=False)
    invited_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    mobile_number: Mapped[str] = mapped_column(String(15), nullable=False)
    invitation_token: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="PENDING", nullable=False)
    expires_at: Mapped[datetime] = mapped_column(nullable=False)
    created_at: Mapped[datetime] = mapped_column(server_default=func.now(), nullable=False)


class CredentialResetRequest(Base):
    __tablename__ = "credential_reset_requests"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    reset_type: Mapped[str] = mapped_column(String(20), nullable=False)
    requested_via: Mapped[str] = mapped_column(String(20), nullable=False)
    approved_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="PENDING", nullable=False)
    requested_at: Mapped[datetime] = mapped_column(server_default=func.now(), nullable=False)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(nullable=True)


class UserSyncLog(Base):
    __tablename__ = "user_sync_log"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_type: Mapped[str] = mapped_column(String(40), nullable=False)
    entity_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), nullable=False)
    operation: Mapped[str] = mapped_column(String(20), nullable=False)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)
    sync_status: Mapped[str] = mapped_column(String(20), default="PENDING", nullable=False)
    created_at: Mapped[datetime] = mapped_column(server_default=func.now(), nullable=False)
    synced_at: Mapped[Optional[datetime]] = mapped_column(nullable=True)
# ── E. Rooms ──────────────────────────────────────────────────────────────────

class RoomType(Base, TimestampMixin):
    __tablename__ = "room_types"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    name: Mapped[Optional[str]] = mapped_column(String(100))
    category: Mapped[Optional[str]] = mapped_column(String(50))
    occupancy: Mapped[int] = mapped_column(Integer, default=2)
    bed_type: Mapped[Optional[str]] = mapped_column(String(50))
    room_size: Mapped[Optional[str]] = mapped_column(String(50))
    smoking: Mapped[bool] = mapped_column(Boolean, default=False)
    balcony: Mapped[bool] = mapped_column(Boolean, default=False)
    view: Mapped[Optional[str]] = mapped_column(String(100))
    ac: Mapped[bool] = mapped_column(Boolean, default=True)
    description: Mapped[Optional[str]] = mapped_column(Text)

RoomCategory = RoomType

class RoomInventory(Base, TimestampMixin):
    __tablename__ = "room_inventory"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_type_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("room_types.id", ondelete="CASCADE"), nullable=False, unique=True)
    total_rooms: Mapped[int] = mapped_column(Integer, default=0)
    available_rooms: Mapped[int] = mapped_column(Integer, default=0)

class RoomPricing(Base, TimestampMixin):
    __tablename__ = "room_pricing"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_type_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("room_types.id", ondelete="CASCADE"), nullable=False, unique=True)
    base_price: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    weekend_price: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    extra_adult: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    extra_child: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    tax: Mapped[Optional[str]] = mapped_column(String(20))
    meal_plan: Mapped[Optional[str]] = mapped_column(String(50))

class RoomAmenity(Base, TimestampMixin):
    __tablename__ = "room_amenities"
    __table_args__ = (
        UniqueConstraint('room_type_id', 'amenity_id', name='uq_room_amenity'),
        {'extend_existing': True}
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_type_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("room_types.id", ondelete="CASCADE"), nullable=False)
    amenity_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("amenities.id", ondelete="CASCADE"), nullable=False)



class Room(Base, TimestampMixin, SyncMixin):
    __tablename__ = "rooms"
    __table_args__ = {'extend_existing': True}
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    room_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_type_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("room_types.id"), nullable=False)
    room_number: Mapped[str] = mapped_column(String(20), nullable=False)
    housekeeping_status: Mapped[Optional[str]] = mapped_column(String(20), default='clean')
    occupancy_status: Mapped[Optional[str]] = mapped_column(String(20), default='vacant')
    image_url: Mapped[Optional[str]] = mapped_column(Text)


# ── F. Guests & Bookings ──────────────────────────────────────────────────────

class Guest(Base, TimestampMixin, SyncMixin):
    __tablename__ = "guests"
    __table_args__ = {'extend_existing': True}
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    guest_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    mobile: Mapped[Optional[str]] = mapped_column(String(15))
    email: Mapped[Optional[str]] = mapped_column(String(150))


class Booking(Base, TimestampMixin, SyncMixin):
    __tablename__ = "bookings"
    __table_args__ = (
        UniqueConstraint('booking_reference', name='uq_bookings_reference'),
        {'extend_existing': True},
    )
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    booking_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    guest_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("guests.guest_id"), nullable=False)
    booking_type: Mapped[Optional[str]] = mapped_column(String(20), default='walkin')
    booking_source: Mapped[Optional[str]] = mapped_column(String(30))
    # Broker who sourced this booking (only set when booking_source == 'broker')
    broker_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    # Human-readable, system-generated reference for guest portal auth (globally unique)
    booking_reference: Mapped[Optional[str]] = mapped_column(String(30), unique=True, nullable=True)
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
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    checkin_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    booking_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bookings.booking_id"), nullable=False)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    guest_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("guests.guest_id"), nullable=False)
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
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    checkout_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    checkin_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("check_ins.checkin_id"), nullable=False)
    booking_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bookings.booking_id"), nullable=False)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
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
        Index("ix_audit_logs_timestamp", "timestamp"),
        Index("ix_audit_logs_target", "target_entity", "target_record_id"),
        {'extend_existing': True},
    )
    log_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"), nullable=True)
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
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    task_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    assigned_staff_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(20), default='pending')
    priority: Mapped[str] = mapped_column(String(10), default='medium')
    checklist_status: Mapped[Optional[dict]] = mapped_column(JSONB)
    remarks: Mapped[Optional[str]] = mapped_column(Text)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


class MaintenanceTicket(Base, TimestampMixin, SyncMixin):
    __tablename__ = "maintenance_tickets"
    __table_args__ = {'extend_existing': True}
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    ticket_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
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
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    item_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("rooms.room_id"), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    found_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(20), default='stored')
    photo: Mapped[Optional[str]] = mapped_column(Text)


# ── I. Property Payments (guest billing) ──────────────────────────────────────

class Invoice(Base, TimestampMixin):
    """Guest billing invoice (property-level, for check-out folio)."""
    __tablename__ = "invoices"
    __table_args__ = {'extend_existing': True}
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    invoice_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id"))
    guest_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("guests.guest_id"))
    invoice_number: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    plan: Mapped[Optional[str]] = mapped_column(String(50))          # for subscription invoices
    date: Mapped[date] = mapped_column(Date, nullable=False)
    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    gst: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    status: Mapped[str] = mapped_column(String(20), default="Pending")


class Payment(Base, TimestampMixin, SyncMixin):
    """Guest payment."""
    __tablename__ = "payments"
    payment_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("invoices.invoice_id"))
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id"))
    transaction_id: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    reference_number: Mapped[Optional[str]] = mapped_column(String(100))
    payment_mode: Mapped[str] = mapped_column(String(20), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    upi_id: Mapped[Optional[str]] = mapped_column(String(100))
    bank_name: Mapped[Optional[str]] = mapped_column(String(100))
    card_last4: Mapped[Optional[str]] = mapped_column(String(4))
    collected_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"))
    remarks: Mapped[Optional[str]] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default='pending')
    synced: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)



# ── J. Admin Subscriptions & Billing ─────────────────────────────────────────

class SubscriptionPlan(Base, TimestampMixin):
    """Available subscription plans on the platform."""
    __tablename__ = "subscription_plans"
    __table_args__ = {'extend_existing': True}
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"), nullable=True)
    plan_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    features: Mapped[Optional[str]] = mapped_column(Text)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    duration_months: Mapped[int] = mapped_column(Integer, default=1)
    status: Mapped[str] = mapped_column(String(20), default="Active")

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
    subscription_required: Mapped[bool] = mapped_column(Boolean, default=True)


class SubscriptionTransaction(Base, TimestampMixin):
    """Admin-level payment record (Pinesphere platform subscription payment)."""
    __tablename__ = "subscription_transactions"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    invoice_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("invoices.invoice_id"))
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    method: Mapped[Optional[str]] = mapped_column(String(50))
    status: Mapped[str] = mapped_column(String(20), default="Processing")
    bank_ref: Mapped[Optional[str]] = mapped_column(String(100))

class PaymentTransaction(Base, TimestampMixin):
    """Guest payment ledger."""
    __tablename__ = "payment_transactions"
    __table_args__ = {'extend_existing': True}
    txn_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("payments.payment_id"), nullable=False)
    event: Mapped[str] = mapped_column(String(20), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    meta_data: Mapped[Optional[dict]] = mapped_column(JSONB)


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





# ── L. Split Payments ─────────────────────────────────────────────────────────

class SplitPayment(Base, TimestampMixin):
    __tablename__ = "split_payments"
    __table_args__ = {'extend_existing': True}
    split_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    payment_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("payments.payment_id"), nullable=False)
    mode: Mapped[str] = mapped_column(String(20), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)


# ── M. Reports & Analytics ────────────────────────────────────────────────────
from app.modules.reports.models import DailyKPISnapshot, ReportTemplate, ScheduledReport

# ── Settings (Module 15) ──
from app.modules.settings.models import SystemConfiguration, PropertySetting

class Task(Base, TimestampMixin, SyncMixin):
    __tablename__ = "tasks"
    __table_args__ = (
        Index("ix_tasks_property", "property_id"),
        {'extend_existing': True},
    )
    task_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    # property_id is REQUIRED for isolation — every task must belong to exactly one property
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    task_type: Mapped[str] = mapped_column(String(50), nullable=False) # cleaning, maintenance, food
    status: Mapped[str] = mapped_column(String(20), default='pending') # pending, accepted, in_progress, completed, closed
    priority: Mapped[str] = mapped_column(String(20), default='normal') # normal, high, emergency
    room_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("rooms.room_id"), nullable=True)
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id"), nullable=True)
    assigned_to: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text)
    due_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    photos: Mapped[Optional[str]] = mapped_column(Text) # JSON list of URLs
    remarks: Mapped[Optional[str]] = mapped_column(Text)

class TaskLog(Base, TimestampMixin, SyncMixin):
    __tablename__ = "task_logs"
    __table_args__ = {'extend_existing': True}
    log_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    task_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tasks.task_id", ondelete="CASCADE"), nullable=False)
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    old_status: Mapped[Optional[str]] = mapped_column(String(20))
    new_status: Mapped[str] = mapped_column(String(20), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)

class Notification(Base, TimestampMixin, SyncMixin):
    __tablename__ = "notifications"
    __table_args__ = {'extend_existing': True}
    notification_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recipient_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    channel: Mapped[str] = mapped_column(String(20), default='in_app') # in_app, whatsapp, push
    priority: Mapped[str] = mapped_column(String(20), default='normal') # normal, high, critical
    status: Mapped[str] = mapped_column(String(20), default='unread') # unread, read, dismissed, failed
    read_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    payload: Mapped[Optional[dict]] = mapped_column(JSONB) # any extra data like task_id, booking_id


# ── N. OTP Requests ────────────────────────────────────────────────────────────

class OTPRequest(Base):
    """Stores hashed OTPs for account unlock, guest portal auth, etc."""
    __tablename__ = "otp_requests"
    __table_args__ = (
        Index("ix_otp_requests_user_purpose", "user_id", "purpose"),
        {'extend_existing': True},
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id", ondelete="CASCADE"), nullable=True)
    otp_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    purpose: Mapped[str] = mapped_column(String(40), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    used_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


# ── O. Pricing Rule Engine ────────────────────────────────────────────────────

class PricingRule(Base, TimestampMixin):
    """Dynamic pricing rule applied during booking creation."""
    __tablename__ = "pricing_rules"
    __table_args__ = (
        Index("ix_pricing_rules_property_active", "property_id", "is_active"),
        {'extend_existing': True},
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    rule_type: Mapped[str] = mapped_column(String(30), nullable=False)
    condition_json: Mapped[Optional[dict]] = mapped_column(JSONB)
    multiplier: Mapped[float] = mapped_column(Numeric(6, 4), nullable=False, default=1.0)
    flat_adjustment: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    priority: Mapped[int] = mapped_column(Integer, nullable=False, default=10)
    effective_from: Mapped[Optional[date]] = mapped_column(Date)
    effective_until: Mapped[Optional[date]] = mapped_column(Date)
    days_of_week: Mapped[Optional[str]] = mapped_column(String(20))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)


# ── P. Security Incidents & Device Blacklist ──────────────────────────────────

class SecurityIncident(Base, TimestampMixin):
    """Security incidents detected by the platform."""
    __tablename__ = "security_incidents"
    __table_args__ = (
        Index("ix_security_incidents_property", "property_id"),
        {'extend_existing': True},
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id"), nullable=True)
    incident_type: Mapped[str] = mapped_column(String(50), nullable=False)
    severity: Mapped[str] = mapped_column(String(20), nullable=False, default="medium")
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)
    device_uid: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    ip_address: Mapped[Optional[str]] = mapped_column(String(45), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="open")
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    resolved_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)


class DeviceBlacklist(Base):
    """Global blacklist for compromised device UIDs."""
    __tablename__ = "device_blacklist"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_uid: Mapped[str] = mapped_column(String(128), unique=True, nullable=False, index=True)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    blacklisted_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)
    blacklisted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    lifted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


class SecurityCamera(Base, TimestampMixin):
    """Security cameras integrated with the system."""
    __tablename__ = "security_cameras"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    location: Mapped[str] = mapped_column(String(255), nullable=False)
    ip_address: Mapped[Optional[str]] = mapped_column(String(45), nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="online")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class Watchlist(Base, TimestampMixin):
    """Watchlist for flagged individuals."""
    __tablename__ = "watchlist"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=True)
    person_name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    id_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    reason: Mapped[str] = mapped_column(String(255), nullable=False)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


# ── Q. Foreign Guest Compliance ───────────────────────────────────────────────

class GuestNationalityDocument(Base, TimestampMixin):
    """Passport/visa details for foreign guests."""
    __tablename__ = "guest_nationality_documents"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    guest_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("guests.guest_id", ondelete="CASCADE"), nullable=False)
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id"), nullable=True)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    nationality: Mapped[str] = mapped_column(String(60), nullable=False)
    passport_number: Mapped[str] = mapped_column(String(30), nullable=False)
    passport_expiry: Mapped[Optional[date]] = mapped_column(Date)
    visa_number: Mapped[Optional[str]] = mapped_column(String(30))
    visa_type: Mapped[Optional[str]] = mapped_column(String(30))
    visa_expiry: Mapped[Optional[date]] = mapped_column(Date)
    port_of_arrival: Mapped[Optional[str]] = mapped_column(String(100))
    arrival_date: Mapped[Optional[date]] = mapped_column(Date)
    document_front_url: Mapped[Optional[str]] = mapped_column(Text)
    document_back_url: Mapped[Optional[str]] = mapped_column(Text)
    verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    verified_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)


class FormCRecord(Base, TimestampMixin):
    """Form C declaration auto-generated on foreign national check-in."""
    __tablename__ = "form_c_records"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    guest_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("guests.guest_id"), nullable=False)
    booking_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bookings.booking_id"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    nationality_doc_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("guest_nationality_documents.id"), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="generated")
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    deadline_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    submitted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    pdf_url: Mapped[Optional[str]] = mapped_column(Text)
    submitted_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)


class FormCAmendment(Base):
    """Immutable amendment record for a Form C after submission."""
    __tablename__ = "form_c_amendments"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    form_c_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("form_c_records.id", ondelete="CASCADE"), nullable=False)
    amended_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    amendment_reason: Mapped[str] = mapped_column(Text, nullable=False)
    old_data_json: Mapped[dict] = mapped_column(JSONB, nullable=False)
    new_data_json: Mapped[dict] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


# ── R. Broker Commission Engine ───────────────────────────────────────────────

class BrokerCommissionRule(Base, TimestampMixin):
    """Property-level commission rate for a broker user."""
    __tablename__ = "broker_commission_rules"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    broker_user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    rate_percent: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False)
    effective_from: Mapped[date] = mapped_column(Date, nullable=False)
    effective_until: Mapped[Optional[date]] = mapped_column(Date)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)


class BrokerWallet(Base, TimestampMixin):
    """Accrued commission balance for a broker, scoped per property."""
    __tablename__ = "broker_wallets"
    __table_args__ = (
        UniqueConstraint("broker_user_id", "property_id", name="uq_broker_wallet"),
        {'extend_existing': True},
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    broker_user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id", ondelete="CASCADE"), nullable=False)
    balance: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False, default=0)
    currency: Mapped[str] = mapped_column(String(5), nullable=False, default="INR")


class CommissionTransaction(Base, TimestampMixin):
    """Individual commission accrual or reversal event."""
    __tablename__ = "commission_transactions"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    broker_wallet_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("broker_wallets.id"), nullable=False)
    booking_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("bookings.booking_id"), nullable=True)
    payment_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("payments.payment_id"), nullable=True)
    txn_type: Mapped[str] = mapped_column(String(20), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    rate_applied: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False)
    note: Mapped[Optional[str]] = mapped_column(Text)


class CommissionPayout(Base, TimestampMixin):
    """Disbursement record for broker commission."""
    __tablename__ = "commission_payouts"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    broker_user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    mode: Mapped[str] = mapped_column(String(30), nullable=False)
    reference: Mapped[Optional[str]] = mapped_column(String(100))
    status: Mapped[str] = mapped_column(String(20), default="pending")
    initiated_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)
    paid_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


# ── S. Guest Folio ─────────────────────────────────────────────────────────────

class FolioLineItem(Base, TimestampMixin):
    """Individual charge on a guest's billing folio."""
    __tablename__ = "folio_line_items"
    __table_args__ = (
        Index("ix_folio_line_items_booking", "booking_id"),
        {'extend_existing': True},
    )
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    booking_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bookings.booking_id", ondelete="CASCADE"), nullable=False)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    category: Mapped[str] = mapped_column(String(30), nullable=False)
    description: Mapped[str] = mapped_column(String(200), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    unit_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    added_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)
    is_void: Mapped[bool] = mapped_column(Boolean, default=False)
    voided_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)
    voided_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))


# ── T. Security Guard Module ──────────────────────────────────────────────────

class VisitorLog(Base, TimestampMixin):
    """Visitor registry entry recorded by security guard."""
    __tablename__ = "visitor_logs"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    visitor_name: Mapped[str] = mapped_column(String(150), nullable=False)
    visitor_mobile: Mapped[Optional[str]] = mapped_column(String(15))
    host_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)
    host_room: Mapped[Optional[str]] = mapped_column(String(20))
    purpose: Mapped[Optional[str]] = mapped_column(String(100))
    id_type: Mapped[Optional[str]] = mapped_column(String(30))
    id_number: Mapped[Optional[str]] = mapped_column(String(50))
    entry_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    exit_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    photo_url: Mapped[Optional[str]] = mapped_column(Text)
    logged_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)


class VehicleLog(Base, TimestampMixin):
    """Vehicle entry/exit registry."""
    __tablename__ = "vehicle_logs"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    plate_number: Mapped[str] = mapped_column(String(20), nullable=False)
    vehicle_type: Mapped[Optional[str]] = mapped_column(String(30))
    driver_name: Mapped[Optional[str]] = mapped_column(String(150))
    entry_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    exit_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    logged_by: Mapped[Optional[uuid.UUID]] = mapped_column(ForeignKey("users.id"), nullable=True)


class PropertyIncidentReport(Base):
    """Immutable incident report filed by security guard."""
    __tablename__ = "property_incident_reports"
    __table_args__ = {'extend_existing': True}
    id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.property_id"), nullable=False)
    reported_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    incident_type: Mapped[str] = mapped_column(String(50), nullable=False)
    location: Mapped[Optional[str]] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(Text, nullable=False)
    severity: Mapped[str] = mapped_column(String(20), nullable=False, default="medium")
    witness_name: Mapped[Optional[str]] = mapped_column(String(150))
    photo_url: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
