# 2. System Architecture

## Overview

Pinesphere Stay is composed of three primary applications connected through a shared REST API:

```
+------------------+        HTTPS REST        +--------------------+
|  Admin Portal    |  <----------------------> |                    |
|  (React/Vite)    |                           |   FastAPI Backend   |
+------------------+                           |  (Python 3.12)     |
                                               |                    |
+------------------+        HTTPS REST        |  /api/v1/*         |
|  Flutter Mobile  |  <----------------------> |                    |
|  App (Android/   |    Offline Sync Batch     +--------------------+
|  iOS/Windows)    |                                   |
+------------------+                                   |
                                                       v
                                           +--------------------+
                                           |   PostgreSQL DB    |
                                           |   (Neon Serverless)|
                                           +--------------------+
                                           |   (Optional)        |
                                           +--------------------+
                                           |   Redis Cache      |
                                           +--------------------+
                                           |   MinIO Storage    |
                                           +--------------------+
```

---

## Technology Stack

### Backend
| Component | Technology | Version |
|-----------|------------|---------|
| Framework | FastAPI | 0.139.0 |
| Language | Python | 3.12 |
| ORM | SQLAlchemy (async) | 2.0.51 |
| Migrations | Alembic | 1.18.5 |
| Auth | PyJWT + bcrypt | - |
| Password Hashing | bcrypt | 3.2.2 |
| Task Queue | Celery + Kombu | 5.6.3 |
| Rate Limiting | SlowAPI | 0.1.9 |
| Logging | structlog | 24.4.0 |
| Storage | MinIO (optional) | 7.2.20 |
| Caching | Redis (optional) | 8.0.1 |
| Payments | Razorpay + Stripe | - |
| WhatsApp | WhatsApp Business API (aiohttp) | - |
| Server | Uvicorn | 0.51.0 |
| OCR | External OCR API | - |

### Frontend (Super Admin Portal)
| Component | Technology |
|-----------|------------|
| Framework | React 18 |
| Build Tool | Vite |
| Routing | React Router v6 |
| HTTP | fetch API (custom fetchAPI wrapper) |
| Styling | Vanilla CSS |
| Icons | Lucide React |

### Mobile Application
| Component | Technology |
|-----------|------------|
| Framework | Flutter |
| Language | Dart (SDK 3.12+) |
| State Management | Riverpod (with riverpod_generator) |
| Local Database | ObjectBox (offline-first) |
| HTTP Client | Dio |
| Storage | flutter_secure_storage |
| Auth | JWT (stored in secure storage) |
| Background Tasks | WorkManager |
| Biometrics | local_auth |
| Payments | Razorpay Flutter |
| PDF Generation | pdf package |
| Navigation | GoRouter |
| Code Generation | build_runner + freezed + json_serializable |

### Database
| Component | Technology |
|-----------|------------|
| Production | PostgreSQL (Neon Serverless) |
| Development | SQLite (aiosqlite) |
| Schema | Multi-tenant via search_path |

---

## Backend Application Structure

```
app/
  main.py          -- FastAPI app creation, middleware, lifespan hooks
  api.py           -- Central APIRouter: registers all module routers
  core/
    config.py      -- Pydantic settings (reads .env)
    dependencies.py  -- get_current_user, require_super_admin, assert_property_access, RBAC
    security.py    -- create_access_token, create_refresh_token, verify_password, get_password_hash
    responses.py   -- StandardResponse model, success_response(), error_response()
    notifications.py  -- WhatsAppService class
    subscription_gate.py  -- require_active_subscription dependency
    limiter.py     -- SlowAPI rate limiter setup
    ocr.py         -- OCR document scanning helper
  infra/
    database.py    -- Engine, AsyncSessionLocal, get_db, Base, TimestampMixin, SyncMixin
    models.py      -- All SQLAlchemy ORM models (1108 lines)
  modules/
    auth/          -- Login, OTP, token refresh, logout, offline bootstrap
    properties/    -- Property CRUD, rooms, categories, images, documents
    bookings/      -- Guest creation, booking CRUD
    checkin/       -- Check-in workflow
    checkout/      -- Check-out, invoice, folio
    housekeeping/  -- Tasks, room status, maintenance, lost & found
    kitchen/       -- Food orders
    payments/      -- Payments, Razorpay integration
    subscriptions/ -- Plans, subscription CRUD
    devices/       -- Device registration, approval, global console
    users/         -- User creation, listing
    staff/         -- Staff management
    owners/        -- Owner listing
    portal/        -- Guest portal (auth, service requests)
    notifications/ -- In-app notification CRUD
    audit/         -- Audit log CRUD and logger
    reports/       -- KPIs, daily snapshots
    settings/      -- System config, property settings
    sync/          -- Offline sync push/pull endpoints
    onboarding/    -- Property onboarding wizard
    inventory/     -- Room inventory
    pricing/       -- Dynamic pricing rules
    documents/     -- Form C / foreign guest compliance
    broker/        -- Commission engine
    security/      -- Security incidents, cameras, watchlist
    security_guard/ -- Visitor logs, vehicle logs, incident reports
    manager/       -- Manager-level aggregated views
    accountant/    -- Accountant-level financial views
    dashboard/     -- Dashboard KPI endpoint
    tasks/         -- Task management (cross-role)
    guests/        -- Guest module (CRUD)
    amenities/     -- Amenity catalog
```

