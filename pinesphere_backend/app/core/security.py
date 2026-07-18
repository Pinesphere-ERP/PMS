import jwt
import uuid
import bcrypt
from datetime import datetime, timedelta, timezone

from app.core.config import settings

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

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

def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except Exception:
        raise ValueError("Invalid token")
