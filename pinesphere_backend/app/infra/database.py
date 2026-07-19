from typing import AsyncGenerator
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import MetaData, func, text
from fastapi import Request

from app.core.config import settings

# Naming conventions for clean Alembic migrations
convention = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=convention)

class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(server_default=func.now(), onupdate=func.now())

class TenantMixin:
    tenant_id: Mapped[UUID] = mapped_column(index=True)

class SyncMixin:
    """Fields required for offline-first synchronization."""
    last_modified_hlc: Mapped[str] = mapped_column(default="", index=True)
    is_deleted: Mapped[bool] = mapped_column(default=False)
    deleted_at: Mapped[datetime | None] = mapped_column(nullable=True)
    device_id: Mapped[str | None] = mapped_column(nullable=True)

# Engine + Session Factory
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_size=20,
    max_overflow=10,
    echo=False,
    connect_args={"timeout": 60},  # Increase timeout for serverless DB wake-up
    execution_options={"schema_translate_map": {"public": None}} if settings.DATABASE_URL.startswith("sqlite") else {}
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    expire_on_commit=False,  # CRITICAL for async
    class_=AsyncSession,
)

async def get_db(request: Request) -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        async with session.begin():
            # Extract tenant from request headers
            tenant_id = request.headers.get("x-tenant-id")
            
            if not settings.DATABASE_URL.startswith("sqlite"):
                if tenant_id:
                    safe_tenant_id = str(tenant_id).replace("-", "_")
                    await session.execute(text(f"SET search_path TO property_{safe_tenant_id}, public"))
                else:
                    await session.execute(text("SET search_path TO public"))
                
            yield session

async def provision_tenant_schema(tenant_id: str):
    """
    Creates a new schema for the given tenant and initializes the tables.
    """
    schema_name = f"property_{str(tenant_id).replace('-', '_')}"
    async with engine.begin() as conn:
        # Create the schema
        if not settings.DATABASE_URL.startswith("sqlite"):
            await conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
            # Set search path for the current connection session
            await conn.execute(text(f"SET search_path TO {schema_name}, public"))
        # Create all tables (platform tables will go to public because of schema='public',
        # tenant tables will go to the current search_path i.e., schema_name)
        
        # SQLite doesn't support schemas, so map 'public' to None
        conn_opt = await conn.execution_options(schema_translate_map={"public": None})
        await conn_opt.run_sync(Base.metadata.create_all)
