"""
Integration tests for User & Role Management module.

Strategy:
- Uses production SQLAlchemy models directly with SQLite in-memory
- Creates all production tables from Base.metadata in SQLite
- Overrides get_current_user dependency for authenticated endpoint tests
- Tests: security utils, access levels, login, CRUD, deactivation, credential reset, seed integrity
"""
import asyncio
import uuid
from datetime import datetime, timedelta
from unittest.mock import MagicMock
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.infra.database import Base, get_db
from app.infra.models import User, Role, Permission, RolePermission, UserSession
from app.core.dependencies import get_current_user, require_permission

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------
SQLITE_URL = "sqlite+aiosqlite:///:memory:"
PROPERTY_ID = str(uuid.uuid4())
OWNER_ROLE_ID = str(uuid.uuid4())
MANAGER_ROLE_ID = str(uuid.uuid4())
RECEPTION_ROLE_ID = str(uuid.uuid4())
OWNER_USER_ID = str(uuid.uuid4())
MANAGER_USER_ID = str(uuid.uuid4())
USERS_PERM_ID = str(uuid.uuid4())
BOOKINGS_PERM_ID = str(uuid.uuid4())


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def engine():
    eng = create_async_engine(SQLITE_URL, echo=False)
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await eng.dispose()


async def _seed_data(session: AsyncSession):
    """Populate roles, permissions, role-permissions, and users."""
    # Roles
    session.add_all([
        Role(id=uuid.UUID(OWNER_ROLE_ID), role_code="owner", role_name="Owner", is_system_role=True),
        Role(id=uuid.UUID(MANAGER_ROLE_ID), role_code="manager", role_name="Manager", is_system_role=True),
        Role(id=uuid.UUID(RECEPTION_ROLE_ID), role_code="reception", role_name="Reception", is_system_role=True),
    ])
    await session.flush()

    # Permissions
    session.add_all([
        Permission(id=uuid.UUID(USERS_PERM_ID), permission_code="USERS", module_name="userRoleManagement"),
        Permission(id=uuid.UUID(BOOKINGS_PERM_ID), permission_code="BOOKINGS", module_name="bookingManagement"),
    ])
    await session.flush()

    # Role Permissions
    session.add_all([
        RolePermission(role_id=uuid.UUID(OWNER_ROLE_ID), permission_id=uuid.UUID(USERS_PERM_ID), access_level="FULL"),
        RolePermission(role_id=uuid.UUID(OWNER_ROLE_ID), permission_id=uuid.UUID(BOOKINGS_PERM_ID), access_level="FULL"),
        RolePermission(role_id=uuid.UUID(MANAGER_ROLE_ID), permission_id=uuid.UUID(USERS_PERM_ID), access_level="LIMITED"),
        RolePermission(role_id=uuid.UUID(MANAGER_ROLE_ID), permission_id=uuid.UUID(BOOKINGS_PERM_ID), access_level="FULL"),
        RolePermission(role_id=uuid.UUID(RECEPTION_ROLE_ID), permission_id=uuid.UUID(USERS_PERM_ID), access_level="VIEW"),
        RolePermission(role_id=uuid.UUID(RECEPTION_ROLE_ID), permission_id=uuid.UUID(BOOKINGS_PERM_ID), access_level="LIMITED"),
    ])
    await session.flush()

    # Users
    session.add_all([
        User(
            id=uuid.UUID(OWNER_USER_ID), property_id=uuid.UUID(PROPERTY_ID),
            role_id=uuid.UUID(OWNER_ROLE_ID), name="Test Owner",
            mobile_number="9876543210", email="owner@test.com", username="owner",
            password_hash=get_password_hash("OwnerPass123!"),
            pin_hash=get_password_hash("1234"),
            is_primary_owner=True, status="ACTIVE",
        ),
        User(
            id=uuid.UUID(MANAGER_USER_ID), property_id=uuid.UUID(PROPERTY_ID),
            role_id=uuid.UUID(MANAGER_ROLE_ID), name="Test Manager",
            mobile_number="9876543211", email="manager@test.com", username="manager",
            password_hash=get_password_hash("ManagerPass123!"),
            is_primary_owner=False, status="ACTIVE",
        ),
    ])
    await session.flush()


@pytest_asyncio.fixture(scope="function")
async def seeded_engine(engine):
    session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with session_factory() as session:
        async with session.begin():
            await _seed_data(session)
    yield engine


def _build_app(seeded_engine, as_user_id=None):
    """Build FastAPI test app with optional auth override."""
    from app.modules.auth.router import router as auth_router
    from app.modules.users.router import router as users_router
    from fastapi import FastAPI

    test_app = FastAPI()
    test_app.include_router(auth_router, prefix="/auth")
    test_app.include_router(users_router, prefix="/users")

    session_factory = async_sessionmaker(seeded_engine, expire_on_commit=False, class_=AsyncSession)

    async def override_get_db():
        async with session_factory() as session:
            async with session.begin():
                yield session

    test_app.dependency_overrides[get_db] = override_get_db

    if as_user_id:
        async def override_get_current_user():
            async with session_factory() as session:
                result = await session.execute(select(User).where(User.id == uuid.UUID(as_user_id)))
                user = result.scalars().first()
                if not user:
                    from fastapi import HTTPException, status
                    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Test user not found")
                return user
        test_app.dependency_overrides[get_current_user] = override_get_current_user

        # Also override require_permission's inner dependency to bypass RBAC for owner
        def override_require_perm(perm_code, level="VIEW"):
            return override_get_current_user
        # We monkey-patch the require_permission calls in the users router
        # by overriding the get_current_user dep that require_permission calls internally

    return test_app


