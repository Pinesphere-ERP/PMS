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
from app.core.responses import success_response, StandardResponse

router = APIRouter()


async def _require_target_access(user: User, current_user: User, db: AsyncSession) -> None:
    if user.property_id:
        await assert_property_access(user.property_id, current_user, db)
    elif (await get_current_role(current_user, db)).role_code != "SUPER_ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


@router.get("", response_model=StandardResponse)
async def list_users(
    property_id: Optional[uuid.UUID] = None,
    unassigned_only: bool = False,
    role_code: Optional[str] = None,
    current_user: User = Depends(require_permission("USERS", "VIEW")),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(User)
    
    if role_code:
        stmt = stmt.join(Role).where(Role.role_code == role_code)

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
        
    users = (await db.execute(stmt)).scalars().all()
    return success_response(data=users)


@router.post("", response_model=StandardResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: UserCreateRequest,
    current_user: User = Depends(require_permission("USERS", "FULL")),
    db: AsyncSession = Depends(get_db),
):
    current_role = await get_current_role(current_user, db)
    
    # Determine target property
    if current_role.role_code in ["SUPER_ADMIN", "OWNER"]:
        target_property_id = payload.property_id
        if target_property_id:
            await assert_property_access(target_property_id, current_user, db)
        elif current_role.role_code == "OWNER":
            raise HTTPException(status_code=400, detail="Property ID must be provided when creating a user")
    else:
        target_property_id = current_user.property_id
        if not target_property_id:
            raise HTTPException(status_code=400, detail="Cannot create user without a property scope")

    # Resolve the role being assigned
    if payload.role_id:
        role = (await db.execute(select(Role).where(Role.id == payload.role_id))).scalar_one_or_none()
    elif payload.role_code:
        role = (await db.execute(select(Role).where(Role.role_code == payload.role_code.upper()))).scalar_one_or_none()
    else:
        raise HTTPException(status_code=400, detail="Must provide role_id or role_code")
        
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    # Enforce: non-SUPER_ADMIN roles MUST have a property_id
    if role.role_code != "SUPER_ADMIN" and not target_property_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Property must be selected when creating a user with role '{role.role_name}'. Only Super Admin users can exist without a property."
        )

    # Check for duplicate email within property
    if payload.email:
        dup_email_stmt = select(User).where(
            User.property_id == target_property_id,
            User.email == payload.email
        )
        if target_property_id is None:
            dup_email_stmt = select(User).where(User.email == payload.email)
        duplicate = (await db.execute(dup_email_stmt)).scalar_one_or_none()
        if duplicate:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered in this property")

    # Check for duplicate username globally
    if payload.username:
        dup_username = (await db.execute(select(User).where(User.username == payload.username))).scalar_one_or_none()
        if dup_username:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already taken")

    # Check for duplicate mobile globally
    dup_mobile = (await db.execute(select(User).where(User.mobile_number == payload.mobile_number))).scalar_one_or_none()
    if dup_mobile:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Mobile number already registered")
        
    user = User(
        id=uuid.uuid4(),
        property_id=target_property_id,
        role_id=role.id,
        name=payload.name,
        mobile_number=payload.mobile_number,
        email=payload.email,
        username=payload.username,
        password_hash=get_password_hash(payload.password),
        status="ACTIVE",
        created_by=current_user.id,
    )
    db.add(user)
    await db.flush()
    await AuditLogger.log(db, module_name="userRoleManagement", action_type="user_create", target_entity="user", target_record_id=user.id, property_id=target_property_id, user_id=current_user.id, new_value={"name": user.name, "role": role.role_code})
    return success_response(data=user, message="User created successfully")




@router.post("/roles", response_model=StandardResponse, dependencies=[Depends(require_super_admin)])
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
    
    return success_response(message="Role created successfully")


@router.get("/roles", response_model=StandardResponse)
async def list_roles(db: AsyncSession = Depends(get_db)):
    stmt = select(Role)
    result = await db.execute(stmt)
    roles = result.scalars().all()
    return success_response(data=roles)


@router.patch("/{user_id}", response_model=StandardResponse)
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
    return success_response(data=user, message="User updated successfully")


@router.post("/{user_id}/deactivate", response_model=StandardResponse)
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
    
    return success_response(message="User deactivated successfully")


@router.post("/{user_id}/reset-credential", response_model=StandardResponse)
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
        
    return success_response(message="Credentials reset successfully")
