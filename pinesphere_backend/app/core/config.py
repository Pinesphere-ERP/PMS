from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Pinesphere Stay API"
    VERSION: str = "1.0.0"

    # Seeding is intentionally opt-in and is run with `python -m app.seeds`.
    # It is never part of the web application's startup lifecycle.
    ENABLE_SEEDING: bool = False
    SEED_MODE: str = "development"
    SEED_ADMIN_USERNAME: str | None = None
    SEED_ADMIN_EMAIL: str | None = None
    SEED_ADMIN_PASSWORD: str | None = None
    SEED_ADMIN_NAME: str = "System Administrator"
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+asyncpg://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?ssl=require")
    ALEMBIC_DATABASE_URL: str = os.getenv("ALEMBIC_DATABASE_URL", "postgresql+asyncpg://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?ssl=require")
    
    @field_validator("DATABASE_URL", "ALEMBIC_DATABASE_URL", mode="before")
    @classmethod
    def clean_db_url(cls, v: str) -> str:
        if isinstance(v, str) and v.startswith("postgres"):
            return v.replace("sslmode=require", "ssl=require")
        return v

    @field_validator("SEED_MODE")
    @classmethod
    def validate_seed_mode(cls, value: str) -> str:
        mode = value.lower()
        if mode not in {"development", "demo", "production"}:
            raise ValueError("SEED_MODE must be development, demo, or production")
        return mode
    
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
