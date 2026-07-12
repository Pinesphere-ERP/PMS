from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Any

from app.infra.database import get_db
from .schemas import LoginRequest, TokenResponse, OfflineBootstrapRequest, RefreshRequest
from .service import AuthService

router = APIRouter()

def get_auth_service(db: AsyncSession = Depends(get_db)) -> AuthService:
    return AuthService(db)

@router.post("/login", response_model=TokenResponse)
async def login(
    request: LoginRequest,
    service: AuthService = Depends(get_auth_service)
) -> Any:
    return await service.login(request)

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshRequest,
    service: AuthService = Depends(get_auth_service)
) -> Any:
    return await service.refresh_token(request)

@router.post("/offline-bootstrap")
async def offline_bootstrap(
    request: OfflineBootstrapRequest,
    service: AuthService = Depends(get_auth_service)
):
    # This endpoint is to bootstrap local offline auth.
    # The device generates a pin hash and stores it on the cloud so that
    # the super admin can audit it, but the primary source of truth is local for offline.
    # For now, it's just a stub.
    return {"status": "offline auth bootstrapped"}

@router.post("/logout")
async def logout():
    # Logout is primarily a client-side operation (deleting tokens).
    # Server-side we might blacklist tokens or invalidate device sessions.
    return {"status": "logged out"}
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid

from app.infra.database import get_db
from app.infra.models import User
from app.modules.audit.logger import AuditLogger

router = APIRouter()


@router.post("/login")
async def login(
    mobile_number: str,
    password: str,
    db: AsyncSession = Depends(get_db),
):
    stmt = select(User).where(User.mobile_number == mobile_number)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or user.password_hash != password:
        await AuditLogger.log(
            db,
            module_name="auth",
            action_type="login_failure",
            target_entity="user",
            target_record_id=uuid.uuid4(),
            new_value={"mobile_number": mobile_number, "reason": "invalid_credentials"},
        )
        return {"status": "failure", "detail": "Invalid credentials"}

    await AuditLogger.log(
        db,
        module_name="auth",
        action_type="login_success",
        target_entity="user",
        target_record_id=user.id,
        user_id=user.id,
        property_id=user.property_id,
        new_value={"mobile_number": mobile_number},
    )
    return {"status": "success", "user_id": str(user.id)}


@router.post("/logout")
async def logout(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    await AuditLogger.log(
        db,
        module_name="auth",
        action_type="logout",
        target_entity="user",
        target_record_id=user_id,
        user_id=user_id,
    )
    return {"status": "success"}
