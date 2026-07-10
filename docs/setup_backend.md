# Pinesphere Stay Backend Setup Guide

This document outlines the steps required to set up the Python FastAPI backend, PostgreSQL database, and Redis cache for Pinesphere Stay.

## Prerequisites
- **Python**: v3.11 or higher
- **Poetry**: (Optional, but recommended for dependency management) or `pip`
- **Docker & Docker Compose**: For running PostgreSQL, Redis, and MinIO locally.

## 1. Local Infrastructure (Docker)
The easiest way to spin up the required databases and object storage is using Docker.

Ensure you have a `docker-compose.yml` configured at the root of `pinesphere_backend` that includes:
- PostgreSQL 16
- Redis 7
- MinIO

To start the infrastructure:
```bash
cd pinesphere_backend
docker-compose up -d
```

## 2. Python Environment Setup
Navigate to the backend directory and create a virtual environment:

```bash
cd pinesphere_backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

Install the dependencies:
```bash
pip install -r requirements.txt
```
*(If using Poetry: `poetry install`)*

## 3. Database Migrations
Pinesphere Stay utilizes SQLAlchemy 2.0 with Async drivers and Alembic for migrations.
Once PostgreSQL is running, apply the migrations to construct the multi-tenant schema:

```bash
alembic upgrade head
```

## 4. Environment Variables
Create a `.env` file in the root of `pinesphere_backend`. You can copy the template:
```bash
cp .env.example .env
```
Ensure the database URL points to your local Docker instance:
`DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/pinesphere`

## 5. Running the Server
Run the FastAPI development server using Uvicorn from the `pinesphere_backend` root directory (do not `cd` into `app`):

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`. 
Interactive API documentation (Swagger UI) is available at `http://localhost:8000/docs`.

## 6. Running Celery (Background Tasks)
For the background sync and email processors:
```bash
celery -A app.core.celery_app worker --loglevel=info
```
