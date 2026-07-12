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

ACCESS_LEVEL_ORDER = {"NONE": 0, "VIEW": 1, "OWN": 2, "LIMITED": 3, "FULL": 4}

def require_permission(permission_code: str, required_level: str = "VIEW"):
    async def permission_checker(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
        from app.infra.models import Permission, Role
        
        # Fetch the role to check for superAdmin/owner bypass
        role_res = await db.execute(select(Role).filter(Role.id == user.role_id))
        role = role_res.scalars().first()
        if role and role.role_code in ("superAdmin", "owner"):
            return user
            
        result = await db.execute(
            select(RolePermission)
            .join(Permission, RolePermission.permission_id == Permission.id)
            .filter(
                RolePermission.role_id == user.role_id,
                Permission.permission_code == permission_code
            )
        )
        role_perm = result.scalars().first()
        if not role_perm:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Missing permission: {permission_code}")
            
        user_level = role_perm.access_level.upper()
        req_level = required_level.upper()
        
        if ACCESS_LEVEL_ORDER.get(user_level, 0) < ACCESS_LEVEL_ORDER.get(req_level, 0):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Insufficient permission level for: {permission_code}")
            
        return user
    return permission_checker
