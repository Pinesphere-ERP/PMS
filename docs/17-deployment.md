# 17. Deployment Guide

## Infrastructure Overview

| Component | Platform | URL |
|-----------|----------|-----|
| Backend API | Render.com (Web Service) | https://pms-bvko.onrender.com |
| Database | Neon Serverless PostgreSQL | neon.tech project |
| File Storage | MinIO (optional) | Self-hosted or MinIO Cloud |
| Cache | Redis (optional) | Redis Cloud or Render Redis |
| Admin Portal | Deployed separately or Render Static Sites | |

---

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL async connection string | `postgresql+asyncpg://user:pass@host/db?ssl=require` |
| `ALEMBIC_DATABASE_URL` | PostgreSQL sync connection string (for Alembic) | `postgresql://user:pass@host/db?sslmode=require` |
| `SECRET_KEY` | JWT signing secret (min 32 chars) | `your-super-secret-key-here` |

### Optional (Features degrade gracefully if missing)

| Variable | Description |
|----------|-------------|
| `REDIS_URL` | Redis connection string (caching) |
| `MINIO_ENDPOINT` | MinIO server endpoint |
| `MINIO_ACCESS_KEY` | MinIO access key |
| `MINIO_SECRET_KEY` | MinIO secret key |
| `RAZORPAY_KEY_ID` | Razorpay API key |
| `RAZORPAY_KEY_SECRET` | Razorpay secret |
| `WHATSAPP_API_URL` | WhatsApp Business API base URL |
| `WHATSAPP_PHONE_NUMBER_ID` | WhatsApp phone number ID |
| `WHATSAPP_ACCESS_TOKEN` | WhatsApp access token |
| `OCR_API_KEY` | OCR API key for document scanning |
| `FRONTEND_URL` | Admin portal URL (for CORS) |
| `BASE_URL` | Backend base URL (for generating file URLs) |

---

## Local Development Setup

### Prerequisites
- Python 3.12+
- Node.js 18+
- Flutter SDK 3.12+
- PostgreSQL or SQLite (auto-used in dev)

### Backend Setup

```bash
cd pinesphere_backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Create .env file
copy .env.example .env
# Edit .env and set DATABASE_URL=sqlite+aiosqlite:///./pinesphere.db

# Initialize database
python init_db.py

# Seed Super Admin
python seed_admin.py
# Default: email=admin@pinesphere.in, password=admin123

# Start server
uvicorn app.main:app --reload --port 8000
```

Backend will be available at: `http://localhost:8000`

API docs (Swagger): `http://localhost:8000/docs`

### Frontend Setup

```bash
cd web/admin

npm install
npm run dev
```

Admin portal at: `http://localhost:5173`

### Mobile Setup

```bash
cd pinesphere_stay

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run on Android emulator or device
flutter run

# To connect to local backend on Android emulator:
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1
```

---

## Render.com Deployment

### Configuration (render.yaml)

```yaml
services:
  - type: web
    name: pinesphere-backend
    env: python
    buildCommand: "cd pinesphere_backend && pip install -r requirements.txt"
    startCommand: "cd pinesphere_backend && alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT"
    envVars:
      - key: DATABASE_URL
        sync: false
      - key: ALEMBIC_DATABASE_URL
        sync: false
      - key: SECRET_KEY
        generateValue: true
```

**Important:** `generateValue: true` for `SECRET_KEY` means Render auto-generates a random key on first deploy. Copy it to all instances if running multiple replicas.

### Migration Strategy

Migrations run automatically at startup via `alembic upgrade head` in the start command.

**Alembic configuration:**
- `alembic.ini` — migration config
- `alembic/env.py` — uses `ALEMBIC_DATABASE_URL` (sync, not async)
- `alembic/versions/` — migration scripts

### Render Free Tier Limitations

- **Cold start:** Free tier instances spin down after 15 minutes of inactivity. First request after idle takes 30-90 seconds. This is why the Dio client has a 90-second timeout.
- **Bandwidth:** 100GB/month
- **No persistent disk** — file uploads stored locally will be lost on redeploy. Use MinIO.

---

## Database Migrations

```bash
cd pinesphere_backend

# Create a new migration
alembic revision --autogenerate -m "add_floor_to_rooms"

# Apply all pending migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# View migration history
alembic history
```

**Important:** Autogenerate may miss:
- Computed columns
- CHECK constraints
- Index changes (verify manually)
- Schema changes on PostgreSQL

Always review generated migrations before applying to production.

---

## Seeding Initial Data

**File:** `pinesphere_backend/seed_admin.py`

Creates:
1. Super Admin role (`SUPER_ADMIN`)
2. Super Admin user with email `admin@pinesphere.in`
3. Default permission set

Run once on a fresh database:
```bash
python seed_admin.py
```

---

## Health Check Endpoint

`GET /api/v1/health`

Returns:
```json
{ "status": "ok", "version": "1.0.0" }
```

Use this for uptime monitoring (Render, UptimeRobot, etc.).

---

## File Upload Storage

**Development:** Files are saved to `pinesphere_backend/uploads/` directory and served at `/api/v1/uploads/<filename>`.

**Production:** Configure MinIO for persistent object storage:
```env
MINIO_ENDPOINT=your-minio-server.com
MINIO_ACCESS_KEY=your-access-key
MINIO_SECRET_KEY=your-secret-key
```

Files are stored in the `pinesphere` bucket.

---

## Mobile App Build

```bash
# Android APK
flutter build apk --dart-define=API_URL=https://pms-bvko.onrender.com/api/v1

# Android App Bundle (Play Store)
flutter build appbundle --dart-define=API_URL=https://pms-bvko.onrender.com/api/v1

# Release signing
# Configure key.properties in android/ directory
```

---

## Cross-References

- Architecture: [02-architecture.md](./02-architecture.md)
- Backend modules: [05-backend.md](./05-backend.md)
- Developer guide: [18-developer-guide.md](./18-developer-guide.md)
