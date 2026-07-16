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
    
    # Database (No default fallback, must be in .env)
    DATABASE_URL: str
    ALEMBIC_DATABASE_URL: str
    
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
    
    # Security (No default fallback, must be in .env)
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # URLs
    BASE_URL: str = "http://localhost:8000"
    FRONTEND_URL: str = "http://localhost:3000"
    
    # CORS setup
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:5173", "http://localhost:8000"]
    
    # Redis
    REDIS_URL: str
    
    # MinIO
    MINIO_ENDPOINT: str
    MINIO_ACCESS_KEY: str
    MINIO_SECRET_KEY: str
    MINIO_SECURE: bool = False

    # Razorpay (Optional, but default None instead of empty string)
    RAZORPAY_KEY_ID: str | None = None
    RAZORPAY_KEY_SECRET: str | None = None
    
    # OCR
    OCR_API_KEY: str | None = None

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

settings = Settings()
