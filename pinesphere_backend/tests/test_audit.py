"""
Tests for Module 14: Audit Logs.
Covers hash chain integrity, tamper detection, query/filtering, chain verification.
"""
import uuid
from datetime import datetime, timedelta, timezone

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import String, Text, DateTime, Index, JSON, Integer, Boolean
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.types import TypeDecorator

import app.infra.models as _infra_models


# ---------------------------------------------------------------------------
# SQLite-compatible type
# ---------------------------------------------------------------------------

class GUIDString(TypeDecorator):
    impl = String(36)
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        return str(value)

    def process_result_value(self, value, dialect):
        return value


# ---------------------------------------------------------------------------
# Test Base & AuditLog (SQLite-compatible)
# ---------------------------------------------------------------------------

class TestBase(DeclarativeBase):
    pass


class TestAuditLog(TestBase):
    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("ix_audit_logs_property_timestamp", "property_id", "timestamp"),
        Index("ix_audit_logs_target", "target_entity", "target_record_id"),
    )

    log_id = mapped_column(GUIDString(), primary_key=True, default=lambda: str(uuid.uuid4()))
    property_id = mapped_column(GUIDString(), nullable=True)
    user_id = mapped_column(GUIDString(), nullable=True)
    device_id = mapped_column(String(100), nullable=True)
    timestamp = mapped_column(DateTime, nullable=False, index=True)
    module_name = mapped_column(String(50), nullable=True, index=True)
    action_type = mapped_column(String(50), nullable=True)
    target_entity = mapped_column(String(50), nullable=True)
    target_record_id = mapped_column(GUIDString(), nullable=True)
    old_value_snapshot = mapped_column(JSON, nullable=True)
    new_value_snapshot = mapped_column(JSON, nullable=True)
    ip_address = mapped_column(String(45), nullable=True)
    previous_log_hash = mapped_column(String(64), nullable=True)
    entry_hash = mapped_column(String(64), nullable=True)


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
async def db_session(engine):
    session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with session_factory() as session:
        async with session.begin():
            yield session


@pytest.fixture
def patched_audit_model(monkeypatch):
    """Patch app.infra.models.AuditLog with SQLite-compatible test model."""
    monkeypatch.setattr(_infra_models, "AuditLog", TestAuditLog)
    yield


# We need asyncio for the async fixtures
import asyncio


# ---------------------------------------------------------------------------
# Hash chain helpers (replicated from service.py for direct testing)
# ---------------------------------------------------------------------------

GENESIS_HASH = "0" * 64

import hashlib


def _compute_entry_hash(previous_hash, timestamp, user_id, action_type, old_value, new_value):
    parts = [
        previous_hash or GENESIS_HASH,
        timestamp.isoformat() if timestamp else "",
        str(user_id) if user_id else "",
        action_type or "",
        str(old_value) if old_value else "",
        str(new_value) if new_value else "",
    ]
    raw = "||".join(parts)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Tests: Hash Chain Integrity
# ---------------------------------------------------------------------------

