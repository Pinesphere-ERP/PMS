# 5. Backend Documentation

## Overview

The backend is a **FastAPI** application running on **Python 3.12** with **SQLAlchemy async** ORM.

Entry point: `pinesphere_backend/app/main.py`  
API prefix: `/api/v1`  
Hosted at: `https://pms-bvko.onrender.com`

---

## Startup Lifecycle (lifespan)

On startup (`@asynccontextmanager lifespan`), the app checks:
1. **Database** — executes `SELECT 1` to verify connectivity.
2. **Redis** — pings if `REDIS_URL` is configured.
3. **MinIO** — calls `list_buckets()` if credentials are configured.

These checks are **non-fatal** — the app starts even if Redis or MinIO are unavailable (they are optional).

---

## Core Module: `app/core/`

### config.py — Settings

```python
class Settings(BaseSettings):
    PROJECT_NAME = "Pinesphere Stay API"
    VERSION = "1.0.0"
    DATABASE_URL: str           # Required
    ALEMBIC_DATABASE_URL: str   # Required
    SECRET_KEY: str             # Required
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    REDIS_URL: str | None       # Optional
    MINIO_ENDPOINT: str | None  # Optional
    RAZORPAY_KEY_ID: str | None # Optional
    OCR_API_KEY: str | None     # Optional
```
Reads from `.env` file. DATABASE_URL is cleaned to replace `sslmode=require` with `ssl=require` for asyncpg compatibility.

### security.py — Cryptography

| Function | Purpose |
|----------|---------|
| `verify_password(plain, hashed)` | bcrypt comparison |
| `get_password_hash(password)` | bcrypt hash generation |
| `create_access_token(user_id, tenant_id, device_fp)` | HS256 JWT, 30min expiry by default |
| `create_refresh_token(user_id, device_fp)` | HS256 JWT, 7-day expiry, includes `family` claim |
| `decode_access_token(token)` | Decode and validate JWT |

JWT payload fields:
- `sub` — user UUID
- `tenant_id` — property UUID
- `jti` — unique token ID (for revocation)
- `device_fp` — device fingerprint (for device binding)
- `exp` — expiry timestamp
- `type` — "access" or "refresh"

### dependencies.py — FastAPI Dependencies

| Dependency | Description |
|-----------|-------------|
| `get_current_user` | Decodes JWT, validates session, resolves active_property_id, returns User |
| `require_super_admin` | Asserts role_code == SUPER_ADMIN |
| `assert_property_access` | Validates user has access to the given property_id |
| `assert_resource_property_access` | Validates user has access to a resource's property |
| `require_property_access` | Dependency factory for property-scoped routes |
| `require_resource_property_access` | Dependency factory for resource-scoped routes |
| `require_permission` | Checks role_permissions table for a specific permission_code + level |
| `require_housekeeper_or_manager` | Allows specific roles |
| `get_current_role` | Returns the Role object for the current user |
| `resolve_owner_id` | Finds Owner by email/mobile match |

**ACCESS_LEVEL_ORDER** (hierarchy):
```
NONE (0) < VIEW (1) < OWN (2) < LIMITED (3) < FULL (4)
```

### responses.py — Response Format

All API endpoints return a `StandardResponse`:
```json
{
  "success": true,
  "message": "Success",
  "data": <any>,
  "pagination": { "total": N, "page": 1, "size": 50, "pages": N } | null,
  "meta": { "timestamp": "...", "requestId": "..." } | null
}
```

Error responses:
```json
{
  "success": false,
  "message": "Error description",
  "data": { "detail": [...] }
}
```

### subscription_gate.py — Paywall

`require_active_subscription` dependency:
1. Exempts SUPER_ADMIN.
2. Looks up the property's `Subscription` record.
3. If no subscription exists, **auto-creates a Free Trial** (5-year expiry).
4. Raises `HTTP 402` if subscription is not Active or is expired.

Applied via `_paywall = [Depends(require_active_subscription)]` in `api.py`.

---

## Module Documentation

### auth/ — Authentication

**Router:** `POST /api/v1/auth/*`

#### Login — `POST /auth/login`
**Flow:**
1. Accept `email`, `login_id`, or `mobile_number` + `password`.
2. Resolve user via `_resolve_user()` (matches any of the three identifiers).
3. Verify bcrypt password.
4. Check account status (ACTIVE required; LOCKED returns 403).
5. Increment failed attempts on wrong password; lock account at 5 failures.
6. Check if device is blacklisted.
7. Revoke previous sessions for the same device (if any).
8. Create `UserSession` record.
9. Return `TokenResponse` with access_token, refresh_token, role_code, and accessible properties.

