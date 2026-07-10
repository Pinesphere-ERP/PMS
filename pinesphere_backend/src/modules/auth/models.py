from typing import Optional
from uuid import UUID, uuid4
from sqlalchemy import String, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base, TimestampMixin, TenantMixin

class Tenant(Base, TimestampMixin):
    __tablename__ = "tenants"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    subdomain: Mapped[str] = mapped_column(String(63), unique=True, nullable=False)
    is_active: Mapped[bool] = mapped_column(default=True)
    
class Role(Base, TimestampMixin, TenantMixin):
    __tablename__ = "roles"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    
    users: Mapped[list["User"]] = relationship(back_populates="role")

class User(Base, TimestampMixin, TenantMixin):
    __tablename__ = "users"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(default=True)
    role_id: Mapped[Optional[UUID]] = mapped_column(ForeignKey("roles.id"))
    
    role: Mapped[Optional["Role"]] = relationship(back_populates="users", lazy="selectin")

class Device(Base, TimestampMixin, TenantMixin):
    __tablename__ = "devices"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    fingerprint: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    is_trusted: Mapped[bool] = mapped_column(default=False)
