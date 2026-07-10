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
