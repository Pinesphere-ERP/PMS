from typing import Optional
from uuid import UUID, uuid4
from datetime import datetime
from sqlalchemy import String, Boolean, ForeignKey, Integer, JSON, Enum as SQLEnum, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.database.database import Base, TimestampMixin, TenantMixin

class VerificationStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    CHANGES_REQUESTED = "CHANGES_REQUESTED"

class Owner(Base, TimestampMixin, TenantMixin):
    __tablename__ = "owners"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    mobile: Mapped[str] = mapped_column(String(20), nullable=False)
    email: Mapped[Optional[str]] = mapped_column(String(255))
    whatsapp_number: Mapped[Optional[str]] = mapped_column(String(20))

    properties: Mapped[list["Property"]] = relationship(back_populates="owner")

class Property(Base, TimestampMixin, TenantMixin):
    __tablename__ = "properties"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    owner_id: Mapped[UUID] = mapped_column(ForeignKey("owners.id"))
    
    # Business Info
    business_name: Mapped[str] = mapped_column(String(255), nullable=False)
    business_type: Mapped[str] = mapped_column(String(100), nullable=False)
    gst_number: Mapped[Optional[str]] = mapped_column(String(50))
    pan_number: Mapped[Optional[str]] = mapped_column(String(50))
    
    # Property Info
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    property_type: Mapped[str] = mapped_column(String(100), nullable=False)
    star_category: Mapped[Optional[int]] = mapped_column(Integer)
    number_of_rooms: Mapped[int] = mapped_column(Integer, default=0)
    floors: Mapped[Optional[int]] = mapped_column(Integer)
    description: Mapped[Optional[str]] = mapped_column(String(1000))
    
    # Address
    address: Mapped[str] = mapped_column(String(500), nullable=False)
    landmark: Mapped[Optional[str]] = mapped_column(String(255))
    city: Mapped[str] = mapped_column(String(100), nullable=False)
    state: Mapped[str] = mapped_column(String(100), nullable=False)
    country: Mapped[str] = mapped_column(String(100), nullable=False, default="India")
    pincode: Mapped[str] = mapped_column(String(20), nullable=False)
    google_map_url: Mapped[Optional[str]] = mapped_column(String(500))
    
    # JSON Data
    amenities: Mapped[Optional[dict]] = mapped_column(JSON)
    bank_details: Mapped[Optional[dict]] = mapped_column(JSON)
    documents: Mapped[Optional[dict]] = mapped_column(JSON)
    
    is_active: Mapped[bool] = mapped_column(default=False)
    is_draft: Mapped[bool] = mapped_column(default=True)
    verification_status: Mapped[VerificationStatus] = mapped_column(SQLEnum(VerificationStatus), default=VerificationStatus.PENDING)

    owner: Mapped["Owner"] = relationship(back_populates="properties", lazy="selectin")
    verifications: Mapped[list["PropertyVerification"]] = relationship(back_populates="property")

class PropertyVerification(Base, TimestampMixin, TenantMixin):
    __tablename__ = "property_verifications"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    property_id: Mapped[UUID] = mapped_column(ForeignKey("properties.id"))
    
    verification_type: Mapped[str] = mapped_column(String(100), nullable=False) # e.g., "PAN", "GST", "Ownership"
    status: Mapped[VerificationStatus] = mapped_column(SQLEnum(VerificationStatus), default=VerificationStatus.PENDING)
    remarks: Mapped[Optional[str]] = mapped_column(String(1000))
    assigned_to: Mapped[Optional[UUID]] = mapped_column(ForeignKey("users.id"))
    
    property: Mapped["Property"] = relationship(back_populates="verifications", lazy="selectin")
