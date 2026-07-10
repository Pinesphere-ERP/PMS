"""
Shared test fixtures for pinesphere_backend.
Uses SQLite in-memory to bypass the PostgreSQL requirement and
the pre-existing Subscription import error in properties/router.py.
"""
import asyncio
import uuid
from typing import Any, AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import String, Text, Boolean, Integer, DateTime, Index, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.types import TypeDecorator
import app.infra.models as _infra_models


# ---------------------------------------------------------------------------
# TypeDecorator: wraps String to accept uuid.UUID objects
# ---------------------------------------------------------------------------

class GUIDString(TypeDecorator):
    """Store UUID as VARCHAR(36). Accepts uuid.UUID on write."""
    impl = String(36)
    cache_ok = True

    def process_bind_param(self, value: Any, dialect) -> str | None:
        if value is None:
            return None
        if isinstance(value, uuid.UUID):
            return str(value)
        return str(value)

    def process_result_value(self, value: Any, dialect) -> str | None:
        return value


# ---------------------------------------------------------------------------
# Test Base
# ---------------------------------------------------------------------------

class TestBase(DeclarativeBase):
    pass


class TimestampMixin:
    created_at = mapped_column(DateTime, nullable=True)
    updated_at = mapped_column(DateTime, nullable=True)


class SyncMixin:
    version = mapped_column(Integer, default=1)
    is_deleted = mapped_column(Boolean, default=False)
    deleted_at = mapped_column(DateTime, nullable=True)
    device_id = mapped_column(String(100), nullable=True)


# ---------------------------------------------------------------------------
# Test models (SQLite-compatible)
# ---------------------------------------------------------------------------

class SystemConfiguration(TestBase, TimestampMixin):
    __tablename__ = "system_configurations"

    id = mapped_column(GUIDString(), primary_key=True, default=lambda: str(uuid.uuid4()))
    config_key = mapped_column(String(100), unique=True, nullable=False, index=True)
    config_value = mapped_column(Text, nullable=False)
    description = mapped_column(Text, nullable=True)
    updated_by = mapped_column(GUIDString(), nullable=True)


class PropertySetting(TestBase, TimestampMixin, SyncMixin):
    __tablename__ = "property_settings"
    __table_args__ = (
        Index(
            "uq_property_settings_active_key",
            "property_id", "setting_key",
            unique=True,
            postgresql_where=text("is_deleted = FALSE"),
            sqlite_where=text("is_deleted = FALSE"),
        ),
    )

    id = mapped_column(GUIDString(), primary_key=True, default=lambda: str(uuid.uuid4()))
    property_id = mapped_column(GUIDString(), nullable=False, index=True)
    setting_key = mapped_column(String(100), nullable=False)
    setting_value = mapped_column(Text, nullable=False)
    value_type = mapped_column(String(20), nullable=False, default="string")
    description = mapped_column(Text, nullable=True)
    updated_by = mapped_column(GUIDString(), nullable=True)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

SQLITE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def engine():
    eng = create_async_engine(SQLITE_URL, echo=False)
    async with eng.begin() as conn:
        await conn.run_sync(TestBase.metadata.create_all)
    yield eng
    async with eng.begin() as conn:
        await conn.run_sync(TestBase.metadata.drop_all)
    await eng.dispose()


@pytest_asyncio.fixture(scope="function")
async def db_session(engine) -> AsyncGenerator[AsyncSession, None]:
    session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with session_factory() as session:
        async with session.begin():
            yield session




@pytest.fixture
def patched_settings_models(monkeypatch):
    """Patch app.infra.models with SQLite-compatible test models.

    Scoped to each test function via monkeypatch — auto-reverts after each test,
    so other test files in the same session never see the patched versions unless
    they explicitly request this fixture.
    """
    monkeypatch.setattr(_infra_models, "SystemConfiguration", SystemConfiguration)
    monkeypatch.setattr(_infra_models, "PropertySetting", PropertySetting)
    yield


@pytest_asyncio.fixture(scope="function")
async def client(engine, patched_settings_models) -> AsyncGenerator[AsyncClient, None]:
    from app.modules.settings.router import router
    from app.infra.database import get_db
    from fastapi import FastAPI

    test_app = FastAPI()
    test_app.include_router(router, prefix="/settings")

    session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    async def override_get_db():
        async with session_factory() as session:
            yield session

    test_app.dependency_overrides[get_db] = override_get_db

    transport = ASGITransport(app=test_app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
