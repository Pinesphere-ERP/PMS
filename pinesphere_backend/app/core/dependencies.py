from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import jwt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import uuid
from typing import Optional

from app.core.config import settings
from app.infra.database import get_db
from app.infra.models import User, RolePermission, Role

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> User:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id_str = payload.get("sub")
        if user_id_str is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication credentials")
        
        result = await db.execute(select(User).filter(User.id == uuid.UUID(user_id_str)))
        user = result.scalars().first()
        if user is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
        if user.status != "ACTIVE":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive user")
            
        return user
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication credentials")

def require_permission(permission_code: str):
    async def permission_checker(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
        # RBAC Check
        # Fast path for Super Admins or Primary Owners if you have them.
        # Otherwise, fetch permissions for user.role_id
        
        # We need a proper join between RolePermission and Permission to check the code
        from app.infra.models import Permission
        
        result = await db.execute(
            select(RolePermission)
            .join(Permission, RolePermission.permission_id == Permission.id)
            .filter(
                RolePermission.role_id == user.role_id,
                Permission.code == permission_code
            )
        )
        role_perm = result.scalars().first()
        if not role_perm or role_perm.access_level == "NONE":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Missing permission: {permission_code}")
            
        return user
    return permission_checker
