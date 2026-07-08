import jwt
import uuid
from datetime import datetime, timedelta, timezone
from passlib.context import CryptContext

from src.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(user_id: str, tenant_id: str, device_fp: str, expires_delta: timedelta | None = None) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {
        "sub": user_id,
        "tenant_id": tenant_id,
        "jti": str(uuid.uuid4()),
        "device_fp": device_fp,
        "exp": expire,
        "type": "access"
    }
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def create_refresh_token(user_id: str, device_fp: str, family_id: str | None = None) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    
    to_encode = {
        "sub": user_id,
        "jti": str(uuid.uuid4()),
        "family": family_id or str(uuid.uuid4()),
        "device_fp": device_fp,
        "exp": expire,
        "type": "refresh"
    }
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