# ===========================================================================
# Test: Security Module (pure unit tests - no DB)
# ===========================================================================

class TestSecurityModule:
    def test_password_hash_roundtrip(self):
        pw = "TestPassword123!"
        hashed = get_password_hash(pw)
        assert hashed != pw
        assert verify_password(pw, hashed) is True

    def test_wrong_password_rejected(self):
        hashed = get_password_hash("correct_password")
        assert verify_password("wrong_password", hashed) is False

    def test_pin_hash_roundtrip(self):
        pin = "1234"
        hashed = get_password_hash(pin)
        assert verify_password(pin, hashed) is True
        assert verify_password("9999", hashed) is False

    def test_access_token_payload(self):
        import jwt as pyjwt
        from app.core.config import settings
        token = create_access_token(user_id="uid-123", tenant_id="tid-456", device_fp="fp-test")
        decoded = pyjwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        assert decoded["sub"] == "uid-123"
        assert decoded["tenant_id"] == "tid-456"
        assert decoded["type"] == "access"
        assert "jti" in decoded
        assert "exp" in decoded

    def test_refresh_token_payload(self):
        import jwt as pyjwt
        from app.core.config import settings
        token = create_refresh_token(user_id="uid-123", device_fp="fp-test")
        decoded = pyjwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        assert decoded["sub"] == "uid-123"
        assert decoded["type"] == "refresh"
        assert "family" in decoded


# ===========================================================================
# Test: Access Level Ordering
# ===========================================================================

class TestAccessLevelOrdering:
    def test_level_hierarchy(self):
        from app.core.dependencies import ACCESS_LEVEL_ORDER
        assert ACCESS_LEVEL_ORDER["NONE"] < ACCESS_LEVEL_ORDER["VIEW"]
        assert ACCESS_LEVEL_ORDER["VIEW"] < ACCESS_LEVEL_ORDER["OWN"]
        assert ACCESS_LEVEL_ORDER["OWN"] < ACCESS_LEVEL_ORDER["LIMITED"]
        assert ACCESS_LEVEL_ORDER["LIMITED"] < ACCESS_LEVEL_ORDER["FULL"]

    def test_all_levels_present(self):
        from app.core.dependencies import ACCESS_LEVEL_ORDER
        expected = {"NONE", "VIEW", "OWN", "LIMITED", "FULL"}
        assert set(ACCESS_LEVEL_ORDER.keys()) == expected


# ===========================================================================
# Test: Auth Login
# ===========================================================================

class TestAuthLogin:
    @pytest.mark.asyncio
    async def test_login_valid_credentials(self, seeded_engine):
        app = _build_app(seeded_engine)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post("/auth/login", json={
                "email": "owner@test.com", "password": "OwnerPass123!",
            })
            assert res.status_code == 200, f"Login failed: {res.text}"
            data = res.json()
            assert "access_token" in data
            assert "refresh_token" in data
            assert data["token_type"] == "bearer"

    @pytest.mark.asyncio
    async def test_login_invalid_password(self, seeded_engine):
        app = _build_app(seeded_engine)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post("/auth/login", json={
                "email": "owner@test.com", "password": "WrongPassword!",
            })
            assert res.status_code == 401

    @pytest.mark.asyncio
    async def test_login_nonexistent_user(self, seeded_engine):
        app = _build_app(seeded_engine)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post("/auth/login", json={
                "email": "nobody@test.com", "password": "anything",
            })
            assert res.status_code == 401

    @pytest.mark.asyncio
    async def test_login_with_pin(self, seeded_engine):
        app = _build_app(seeded_engine)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post("/auth/login", json={
                "email": "owner@test.com", "password": "1234",
            })
            assert res.status_code == 200
            assert "access_token" in res.json()


# ===========================================================================
# Test: User CRUD (as Owner)
# ===========================================================================