---

## Request Lifecycle

Every API request flows through this pipeline:

```
Client (Browser / Flutter / Mobile)
    |
    | HTTPS Request with:
    |   Authorization: Bearer <JWT>
    |   X-Tenant-ID: <property_id>   (optional)
    |   X-Active-Property-Id: <id>   (optional, for multi-property owners)
    v
FastAPI App (main.py)
    |
    |--> CORS Middleware (allows all origins)
    |--> SlowAPI Rate Limiting Middleware
    |
    v
Router (api.py -> module router)
    |
    |--> get_current_user() dependency:
    |       1. Decode JWT
    |       2. Verify JTI not revoked (UserSession table)
    |       3. Check session expiry
    |       4. Verify device fingerprint (Device table)
    |       5. Resolve active_property_id from headers or default
    |       6. Check UserPropertyAccess for non-primary properties
    |       7. Return User object with active_property_id injected
    |
    |--> require_active_subscription() dependency (for paywalled routes):
    |       1. Skip if SUPER_ADMIN
    |       2. Look up Subscription for active_property_id
    |       3. Auto-create Free Trial if no subscription exists
    |       4. Raise 402 if expired or non-active
    |
    |--> RBAC dependencies (e.g., require_super_admin, assert_property_access)
    |
    v
Route Handler Function
    |
    |--> Business Logic / Service
    |--> SQLAlchemy async query via AsyncSession
    |--> Audit log entry (AuditLogger.log())
    |--> WhatsApp notification (optional)
    v
StandardResponse(success=True, data=...)
    |
    v
Client
```

---

## Authentication Flow

```
[Client]                           [Backend]
   |                                   |
   |-- POST /auth/login (credentials)->|
   |                                   |-- Verify password (bcrypt)
   |                                   |-- Check device fingerprint
   |                                   |-- Revoke old sessions (if any)
   |                                   |-- Create UserSession record
   |                                   |-- JWT: {sub, tenant_id, jti, device_fp, exp}
   |<-- {access_token, refresh_token}--|
   |                                   |
   |-- POST /auth/offline-bootstrap -->|
   |<-- {role, permissions, props}  ---|    (mobile stores locally for offline)
   |                                   |
   |-- POST /auth/refresh ------------>|
   |<-- {new access_token}          ---|
   |                                   |
   |-- POST /auth/logout ------------->|
   |                                   |-- Set revoked_at on UserSession
   |<-- {success}                   ---|
```

---

## Multi-Tenancy Data Isolation

Every operational model carries a `property_id` column:
- `Booking.property_id`
- `Room.property_id`
- `Guest.property_id`
- `HousekeepingTask.property_id`
- etc.

All API endpoints enforce property isolation:
1. `assert_property_access(property_id, user, db)` checks the requesting user has access.
2. Queries always filter by `property_id` from the authenticated user context.
3. Super Admins bypass property checks but still pass a property context header for scoped views.

---

## Communication Between Components

| From | To | Protocol | Auth |
|------|----|----------|------|
| Admin Portal | Backend | HTTPS REST (fetch) | Bearer JWT in header |
| Flutter App | Backend | HTTPS REST (Dio) | Bearer JWT in header + X-Tenant-ID |
| Flutter App | ObjectBox | Local IPC | None (local DB) |
| Backend | PostgreSQL | asyncpg | DB credentials in env |
| Backend | Redis | redis.asyncio | REDIS_URL |
| Backend | MinIO | minio SDK | Access/Secret keys |
| Backend | WhatsApp | aiohttp (HTTPS) | WHATSAPP_ACCESS_TOKEN |
| Backend | Razorpay | razorpay SDK | Key ID + Secret |

---

## Deployment Architecture

```
GitHub Repository
    |
    v
Render (PaaS)
    |
    |--> pinesphere-backend (web service)
    |       buildCommand: pip install -r requirements.txt
    |       startCommand: alembic upgrade head && uvicorn app.main:app
    |
    v
Neon (Serverless PostgreSQL)
    |
    |--> Single database: neondb
    |--> Schemas: public (platform) + property_{uuid} (per-property)
```

---

## Cross-References

- All environment variables: [17-deployment.md](./17-deployment.md)
- Security model: [09-auth-security.md](./09-auth-security.md)
- Sync mechanism: [10-sync-engine.md](./10-sync-engine.md)
- Database schema: [04-database.md](./04-database.md)
