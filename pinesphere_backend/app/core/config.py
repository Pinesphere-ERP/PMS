from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Pinesphere Stay API"
    VERSION: str = "1.0.0"
    
    # Database — app connects as the non-superuser pinesphere_app role
    DATABASE_URL: str = "postgresql+asyncpg://pinesphere_app:pinesphere_password@localhost:5432/pinesphere"
    
    # Alembic migrations connect as the admin/superuser pinesphere role
    # (needed to create roles, grants, DDL that pinesphere_app cannot do)
    ALEMBIC_DATABASE_URL: str = "postgresql+asyncpg://pinesphere:pinesphere_password@localhost:5432/pinesphere"
    
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
