"""Idempotent system-role and optionally configured administrator seed."""

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import get_password_hash
from app.infra.models import Role, User

SYSTEM_ROLES = (
    ("SUPER_ADMIN", "Super Admin"),
    ("OWNER", "Owner"),
    ("MANAGER", "Manager"),
    ("RECEPTION", "Reception"),
    ("HOUSEKEEPING", "Housekeeping"),
    ("ACCOUNTANT", "Accountant"),
    ("GUEST", "Guest"),
)


async def seed(session: AsyncSession) -> None:
    """Create missing system roles and an explicitly configured admin account."""
    for role_code, role_name in SYSTEM_ROLES:
        result = await session.execute(
            select(Role).where(Role.property_id.is_(None), Role.role_code == role_code)
        )
        if result.scalar_one_or_none() is None:
            session.add(
                Role(
                    id=uuid.uuid4(),
                    role_code=role_code,
                    role_name=role_name,
                    is_system_role=True,
                    description=f"{role_name} role",
                )
            )

    if not settings.SEED_ADMIN_USERNAME:
        return
    if not settings.SEED_ADMIN_PASSWORD:
        raise ValueError("SEED_ADMIN_PASSWORD is required when SEED_ADMIN_USERNAME is set")

    result = await session.execute(
        select(Role).where(Role.property_id.is_(None), Role.role_code == "SUPER_ADMIN")
    )
    super_admin_role = result.scalar_one()
    result = await session.execute(
        select(User).where(User.property_id.is_(None), User.username == settings.SEED_ADMIN_USERNAME)
    )
    user = result.scalar_one_or_none()
    password_hash = get_password_hash(settings.SEED_ADMIN_PASSWORD)

    if user is None:
        session.add(
            User(
                id=uuid.uuid4(),
                username=settings.SEED_ADMIN_USERNAME,
                email=settings.SEED_ADMIN_EMAIL,
                password_hash=password_hash,
                name=settings.SEED_ADMIN_NAME,
                status="ACTIVE",
                role_id=super_admin_role.id,
                property_id=None,
            )
        )
        return

    user.email = settings.SEED_ADMIN_EMAIL
    user.password_hash = password_hash
    user.name = settings.SEED_ADMIN_NAME
    user.status = "ACTIVE"
    user.role_id = super_admin_role.id