#### Offline Bootstrap — `GET /auth/offline-bootstrap`
**Purpose:** Called by mobile app after login. Returns full user profile, permissions snapshot, and accessible properties. Mobile stores this locally for offline use.

#### OTP Flow
- `POST /auth/request-otp` — generates 6-digit OTP, stores bcrypt hash in `otp_requests` table.
- `POST /auth/verify-otp` — verifies OTP, logs in user.

#### Refresh Token — `POST /auth/refresh`
Accepts refresh_token, verifies it, revokes old session, creates new access_token + session.

#### Logout — `POST /auth/logout`
Revokes the current `UserSession` by setting `revoked_at`.

#### PIN and Biometric
- `POST /auth/set-pin` — stores bcrypt hash of 4-6 digit PIN.
- `POST /auth/pin-login` — validates PIN for quick re-authentication.
- `POST /auth/biometric-login` — currently validates device trust (biometric itself verified on device).

---

### properties/ — Property Management

**Router:** `GET|POST|PATCH|DELETE /api/v1/properties/*`

Key endpoints:
- `GET /properties` — list all properties (Super Admin: all; Owner: theirs; Staff: their property)
- `POST /properties` — create property + business + owner in one transaction (Super Admin only)
- `GET /properties/{property_id}` — full property detail
- `PATCH /properties/{property_id}` — update property
- `GET /properties/{property_id}/rooms` — list rooms for a property
- `POST /properties/{property_id}/rooms` — create room
- `GET /properties/{property_id}/room-categories` — list room categories
- `POST /properties/{property_id}/room-categories` — create room category
- `GET /properties/rooms` — global rooms list (filtered by `property_id` query param)
- `POST /properties/{property_id}/images` — upload property images
- `POST /properties/{property_id}/documents` — upload documents
- `PATCH /properties/{property_id}/bank-account` — update bank account
- `GET /properties/{property_id}/verification` — get verification status
- `PATCH /properties/{property_id}/verification/{field}` — update single verification flag

---

### bookings/ — Booking Management

**Router:** `GET|POST|PATCH /api/v1/bookings/*`

Key endpoints:
- `POST /bookings/guests` — create a guest record
- `GET /bookings/guests` — list guests for a property
- `POST /bookings` — create a booking (validates room availability, no double-booking)
- `GET /bookings` — list bookings with filters (property_id, status, date)
- `GET /bookings/{booking_id}` — full booking detail
- `PATCH /bookings/{booking_id}` — update booking details
- `POST /bookings/{booking_id}/cancel` — cancel a booking

Availability check: Before creating a booking, the service queries for overlapping confirmed/active bookings for the same room on the same date range. Returns `409` if unavailable.

---

### checkin/ — Check-In

**Router:** `POST /api/v1/checkin/*`

Key endpoints:
- `POST /checkin/{booking_id}` — process check-in
  - Creates `CheckIn` record
  - Updates `Booking.booking_status = "checked_in"`
  - Updates `Room.occupancy_status = "occupied"`
  - Sends WhatsApp welcome message
  - Creates guest portal OTP if needed
  - Creates audit log entry
- `GET /checkin` — list active check-ins
- `GET /checkin/{booking_id}` — get check-in details

---

### checkout/ — Check-Out

**Router:** `POST /api/v1/checkout/*`

Key endpoints:
- `POST /checkout/{booking_id}` — process check-out
  - Calculates folio (room charges + F&B + service charges + taxes)
  - Creates `CheckOut` record
  - Generates `Invoice` + `InvoiceItem` records
  - Updates `Booking.booking_status = "checked_out"`
  - Updates `Room.occupancy_status = "vacant"`
  - Updates `Room.housekeeping_status = "dirty"`
  - Sends WhatsApp checkout thank-you message with bill summary
  - Creates audit log

---

### housekeeping/ — Housekeeping & Maintenance

Key endpoints:
- `GET /housekeeping/tasks` — list HK tasks for a property
- `POST /housekeeping/tasks` — create HK task
- `PATCH /housekeeping/tasks/{task_id}` — update task status
- `GET /housekeeping/rooms` — room status board
- `PATCH /housekeeping/rooms/{room_id}/status` — update room clean/dirty status
- `GET /housekeeping/maintenance` — list maintenance tickets
- `POST /housekeeping/maintenance` — create maintenance ticket
- `GET /housekeeping/lost-found` — list lost & found items
- `POST /housekeeping/lost-found` — log found item

---

### payments/ — Payments

