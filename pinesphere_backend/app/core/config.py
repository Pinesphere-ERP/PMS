from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Pinesphere Stay API"
    VERSION: str = "1.0.0"
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./pinesphere.db")
    ALEMBIC_DATABASE_URL: str = os.getenv("ALEMBIC_DATABASE_URL", "sqlite+aiosqlite:///./pinesphere.db")
    
    @field_validator("DATABASE_URL", "ALEMBIC_DATABASE_URL", mode="before")
    @classmethod
    def clean_db_url(cls, v: str) -> str:
        if isinstance(v, str) and v.startswith("postgres"):
            return v.replace("sslmode=require", "ssl=require")
        return v
    
    # Security
    SECRET_KEY: str = "supersecretkey-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # MinIO
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadminpassword"
    MINIO_SECURE: bool = False

    # Razorpay
    RAZORPAY_KEY_ID: str = "rzp_test_TBltKnepLoWSBB"
    RAZORPAY_KEY_SECRET: str = "I3qR6re7q37euzRxXEeh7P0S"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

settings = Settings()
