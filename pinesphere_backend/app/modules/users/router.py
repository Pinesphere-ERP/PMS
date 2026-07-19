import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import assert_property_access, get_current_role, get_current_user, require_permission, require_super_admin
from app.core.security import get_password_hash
from app.infra.database import get_db
from app.infra.models import Role, User, UserSession
from app.modules.audit.logger import AuditLogger
from app.modules.users.schemas import UserCreateRequest, UserResponse, UserUpdateRequest

router = APIRouter()


async def _require_target_access(user: User, current_user: User, db: AsyncSession) -> None:
    if user.property_id:
        await assert_property_access(user.property_id, current_user, db)
    elif (await get_current_role(current_user, db)).role_code != "SUPER_ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


@router.get("", response_model=List[UserResponse])
async def list_users(
    property_id: Optional[uuid.UUID] = None,
    unassigned_only: bool = False,
    current_user: User = Depends(require_permission("USERS", "VIEW")),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(User)
    if property_id:
        await assert_property_access(property_id, current_user, db)
        stmt = stmt.where(User.property_id == property_id)
    elif current_user.property_id:
        stmt = stmt.where(User.property_id == current_user.property_id)
    elif (await get_current_role(current_user, db)).role_code != "SUPER_ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Property scope required")
    if unassigned_only:
        if (await get_current_role(current_user, db)).role_code != "SUPER_ADMIN":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Super admin access required")
        stmt = stmt.where(User.property_id.is_(None))
    return (await db.execute(stmt)).scalars().all()


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: UserCreateRequest,
    current_user: User = Depends(require_permission("USERS", "FULL")),
    db: AsyncSession = Depends(get_db),
):
    current_role = await get_current_role(current_user, db)
    
    # If super admin, allow them to specify property_id in payload. Otherwise force to caller's property
    if current_role.role_code == "SUPER_ADMIN":
        target_property_id = payload.property_id
        if target_property_id:
            await assert_property_access(target_property_id, current_user, db)
    else:
        target_property_id = current_user.property_id
        if not target_property_id:
            raise HTTPException(status_code=400, detail="Cannot create user without a property scope")

    role = (await db.execute(select(Role).where(Role.id == payload.role_id))).scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")
        
    duplicate = (await db.execute(select(User).where(User.property_id == target_property_id, User.email == payload.email))).scalar_one_or_none()
    if duplicate:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered in this property")
        
    user = User(
        id=uuid.uuid4(), property_id=target_property_id, role_id=payload.role_id,
        name=payload.name, mobile_number=payload.mobile_number, email=payload.email,
        password_hash=get_password_hash(payload.password), status="ACTIVE", created_by=current_user.id,
    )
    db.add(user)
    await db.flush()
    await AuditLogger.log(db, module_name="userRoleManagement", action_type="user_create", target_entity="user", target_record_id=user.id, property_id=target_property_id, user_id=current_user.id, new_value={"name": user.name, "role": role.role_code})
    return user


@router.post("/roles", dependencies=[Depends(require_super_admin)])
async def create_role(role_code: str, role_name: str, db: AsyncSession = Depends(get_db)):
    new_role = Role(id=uuid.uuid4(), role_code=role_code, role_name=role_name, is_system_role=True, description=f"{role_name} role")
    db.add(new_role)
    
    await AuditLogger.log(
        db, 
        module_name="userRoleManagement", 
        action_type="role_create", 
        target_entity="role", 
        target_record_id=new_role.id,
        new_value={"role_code": role_code}
    )
    
    return {"status": "success"}


@router.get("/roles")
async def list_roles(db: AsyncSession = Depends(get_db)):
    stmt = select(Role)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(user_id: uuid.UUID, payload: UserUpdateRequest, current_user: User = Depends(require_permission("USERS", "FULL")), db: AsyncSession = Depends(get_db)):
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await _require_target_access(user, current_user, db)
    if payload.role_id:
        if not (await db.execute(select(Role).where(Role.id == payload.role_id))).scalar_one_or_none():
            raise HTTPException(status_code=404, detail="Role not found")
        user.role_id = payload.role_id
    for field in ("name", "email", "mobile_number", "status"):
        value = getattr(payload, field)
        if value is not None:
            setattr(user, field, value)
    await AuditLogger.log(
        db, 
        module_name="userRoleManagement", 
        action_type="user_update", 
        target_entity="user", 
        target_record_id=user.id, 
        property_id=user.property_id, 
        user_id=current_user.id
    )
    return user


@router.post("/{user_id}/deactivate")
async def deactivate_user(user_id: uuid.UUID, current_user: User = Depends(require_permission("USERS", "FULL")), db: AsyncSession = Depends(get_db)):
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await _require_target_access(user, current_user, db)
    if user.is_primary_owner:
        raise HTTPException(status_code=400, detail="Primary Owner cannot be deactivated directly")
    user.status = "INACTIVE"
    await db.execute(update(UserSession).where(UserSession.user_id == user_id, UserSession.revoked_at.is_(None)).values(revoked_at=func.now(), revoked_reason="DEACTIVATION"))
    
    await AuditLogger.log(
        db, 
        module_name="userRoleManagement", 
        action_type="user_deactivate", 
        target_entity="user", 
        target_record_id=user.id, 
        property_id=user.property_id, 
        user_id=current_user.id
    )
    
    return {"status": "success", "detail": "User deactivated successfully"}


@router.post("/{user_id}/reset-credential")
async def reset_credential(user_id: uuid.UUID, password: Optional[str] = None, pin: Optional[str] = None, current_user: User = Depends(require_permission("USERS", "FULL")), db: AsyncSession = Depends(get_db)):
    if not password and not pin:
        raise HTTPException(status_code=400, detail="Must provide password or PIN")
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await _require_target_access(user, current_user, db)
    if password:
        user.password_hash = get_password_hash(password)
    if pin:
        user.pin_hash = get_password_hash(pin)
        
    await AuditLogger.log(
        db, 
        module_name="userRoleManagement", 
        action_type="credential_reset", 
        target_entity="user", 
        target_record_id=user.id, 
        property_id=user.property_id, 
        user_id=current_user.id
    )
        
    return {"status": "success", "detail": "Credentials reset successfully"}
