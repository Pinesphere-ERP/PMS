import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, update, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.infra.models import User, Role, UserSession
from app.core.dependencies import get_current_user, require_permission
from app.core.security import get_password_hash
from app.modules.audit.logger import AuditLogger
from app.modules.users import schemas

router = APIRouter()

@router.get("/roles", response_model=List[schemas.RoleResponse])
async def list_roles(
    current_user: User = Depends(require_permission("USERS", "VIEW")),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Role)
    result = await db.execute(stmt)
    return result.scalars().all()

@router.post("/roles")
async def create_role(
    role_code: str,
    role_name: str,
    db: AsyncSession = Depends(get_db)
):
    import uuid
    new_role = Role(
        id=uuid.uuid4(),
        role_code=role_code,
        role_name=role_name,
        is_system_role=True,
        description=role_name + " role"
    )
    db.add(new_role)
    await db.commit()
    return {"status": "success"}

@router.get("", response_model=List[schemas.UserResponse])
async def list_users(
    property_id: Optional[uuid.UUID] = None,
    unassigned_only: bool = False,
    current_user: User = Depends(require_permission("USERS", "VIEW")),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User)
    
    # Scope check
    if current_user.active_property_id:
        stmt = stmt.where(User.property_id == current_user.active_property_id)
    else:
        if property_id:
            stmt = stmt.where(User.property_id == property_id)
        if unassigned_only:
            stmt = stmt.where(User.property_id.is_(None))
        
    result = await db.execute(stmt)
    users = result.scalars().all()
    return users

@router.post("", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: schemas.UserCreate,
    current_user: User = Depends(require_permission("USERS", "FULL")),
    db: AsyncSession = Depends(get_db)
):
    # Enforce property_id scoping
    target_property_id = current_user.active_property_id
        
    # Verify Role exists
    role_stmt = select(Role).where(Role.id == payload.role_id)
    role_res = await db.execute(role_stmt)
    role = role_res.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")
        
    # Verify unique mobile number per property (or globally for unassigned users)
    if target_property_id:
        dup_stmt = select(User).where(
            User.property_id == target_property_id,
            User.mobile_number == payload.mobile_number
        )
    else:
        dup_stmt = select(User).where(
            User.property_id.is_(None),
            User.mobile_number == payload.mobile_number
        )
    dup_res = await db.execute(dup_stmt)
    if dup_res.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already registered in this context"
        )
        
    # Hash password/PIN if present
    password_hash = get_password_hash(payload.password) if payload.password else None
    pin_hash = get_password_hash(payload.pin) if payload.pin else None
    
    new_user = User(
        id=uuid.uuid4(),
        property_id=target_property_id,
        role_id=payload.role_id,
        name=payload.name,
        mobile_number=payload.mobile_number,
        email=payload.email,
        username=payload.username,
        password_hash=password_hash,
        pin_hash=pin_hash,
        biometric_enabled=False,
        is_primary_owner=False,
        status="ACTIVE",
        failed_login_attempts=0,
        created_by=current_user.id
    )
    db.add(new_user)
    await db.flush()
    
    await AuditLogger.log(
        db,
        module_name="userRoleManagement",
        action_type="user_create",
        target_entity="user",
        target_record_id=new_user.id,
        property_id=target_property_id,
        user_id=current_user.id,
        new_value={"name": new_user.name, "role": role.role_code}
    )
    
    return new_user

@router.patch("/{user_id}", response_model=schemas.UserResponse)
async def update_user(
    user_id: uuid.UUID,
    payload: schemas.UserUpdate,
    current_user: User = Depends(require_permission("USERS", "FULL")),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User).where(User.id == user_id)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
    # Scope check
    if current_user.active_property_id and user.property_id != current_user.active_property_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
        
    old_val = {"name": user.name, "role_id": str(user.role_id), "status": user.status}
    new_val = {}
    
    if payload.name is not None:
        user.name = payload.name
        new_val["name"] = payload.name
    if payload.email is not None:
        user.email = payload.email
        new_val["email"] = payload.email
    if payload.status is not None:
        user.status = payload.status
        new_val["status"] = payload.status
    if payload.role_id is not None:
        role_stmt = select(Role).where(Role.id == payload.role_id)
        role_res = await db.execute(role_stmt)
        if not role_res.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")
        user.role_id = payload.role_id
        new_val["role_id"] = str(payload.role_id)
        
    await db.flush()
    
    await AuditLogger.log(
        db,
        module_name="userRoleManagement",
        action_type="user_update",
        target_entity="user",
        target_record_id=user.id,
        property_id=user.property_id,
        user_id=current_user.id,
        old_value=old_val,
        new_value=new_val
    )
    
    return user

@router.post("/{user_id}/deactivate")
async def deactivate_user(
    user_id: uuid.UUID,
    current_user: User = Depends(require_permission("USERS", "FULL")),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User).where(User.id == user_id)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
    # Scope check
    if current_user.active_property_id and user.property_id != current_user.active_property_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
        
    if user.is_primary_owner:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Primary Owner cannot be deactivated directly"
        )
        
    user.status = "INACTIVE"
    
    # Invalidate all user sessions
    sess_stmt = update(UserSession).where(
        UserSession.user_id == user_id,
        UserSession.revoked_at.is_(None)
    ).values(revoked_at=func.now(), revoked_reason="DEACTIVATION")
    await db.execute(sess_stmt)
    
    await db.flush()
    
    await AuditLogger.log(
        db,
        module_name="userRoleManagement",
        action_type="user_deactivate",
        target_entity="user",
        target_record_id=user.id,
        property_id=user.property_id,
        user_id=current_user.id,
        new_value={"status": "INACTIVE"}
    )
    
    return {"status": "success", "detail": "User deactivated successfully"}

@router.post("/{user_id}/reset-credential")
async def reset_credential(
    user_id: uuid.UUID,
    password: Optional[str] = None,
    pin: Optional[str] = None,
    current_user: User = Depends(require_permission("USERS", "FULL")),
    db: AsyncSession = Depends(get_db)
):
    if not password and not pin:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Must provide password or PIN")
        
    stmt = select(User).where(User.id == user_id)
    res = await db.execute(stmt)
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
    # Scope check
    if current_user.active_property_id and user.property_id != current_user.active_property_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
        
    new_vals = {}
    if password:
        user.password_hash = get_password_hash(password)
        new_vals["password_changed"] = True
    if pin:
        user.pin_hash = get_password_hash(pin)
        new_vals["pin_changed"] = True
        
    await db.flush()
    
    await AuditLogger.log(
        db,
        module_name="userRoleManagement",
        action_type="credential_reset",
        target_entity="user",
        target_record_id=user.id,
        property_id=user.property_id,
        user_id=current_user.id,
        new_value=new_vals
    )
    
    return {"status": "success", "detail": "Credentials reset successfully"}