Key endpoints:
- `POST /payments` — record a payment (cash/UPI/card/bank transfer)
- `GET /payments` — list payments for a booking or property
- `POST /payments/razorpay/order` — create Razorpay payment order
- `POST /payments/razorpay/verify` — verify Razorpay payment signature
- `GET /payments/{payment_id}` — payment detail

---

### subscriptions/ — Subscription Management

Key endpoints:
- `GET /subscriptions` — list all subscriptions (Super Admin)
- `POST /subscriptions` — create subscription for a property
- `PATCH /subscriptions/{id}` — update subscription
- `GET /subscriptions/plans` — list subscription plans
- `POST /subscriptions/plans` — create a subscription plan

---

### devices/ — Device Management

Key endpoints:
- `POST /devices/register` — register a new device
- `GET /devices` — list devices for a property
- `PATCH /devices/{id}/approve` — approve a pending device
- `PATCH /devices/{id}/revoke` — revoke a device
- `GET /devices/global` — all devices across all properties (Super Admin)
- `GET /devices/diagnostics` — device health diagnostics

---

### users/ — User Management

Key endpoints:
- `GET /users` — list all users (Super Admin)
- `POST /users` — create a user for a property
- `GET /users/{user_id}` — get user detail
- `PATCH /users/{user_id}` — update user
- `POST /users/{user_id}/deactivate` — deactivate user

---

### sync/ — Offline Sync

Key endpoints:
- `POST /sync/push` — mobile pushes locally-created/updated records to server
- `POST /sync/pull` — mobile pulls server changes since a given timestamp

See [10-sync-engine.md](./10-sync-engine.md) for complete documentation.

---

### portal/ — Guest Portal

Key endpoints:
- `POST /portal/auth/login` — guest logs in with booking_reference + OTP
- `GET /portal/booking` — guest views their booking
- `POST /portal/service-request` — guest submits a service request
- `GET /portal/service-requests` — guest views their requests
- `GET /portal/folio` — guest views their current bill

---

### audit/ — Audit Logs

Key endpoints:
- `GET /audit` — list audit log entries (filterable by module, date, user, property)
- `GET /audit/{log_id}` — single audit entry detail

AuditLogger usage:
```python
await AuditLogger.log(
    db,
    module_name="checkin",
    action_type="CHECKIN",
    target_entity="check_ins",
    target_record_id=checkin.checkin_id,
    property_id=booking.property_id,
    user_id=current_user.id,
    new_value={"room": room_number, "guest": guest_name},
)
```

---

### dashboard/ — Dashboard

**Note:** The dashboard router uses synchronous SQLAlchemy (not async). This is a known issue that should be refactored.

`GET /dashboard` — Returns:
- `todays_arrivals` — bookings with check_in_date = today
- `todays_departures` — bookings with check_out_date = today
- `occupied_rooms` — rooms with occupancy_status = "occupied"
- `vacant_rooms` — rooms with occupancy_status = "vacant"
- `pending_checkouts` — active bookings where checkout date <= today
- `pending_payments_count`
- `revenue_today` — sum of completed payments today

---

### notifications/ — In-App Notifications

Key endpoints:
- `GET /notifications` — list notifications for current user
- `POST /notifications` — create notification
- `PATCH /notifications/{id}/read` — mark as read
- `POST /notifications/mark-all-read` — mark all as read

---

### reports/ — Reports & Analytics

Key endpoints:
- `GET /reports/kpi` — KPI summary for a property and date range
- `GET /reports/revenue` — revenue breakdown
- `GET /reports/occupancy` — occupancy statistics
- `POST /reports/snapshot` — generate daily KPI snapshot

---

### security/ — Security Management

Key endpoints:
- `GET /security/incidents` — list security incidents
- `POST /security/incidents` — create incident
- `GET /security/cameras` — list cameras
- `POST /security/cameras` — add camera
- `GET /security/watchlist` — list watchlist entries
- `POST /security/watchlist` — add to watchlist
- `GET /security/blacklist` — list blacklisted devices
- `POST /security/blacklist` — blacklist a device

---

### broker/ — Broker Commission Engine

Key endpoints:
- `POST /broker/rules` — create commission rule (rate % for a broker)
- `GET /broker/wallet/{broker_user_id}` — broker wallet balance
- `GET /broker/transactions` — commission transaction history
- `POST /broker/payout` — initiate commission payout
- `POST /broker/calculate` — calculate commission for a booking

---

## Cross-References

- All API endpoints: [06-api-reference.md](./06-api-reference.md)
- Database models: [04-database.md](./04-database.md)
- Authentication: [09-auth-security.md](./09-auth-security.md)
