from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.api import api_router

from contextlib import asynccontextmanager
import logging
from sqlalchemy import text
from minio import Minio
import redis.asyncio as redis
from fastapi.staticfiles import StaticFiles
import os

logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Database connection check
    try:
        from app.infra.database import engine
        async with engine.begin() as conn:
            await conn.execute(text("SELECT 1"))
        logger.info("Startup check: Database connection successful")
    except Exception as e:
        logger.warning(f"Startup check: Database connection failed: {e}")

    # 2. Redis connection check
    try:
        if settings.REDIS_URL:
            r = redis.from_url(settings.REDIS_URL)
            await r.ping()
            await r.aclose()
            logger.info("Startup check: Redis connection successful")
        else:
            logger.warning("Startup check: Redis URL not configured. Redis will be disabled locally.")
    except Exception as e:
        logger.warning(f"Startup check: Redis connection failed: {e}")

    # 3. MinIO connection check
    try:
        if settings.MINIO_ENDPOINT and settings.MINIO_ACCESS_KEY and settings.MINIO_SECRET_KEY:
            client = Minio(
                settings.MINIO_ENDPOINT,
                access_key=settings.MINIO_ACCESS_KEY,
                secret_key=settings.MINIO_SECRET_KEY,
                secure=settings.MINIO_SECURE,
            )
            client.list_buckets()
            logger.info("Startup check: MinIO connection successful")
        else:
            logger.warning("Startup check: MinIO credentials not configured. MinIO will be disabled locally.")
    except Exception as e:
        logger.warning(f"Startup check: MinIO connection failed: {e}")

    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Offline-First Enterprise PMS Backend API",
    lifespan=lifespan,
)

# CORS - allow configured origins only
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create uploads directory if it doesn't exist
os.makedirs("uploads", exist_ok=True)
app.mount("/api/v1/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(api_router, prefix="/api/v1")

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    with open("validation_error.log", "a") as f:
        f.write(f"Validation Error: {exc.errors()}\n")
        f.write(f"Body: {exc.body}\n")
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors(), "body": exc.body},
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled Exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal Server Error"},
    )

@app.get("/health")
async def health_check():
    return {"status": "ok", "version": settings.VERSION}