class TestHashChainIntegrity:
    """Verify that log_entry() produces correct hash chains."""

    @pytest.mark.asyncio
    async def test_single_entry_genesis_hash(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry

        prop_id = uuid.uuid4()
        target_id = uuid.uuid4()

        entry = await log_entry(
            db_session,
            property_id=prop_id,
            user_id=uuid.uuid4(),
            module_name="test",
            action_type="test_action",
            target_entity="test_entity",
            target_record_id=target_id,
            new_value={"key": "value"},
        )
        await db_session.flush()

        assert entry.previous_log_hash == GENESIS_HASH
        assert entry.entry_hash is not None
        assert len(entry.entry_hash) == 64

        expected = _compute_entry_hash(
            GENESIS_HASH, entry.timestamp, entry.user_id,
            "test_action", None, {"key": "value"},
        )
        assert entry.entry_hash == expected

    @pytest.mark.asyncio
    async def test_chain_links_correctly(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry

        prop_id = uuid.uuid4()
        uid = uuid.uuid4()
        t1 = datetime(2025, 1, 1, 10, 0, 0)
        t2 = datetime(2025, 1, 1, 10, 0, 1)

        entry1 = await log_entry(
            db_session,
            property_id=prop_id,
            user_id=uid,
            module_name="test",
            action_type="create",
            target_entity="room",
            target_record_id=uuid.uuid4(),
            timestamp=t1,
        )
        await db_session.flush()

        entry2 = await log_entry(
            db_session,
            property_id=prop_id,
            user_id=uid,
            module_name="test",
            action_type="update",
            target_entity="room",
            target_record_id=uuid.uuid4(),
            timestamp=t2,
        )
        await db_session.flush()

        assert entry2.previous_log_hash == entry1.entry_hash
        assert entry1.previous_log_hash == GENESIS_HASH

    @pytest.mark.asyncio
    async def test_different_property_independent_chains(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry

        prop_a = uuid.uuid4()
        prop_b = uuid.uuid4()
        t1 = datetime(2025, 1, 1, 10, 0, 0, tzinfo=timezone.utc)

        ea = await log_entry(
            db_session, property_id=prop_a, module_name="m", action_type="a",
            target_entity="e", target_record_id=uuid.uuid4(), timestamp=t1,
        )
        eb = await log_entry(
            db_session, property_id=prop_b, module_name="m", action_type="a",
            target_entity="e", target_record_id=uuid.uuid4(), timestamp=t1,
        )
        await db_session.flush()

        assert ea.previous_log_hash == GENESIS_HASH
        assert eb.previous_log_hash == GENESIS_HASH
        assert ea.entry_hash == eb.entry_hash


# ---------------------------------------------------------------------------
# Tests: Tamper Detection
# ---------------------------------------------------------------------------

class TestTamperDetection:
    """Verify that verify_chain() detects tampered entries."""

    @pytest.mark.asyncio
    async def test_valid_chain_passes(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry, verify_chain

        prop_id = uuid.uuid4()
        t = datetime(2025, 1, 1, 10, 0, 0)

        for i in range(5):
            await log_entry(
                db_session,
                property_id=prop_id,
                module_name="test",
                action_type=f"action_{i}",
                target_entity="entity",
                target_record_id=uuid.uuid4(),
                timestamp=t + timedelta(seconds=i),
            )
        await db_session.flush()

        result = await verify_chain(db_session, property_id=prop_id)
        assert result["valid"] is True
        assert result["total_entries"] == 5
        assert result["verified_entries"] == 5

    @pytest.mark.asyncio
    async def test_tampered_entry_detected(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry, verify_chain

        prop_id = uuid.uuid4()
        t = datetime(2025, 1, 1, 10, 0, 0)

        e1 = await log_entry(
            db_session, property_id=prop_id, module_name="test",
            action_type="action_1", target_entity="entity",
            target_record_id=uuid.uuid4(), timestamp=t,
        )
        e2 = await log_entry(
            db_session, property_id=prop_id, module_name="test",
            action_type="action_2", target_entity="entity",
            target_record_id=uuid.uuid4(), timestamp=t + timedelta(seconds=1),
        )
        await db_session.flush()

        e2.new_value_snapshot = {"tampered": True}
        await db_session.flush()

        result = await verify_chain(db_session, property_id=prop_id)
        assert result["valid"] is False
        assert result["verified_entries"] == 1

    @pytest.mark.asyncio
    async def test_empty_chain_valid(self, db_session, patched_audit_model):
        from app.modules.audit.service import verify_chain

        result = await verify_chain(db_session, property_id=uuid.uuid4())
        assert result["valid"] is True
        assert result["total_entries"] == 0


# ---------------------------------------------------------------------------
# Tests: Query / Filtering
# ---------------------------------------------------------------------------

class TestQueryLogs:
    """Verify query_logs filtering and pagination."""

    @pytest.mark.asyncio
    async def test_query_by_module(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry, query_logs

        prop_id = uuid.uuid4()
        t = datetime(2025, 1, 1, 10, 0, 0)

        await log_entry(db_session, property_id=prop_id, module_name="housekeeping",
                        action_type="create", target_entity="task",
                        target_record_id=uuid.uuid4(), timestamp=t)
        await log_entry(db_session, property_id=prop_id, module_name="checkin",
                        action_type="checkin", target_entity="booking",
                        target_record_id=uuid.uuid4(), timestamp=t)
        await db_session.flush()

        logs, total = await query_logs(db_session, property_id=prop_id, module_name="housekeeping")
        assert total == 1
        assert logs[0].module_name == "housekeeping"

    @pytest.mark.asyncio
    async def test_query_by_action_type(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry, query_logs

        prop_id = uuid.uuid4()
        t = datetime(2025, 1, 1, 10, 0, 0)

        await log_entry(db_session, property_id=prop_id, module_name="m",
                        action_type="create", target_entity="e",
                        target_record_id=uuid.uuid4(), timestamp=t)
        await log_entry(db_session, property_id=prop_id, module_name="m",
                        action_type="delete", target_entity="e",
                        target_record_id=uuid.uuid4(), timestamp=t)
        await db_session.flush()

        logs, total = await query_logs(db_session, property_id=prop_id, action_type="delete")
        assert total == 1
        assert logs[0].action_type == "delete"

    @pytest.mark.asyncio
    async def test_query_pagination(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry, query_logs

        prop_id = uuid.uuid4()
        t = datetime(2025, 1, 1, 10, 0, 0)

        for i in range(10):
            await log_entry(db_session, property_id=prop_id, module_name="m",
                            action_type=f"action_{i}", target_entity="e",
                            target_record_id=uuid.uuid4(),
                            timestamp=t + timedelta(seconds=i))
        await db_session.flush()

        logs, total = await query_logs(db_session, property_id=prop_id, skip=0, limit=3)
        assert total == 10
        assert len(logs) == 3

        logs2, _ = await query_logs(db_session, property_id=prop_id, skip=7, limit=3)
        assert len(logs2) == 3

    @pytest.mark.asyncio
    async def test_query_time_range(self, db_session, patched_audit_model):
        from app.modules.audit.service import log_entry, query_logs

        prop_id = uuid.uuid4()
        t1 = datetime(2025, 1, 1, 10, 0, 0)
        t2 = datetime(2025, 6, 1, 10, 0, 0)
        t3 = datetime(2025, 12, 1, 10, 0, 0)

        await log_entry(db_session, property_id=prop_id, module_name="m",
                        action_type="a", target_entity="e",
                        target_record_id=uuid.uuid4(), timestamp=t1)
        await log_entry(db_session, property_id=prop_id, module_name="m",
                        action_type="a", target_entity="e",
                        target_record_id=uuid.uuid4(), timestamp=t2)
        await log_entry(db_session, property_id=prop_id, module_name="m",
                        action_type="a", target_entity="e",
                        target_record_id=uuid.uuid4(), timestamp=t3)
        await db_session.flush()

        logs, total = await query_logs(
            db_session, property_id=prop_id,
            since=datetime(2025, 3, 1),
            until=datetime(2025, 9, 1),
        )
        assert total == 1


# ---------------------------------------------------------------------------
# Tests: Router API endpoints
# ---------------------------------------------------------------------------

class TestAuditRouter:
    """Test the audit API endpoints via HTTP client."""

    @pytest_asyncio.fixture
    async def audit_client(self, engine, patched_audit_model):
        from app.modules.audit.router import router
        from app.infra.database import get_db
        from fastapi import FastAPI

        test_app = FastAPI()
        test_app.include_router(router, prefix="/audit")

        session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

        async def override_get_db():
            async with session_factory() as session:
                yield session

        test_app.dependency_overrides[get_db] = override_get_db

        transport = ASGITransport(app=test_app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac

    @pytest.mark.asyncio
    async def test_list_audit_logs_empty(self, audit_client):
        resp = await audit_client.get("/audit/")
        assert resp.status_code == 200
        data = resp.json()
        assert data["items"] == []
        assert data["total"] == 0

    @pytest.mark.asyncio
    async def test_verify_chain_empty(self, audit_client):
        resp = await audit_client.get("/audit/verify")
        assert resp.status_code == 200
        data = resp.json()
        assert data["valid"] is True
        assert data["total_entries"] == 0
