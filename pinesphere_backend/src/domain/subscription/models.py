from typing import Optional
from uuid import UUID, uuid4
from datetime import datetime
from sqlalchemy import String, Boolean, ForeignKey, Integer, Float, Enum as SQLEnum, DateTime, Date
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from src.infra.database import Base, TimestampMixin, TenantMixin

class SubscriptionStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    GRACE_PERIOD = "GRACE_PERIOD"
    EXPIRED = "EXPIRED"
    DISABLED = "DISABLED"

class PaymentStatus(str, enum.Enum):
    PENDING = "PENDING"
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"

class SubscriptionPlan(Base, TimestampMixin, TenantMixin):
    __tablename__ = "subscription_plans"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    duration_days: Mapped[int] = mapped_column(Integer, nullable=False)
    device_limit: Mapped[int] = mapped_column(Integer, default=1)
    features: Mapped[Optional[str]] = mapped_column(String(1000)) # JSON string or comma separated
    is_active: Mapped[bool] = mapped_column(default=True)
    
    subscriptions: Mapped[list["Subscription"]] = relationship(back_populates="plan")

class Subscription(Base, TimestampMixin, TenantMixin):
    __tablename__ = "subscriptions"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    property_id: Mapped[UUID] = mapped_column(ForeignKey("properties.id"))
    plan_id: Mapped[UUID] = mapped_column(ForeignKey("subscription_plans.id"))
    
    start_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    expiry_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    grace_period_end: Mapped[Optional[datetime]] = mapped_column(DateTime)
    
    status: Mapped[SubscriptionStatus] = mapped_column(SQLEnum(SubscriptionStatus), default=SubscriptionStatus.ACTIVE)
    is_disabled_by_admin: Mapped[bool] = mapped_column(default=False)
    reminder_sent: Mapped[bool] = mapped_column(default=False)
    
    plan: Mapped["SubscriptionPlan"] = relationship(back_populates="subscriptions", lazy="selectin")
    payments: Mapped[list["Payment"]] = relationship(back_populates="subscription")
    licenses: Mapped[list["License"]] = relationship(back_populates="subscription")

class Payment(Base, TimestampMixin, TenantMixin):
    __tablename__ = "payments"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    subscription_id: Mapped[UUID] = mapped_column(ForeignKey("subscriptions.id"))
    
    invoice_number: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    payment_method: Mapped[Optional[str]] = mapped_column(String(100))
    payment_date: Mapped[Optional[datetime]] = mapped_column(DateTime)
    status: Mapped[PaymentStatus] = mapped_column(SQLEnum(PaymentStatus), default=PaymentStatus.PENDING)
    
    subscription: Mapped["Subscription"] = relationship(back_populates="payments", lazy="selectin")

class License(Base, TimestampMixin, TenantMixin):
    __tablename__ = "licenses"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    subscription_id: Mapped[UUID] = mapped_column(ForeignKey("subscriptions.id"))
    
    license_key: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    device_count: Mapped[int] = mapped_column(Integer, default=1)
    expiry_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    is_revoked: Mapped[bool] = mapped_column(default=False)
    
    subscription: Mapped["Subscription"] = relationship(back_populates="licenses", lazy="selectin")

class PropertyDevice(Base, TimestampMixin, TenantMixin):
    __tablename__ = "property_devices"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    property_id: Mapped[UUID] = mapped_column(ForeignKey("properties.id"))
    
    device_name: Mapped[str] = mapped_column(String(255), nullable=False)
    device_type: Mapped[str] = mapped_column(String(100), nullable=False)
    is_primary: Mapped[bool] = mapped_column(default=False)
    status: Mapped[str] = mapped_column(String(50), default="ACTIVE")