class TestUserCRUD:
    @pytest.mark.asyncio
    async def test_list_users(self, seeded_engine):
        app = _build_app(seeded_engine, as_user_id=OWNER_USER_ID)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.get("/users", headers={"Authorization": "Bearer fake"})
            assert res.status_code == 200
            data = res.json()
            assert isinstance(data, list)
            assert len(data) >= 2

    @pytest.mark.asyncio
    async def test_create_user(self, seeded_engine):
        app = _build_app(seeded_engine, as_user_id=OWNER_USER_ID)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post("/users", json={
                "name": "New Staff", "mobile_number": "9876543212",
                "role_id": RECEPTION_ROLE_ID, "email": "newstaff@test.com",
                "password": "StaffPass123!", "pin": "5678",
            }, headers={"Authorization": "Bearer fake"})
            assert res.status_code == 201, f"Create user failed: {res.text}"
            data = res.json()
            assert data["name"] == "New Staff"
            assert data["status"] == "ACTIVE"

    @pytest.mark.asyncio
    async def test_create_duplicate_mobile_rejected(self, seeded_engine):
        app = _build_app(seeded_engine, as_user_id=OWNER_USER_ID)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            await client.post("/users", json={
                "name": "First", "mobile_number": "1111111111", "role_id": RECEPTION_ROLE_ID,
            }, headers={"Authorization": "Bearer fake"})
            res = await client.post("/users", json={
                "name": "Duplicate", "mobile_number": "1111111111", "role_id": RECEPTION_ROLE_ID,
            }, headers={"Authorization": "Bearer fake"})
            assert res.status_code == 400
            assert "already registered" in res.json()["detail"]

    @pytest.mark.asyncio
    async def test_update_user(self, seeded_engine):
        app = _build_app(seeded_engine, as_user_id=OWNER_USER_ID)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.patch(
                f"/users/{MANAGER_USER_ID}",
                json={"name": "Updated Manager"},
                headers={"Authorization": "Bearer fake"}
            )
            assert res.status_code == 200
            assert res.json()["name"] == "Updated Manager"


# ===========================================================================
# Test: Deactivation
# ===========================================================================

class TestDeactivation:
    @pytest.mark.asyncio
    async def test_deactivate_regular_user(self, seeded_engine):
        app = _build_app(seeded_engine, as_user_id=OWNER_USER_ID)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post(
                f"/users/{MANAGER_USER_ID}/deactivate",
                headers={"Authorization": "Bearer fake"}
            )
            assert res.status_code == 200
            assert res.json()["status"] == "success"

    @pytest.mark.asyncio
    async def test_cannot_deactivate_primary_owner(self, seeded_engine):
        app = _build_app(seeded_engine, as_user_id=OWNER_USER_ID)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post(
                f"/users/{OWNER_USER_ID}/deactivate",
                headers={"Authorization": "Bearer fake"}
            )
            assert res.status_code == 400
            assert "Primary Owner" in res.json()["detail"]


# ===========================================================================
# Test: Credential Reset
# ===========================================================================

class TestCredentialReset:
    @pytest.mark.asyncio
    async def test_reset_password(self, seeded_engine):
        app = _build_app(seeded_engine, as_user_id=OWNER_USER_ID)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post(
                f"/users/{MANAGER_USER_ID}/reset-credential",
                params={"password": "NewPassword123!"},
                headers={"Authorization": "Bearer fake"}
            )
            assert res.status_code == 200
            assert res.json()["status"] == "success"

    @pytest.mark.asyncio
    async def test_reset_without_credential_fails(self, seeded_engine):
        app = _build_app(seeded_engine, as_user_id=OWNER_USER_ID)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            res = await client.post(
                f"/users/{MANAGER_USER_ID}/reset-credential",
                headers={"Authorization": "Bearer fake"}
            )
            assert res.status_code == 400
            assert "Must provide" in res.json()["detail"]


# ===========================================================================
# Test: Seed Data Integrity (direct DB queries)
# ===========================================================================

class TestSeedDataIntegrity:
    @pytest.mark.asyncio
    async def test_roles_seeded(self, seeded_engine):
        session_factory = async_sessionmaker(seeded_engine, expire_on_commit=False, class_=AsyncSession)
        async with session_factory() as session:
            result = await session.execute(select(Role))
            roles = result.scalars().all()
            codes = {r.role_code for r in roles}
            assert "owner" in codes
            assert "manager" in codes
            assert "reception" in codes

    @pytest.mark.asyncio
    async def test_permissions_seeded(self, seeded_engine):
        session_factory = async_sessionmaker(seeded_engine, expire_on_commit=False, class_=AsyncSession)
        async with session_factory() as session:
            result = await session.execute(select(Permission))
            perms = result.scalars().all()
            codes = {p.permission_code for p in perms}
            assert "USERS" in codes
            assert "BOOKINGS" in codes

    @pytest.mark.asyncio
    async def test_owner_password_verifies(self, seeded_engine):
        session_factory = async_sessionmaker(seeded_engine, expire_on_commit=False, class_=AsyncSession)
        async with session_factory() as session:
            result = await session.execute(select(User).where(User.id == uuid.UUID(OWNER_USER_ID)))
            user = result.scalars().first()
            assert user is not None
            assert verify_password("OwnerPass123!", user.password_hash) is True
            assert verify_password("WrongPassword", user.password_hash) is False

    @pytest.mark.asyncio
    async def test_owner_pin_verifies(self, seeded_engine):
        session_factory = async_sessionmaker(seeded_engine, expire_on_commit=False, class_=AsyncSession)
        async with session_factory() as session:
            result = await session.execute(select(User).where(User.id == uuid.UUID(OWNER_USER_ID)))
            user = result.scalars().first()
            assert user is not None
            assert verify_password("1234", user.pin_hash) is True
            assert verify_password("0000", user.pin_hash) is False
