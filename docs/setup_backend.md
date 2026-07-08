# FastAPI Backend Setup Guide

This guide covers setting up the Python FastAPI backend, database migrations, and the required Docker infrastructure.

## Prerequisites

- **Python**: 3.11 or higher
- **Docker & Docker Compose**: Required for running PostgreSQL, Redis, and MinIO.

## 1. Infrastructure Setup (Docker)

The backend relies on three external services. From the `pinesphere_backend` directory, start the infrastructure:

```bash
cd pinesphere_backend
docker compose up -d
```

This will spin up:
- **PostgreSQL 16** on port `5432`
- **Redis 7** on port `6379`
- **MinIO** on ports `9000` (API) and `9001` (Console)

## 2. Python Environment Setup

It is highly recommended to use a virtual environment.

```bash
cd pinesphere_backend

# Create a virtual environment
python3 -m venv venv

# Activate the virtual environment
# On Linux/macOS:
source venv/bin/activate
# On Windows:
# .\venv\Scripts\activate

# Install all dependencies
pip install fastapi uvicorn sqlalchemy asyncpg alembic redis minio pydantic-settings pyjwt passlib bcrypt python-multipart celery psycopg2-binary
```

## 3. Database Migrations (Alembic)

Before starting the server, you need to apply the database migrations to set up the PostgreSQL schema.

```bash
# Generate an initial migration (if one doesn't exist yet)
alembic revision --autogenerate -m "Initial schema"

# Apply migrations to the database
alembic upgrade head
```

## 4. Running the Development Server

Start the FastAPI application using Uvicorn with hot-reloading enabled:

```bash
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

Once running, you can access the automatic interactive API documentation at:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## 5. Background Tasks (Celery)

If you are working on features that require background processing (like emails or heavy sync resolution), you must start the Celery worker:

```bash
celery -A src.worker.celery_app worker --loglevel=info
```
