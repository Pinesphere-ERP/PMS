# Pinesphere Stay — Deep Implementation Audit Report
**Date:** 2026-07-18 | **Based on:** `Pinesphere_Stay_PRD (1).md`

---

> [!IMPORTANT]
> **Architecture Deviation (Global)**
> The PRD mandates Flutter Web for **Super Admin** and **Guest Portal**. The actual implementation uses:
> - **Super Admin** → React + Vite (`/admin`)
> - **Guest Portal** → Next.js (`/guest-portal`)
> - **Operational App** → Flutter ✅ (as specified)
> This is either an intentional design change or a critical deviation — it needs a formal decision.

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Fully implemented |
| ⚠️ | Partially implemented / stub only |
| ❌ | Not implemented |

---

## Phase 0: Foundation & Cross-Cutting Infrastructure

| PRD Requirement | Status | Evidence |
|---|---|---|
| PostgreSQL 15+, Redis 7+, MinIO setup | ✅ | `main.py` has lifespan checks for all three; `docker-compose.yml` exists |
| FastAPI skeleton with `/api/v1/` versioning | ✅ | `main.py` → `app.include_router(api_router, prefix="/api/v1")` |
| RBAC engine: `permissions`, `role_permissions` tables | ✅ | `models.py` → `Permission`, `RolePermission`, `Role` models defined |
| `role_permission_overrides` table | ❌ | No `role_permission_overrides` model found. The PRD specifies this separate override table. |
| Permission-check middleware (`require_permission`) | ⚠️ | `dependencies.py` has `require_permission()` factory, but it uses `active_role_id_resolved` which references a non-persisted dynamic attribute, making it fragile |
| JWT: 15min access / 7day refresh tokens | ✅ | `security.py` → `create_access_token` (configurable), `create_refresh_token` (7 days hardcoded) |
| JWT revocation / blacklist on logout | ⚠️ | Logout marks `UserSession` as `revoked_at` but the access token itself is not validated against this revocation on every request |
| Audit log infrastructure (`audit_logs` table) | ✅ | `AuditLog` model, `AuditLogger` class, `audit_service` all implemented |
| Insert-only enforcement on audit_logs | ❌ | No DB trigger enforcing insert-only. The model allows deletes at the ORM level. |
| Multi-property scoping helper | ✅ | `assert_property_access()`, `assert_resource_property_access()` in `dependencies.py` |
| Event backbone (Redis Streams / RabbitMQ) | ❌ | No event bus publisher/subscriber found. All events are handled in-process, not via a message broker. |
| Kotlin platform-channel scaffold + ObjectBox | ⚠️ | `objectbox-model.json` and `objectbox.g.dart` exist in Flutter project, but no Kotlin channel bridge code found. ObjectBox is configured but the native Kotlin layer referenced in PRD §15.2 is absent. |
| Global error handling (400/401/403/404/409/422/429/500) | ⚠️ | `main.py` has `RequestValidationError` (422) and a global 500 handler. 401/403/404 are thrown per-route. 429 (rate limiting) and 409 (conflict) have no global handler. |
| Field validation helpers (email, E.164, currency) | ⚠️ | Pydantic schemas validate types, but no global E.164 phone validator, no centralized currency validator, no booking reference format validator |

---

## Phase 1: Unified Login & Platform Routing (Module 4)

| PRD Requirement | Status | Evidence |
|---|---|---|
| `POST /api/v1/auth/resolve` with role resolution | ⚠️ | `POST /api/v1/auth/login` exists and resolves the user, but there is **no separate `/resolve` endpoint** that defers credentials. The PRD specifies resolve first, authenticate second. |
| App→Web redirect flow for Super Admin on App | ❌ | No `client_platform` header check, no deep link generator found |
| Web→App refusal flow | ❌ | Not implemented |
| `client_platform` header validation | ❌ | No header inspection for platform type in auth routes |
| Single Active Session Enforcement (`login_sessions`) | ⚠️ | `UserSession` model and session creation exist. No heartbeat-timeout logic or concurrent-violation auto-lock found. |
| Account unlock flow (OTP + Super Admin) | ❌ | No OTP verification system. `failed_login_attempts` is tracked in `User` model but no lockout or unlock flow exists. |
| Offline bootstrap endpoint | ✅ | `POST /api/v1/auth/offline-bootstrap` — returns role, permissions, pin_hash for offline use |
| Token refresh endpoint | ✅ | `POST /api/v1/auth/refresh` — validates refresh token, issues new tokens |
| Logout endpoint | ✅ | `POST /api/v1/auth/logout` — revokes session, writes audit log |

---

## Phase 2 / Module 1: Super Admin Portal (Web — React)

### Admin Portal Pages Implemented
| Page | Status | File |
|---|---|---|
| Login | ✅ | `pages/Login.jsx` |
| Platform Dashboard (KPI tiles) | ✅ | `pages/PropertyManagement/Dashboard.jsx` |
| All Properties list | ✅ | `pages/PropertyManagement/AllProperties.jsx` |
| Property Details view | ✅ | `pages/PropertyManagement/PropertyDetails.jsx` |
| Property Rooms view | ✅ | `pages/PropertyManagement/PropertyRooms.jsx` |
| Add Property Wizard | ✅ | `pages/PropertyManagement/AddPropertyWizard.jsx` + `AddProperty.jsx` |
| Verification Queue | ✅ | `pages/PropertyManagement/VerificationQueue.jsx` |
| Subscription Management (main) | ✅ | `pages/SubscriptionManagement/SubscriptionManagement.jsx` |
| Subscription Dashboard | ✅ | `pages/SubscriptionManagement/SubscriptionDashboard.jsx` |
| Subscription Plans CRUD | ✅ | `pages/SubscriptionManagement/SubscriptionPlans.jsx` |
| Active Subscriptions | ✅ | `pages/SubscriptionManagement/ActiveSubscriptions.jsx` |
| Renewal Management | ✅ | `pages/SubscriptionManagement/RenewalManagement.jsx` + `Renewals.jsx` |
| Device Management — Global Console | ✅ | `pages/DeviceManagement/GlobalDeviceConsole.jsx` |
| Device Management — My Devices Panel | ✅ | `pages/DeviceManagement/MyDevicesPanel.jsx` |
| Device Diagnostics | ✅ | `pages/DeviceManagement/DeviceDiagnosticsPanel.jsx` |
| Payments Overview | ✅ | `pages/SubscriptionManagement/Payments.jsx` + `PaymentManagement.jsx` |
| Licenses View | ✅ | `pages/SubscriptionManagement/Licenses.jsx` |
| Devices View | ✅ | `pages/SubscriptionManagement/Devices.jsx` |
| User Management | ✅ | `pages/UserManagement/UserManagement.jsx` |
| System Settings | ✅ | `pages/SystemManagement/SystemSettings.jsx` |
| Audit Logs | ✅ | `pages/AuditManagement/AuditLogs.jsx` |

### PRD Super Admin Requirements NOT Implemented in Admin Portal
| PRD Requirement | Status | Notes |
|---|---|---|
| Customer (Owner) lifecycle — suspend/archive/transfer-ownership | ⚠️ | User Management page exists, but no transfer-ownership or archive flows |
| Property backup / restore | ❌ | No backup/restore UI or API |
| Support tooling: force sync, view PII-masked logs, remote diagnostics | ⚠️ | Force-sync API endpoint exists. PII masking not implemented in log views. |
| Global reports async export for >10k rows | ❌ | No async export mechanism |
| Materialized views + 60s Redis cache for dashboard | ❌ | Dashboard data is computed on every request, no caching |
| Property allocation limit (room_limit) | ❌ | No `room_limit` field or enforcement on subscription assignment |
| Super Admin Security Dashboard | ⚠️ | Device console exists, but no real-time incident feed (WebSocket), no `security_incidents` table |

---

## Phase 3 / Module 2: Owner App (Flutter)

| PRD Requirement | Status | Evidence |
|---|---|---|
| Owner Dashboard (offline-capable KPI tiles) | ✅ | `dashboard/presentation/screens/dashboard_screen.dart` exists |
| Room Management CRUD | ✅ | `rooms/presentation/screens/` — `room_grid_screen`, `occupied_rooms_screen`, `vacant_rooms_screen` |
| Room pricing rules & amenities | ⚠️ | Room model has `base_price` on category. No per-room-type pricing rules engine. Amenities not modeled. |
| Room photo upload | ⚠️ | `image_url` field in `Room` model; upload endpoint exists on backend. UI flow unclear. |
| Room status state machine | ✅ | `occupancy_status` + `housekeeping_status` tracked; `clean_room` endpoint exists |
| Booking creation with availability check | ✅ | Backend `service.create_booking` performs availability check; Flutter `create_booking_sheet.dart` exists |
| Booking edit/cancel/confirm | ✅ | `PATCH /{booking_id}`, `POST /{booking_id}/cancel` implemented |
| Distributed lock + DB exclusion constraint on booking | ❌ | No Redis distributed lock found. No PostgreSQL exclusion constraint in migrations. |
| Offline conflict flagging for bookings | ⚠️ | Sync engine has LWW conflict detection, but no human-in-the-loop resolution UI for booking conflicts |
| Check-In with reason-code gating | ⚠️ | Check-in screen exists; reason-code override not found |
| Check-Out with reason-code gating | ⚠️ | Checkout screen exists; damage/laundry/minibar/restaurant bills on API; reason-code override not found |
| Payments: collect/refund-approve (segregation of duties) | ⚠️ | `payment_collection_screen.dart` exists. Refund-approve with segregation of duties not implemented. |
| Generate invoice | ⚠️ | `Invoice` model exists; no invoice generation (PDF) endpoint |
| Staff Management: create/disable within `staff_limit` | ⚠️ | Staff screens exist (`owner_staff_dashboard`, `staff_directory_screen`). No `staff_limit` enforcement found. |
| Staff device assignment | ⚠️ | `device_management` screens exist; no UI linking staff to specific devices |
| Token blacklist on staff disable | ❌ | No token blacklist on user disable. The `UserSession` revocation is not enforced on token validation. |
| Housekeeping/Kitchen/Maintenance oversight views | ✅ | `housekeeping_screen.dart`, `kitchen_screen.dart` exist |
| Reports (daily/weekly/monthly/occupancy/revenue) | ✅ | `reports_dashboard_screen.dart`, `todays_revenue_screen.dart`, `pl_report_screen.dart` |
| Nightly WhatsApp Business Summary cron job | ❌ | No WhatsApp integration, no cron scheduler found |
| Settings (business/WhatsApp/tax/notification/security) | ⚠️ | `settings_screen.dart` exists. WhatsApp and notification settings are placeholders. |

---

## Phase 4 / Module 3: Guest Portal (Next.js)

| PRD Requirement | Status | Evidence |
|---|---|---|
| Guest OTP authentication (booking-scoped, rate limits) | ⚠️ | `portal/router.py` — authenticates by booking reference + mobile, NOT OTP. Rate limits absent. |
| Guest Dashboard / Booking Details | ✅ | `guest-portal/src/app/page.tsx` (landing/dashboard) |
| Room Details view | ✅ | `guest-portal/src/app/room/` directory exists |
| Stay Duration display | ⚠️ | Check-in page exists (`/checkin/`), full stay timeline unclear |
| Service Requests (Housekeeping/Food/Laundry/etc.) | ⚠️ | `guest-portal/src/app/services/page.tsx` exists. Backend stub returns success without creating tasks. |
| Payments: pay outstanding + download invoice | ⚠️ | `guest-portal/src/app/payments/` exists. Backend payment endpoint returns 501 (not implemented) for new payments. |
| Documents: ID upload + OCR + nationality branching | ⚠️ | Backend has `ocr.py` in core; `documents` module exists. No OCR integration visible. No nationality branching. |
| Feedback (ratings, Google Review redirect) | ❌ | No feedback/rating module in backend or frontend |
| Post-checkout 30-day access enforcement | ❌ | No post-checkout access window logic found |
| Guest portal profile page | ✅ | `guest-portal/src/app/profile/` exists |
| Guest portal share feature | ✅ | `guest-portal/src/app/share/` exists |

---

## Phase 5: Owner Registration & Property Onboarding

| PRD Requirement | Status | Evidence |
|---|---|---|
| Self-service Owner registration flow (App) | ❌ | No owner self-registration flow in Flutter app |
| Admin-Assisted registration flow (Super Admin) | ✅ | `POST /api/v1/properties` creates owner + property; `AddPropertyWizard.jsx` in admin UI |
| Mandatory `assistance_reason` on admin-created owners | ❌ | No `assistance_reason` field in property creation schema |
| Pipeline state machine (Draft→PendingApproval→…→Active) | ⚠️ | `onboarding_status` field exists (draft/completed). Full 7-step state machine not implemented — only 2 states used. |
| Fill Basic Details / Save Draft | ✅ | `AddProperty.jsx` allows draft creation |
| Approve Property gate | ⚠️ | `onboarding_status` is set to `draft` on create. No formal approval gate that blocks downstream steps. |
| Assign Subscription step wired to pricing engine | ⚠️ | Subscription can be toggled in admin UI but not linked to onboarding pipeline gate |
| Register Device + Generate License (blocked pre-subscription) | ⚠️ | Device registration endpoint exists; subscription check not enforced as a gate |
| Activate Property (final unlock) | ⚠️ | Manually setting `onboarding_status=completed` via the backend |
| Property Onboarding screen (Flutter) | ✅ | `property_onboarding/presentation/screens/property_onboarding_screen.dart` |

---

## Phase 6: Dynamic Subscription & Pricing Rule Engine

| PRD Requirement | Status | Evidence |
|---|---|---|
| `pricing_plans`, `billing_cycle_options`, `pricing_rules` schema | ❌ | The `pricing` backend module only has a `rooms/` subdirectory and is mostly empty. `SubscriptionPlan` model exists but has no `pricing_rules` or `billing_cycle_options` tables. |
| Rule evaluation engine (condition matching, priority) | ❌ | No pricing rule evaluator found anywhere |
| Worked-example regression test (weekend vs weekday) | ❌ | No tests found |
| Room-based access (`room_limit` from confirmed payment) | ❌ | No `room_limit` enforcement |
| Super Admin rule-builder UI | ❌ | No pricing rule builder in admin portal |
| Quote API (`GET /pricing/plans/{id}/quote`) | ❌ | Not implemented |
| Equal-priority rule conflict rejection (409) | ❌ | Not implemented |

> [!WARNING]
> **Phase 6 is essentially unimplemented.** Basic subscription CRUD (plan names, amounts, durations) exists, but the *dynamic pricing rule engine* specified in the PRD is entirely absent.

---

## Phase 7: Super Admin Security Dashboard

| PRD Requirement | Status | Evidence |
|---|---|---|
| `security_incidents` table | ❌ | Not found in `models.py` |
| `device_blacklist` table | ❌ | Not found in `models.py` |
| Real-time incident feed (WebSocket) | ❌ | No WebSocket implementation |
| Account unlock endpoint (OTP-gated) | ❌ | No OTP system |
| Device fingerprint blacklist + enforcement | ❌ | Not implemented |
| Security KPI tiles | ⚠️ | Device KPI tiles exist in `GlobalDeviceConsole.jsx` but are not security-incident-aware |

---

## Phase 8: Foreign Guest Compliance (Form C / FRRO)

| PRD Requirement | Status | Evidence |
|---|---|---|
| `guest_nationality_documents` table | ❌ | Not in models.py |
| `form_c_records` table | ❌ | Not in models.py |
| `form_c_amendments` table | ❌ | Not in models.py |
| Nationality-branched registration UI | ❌ | Not implemented |
| Check-in gate for foreign nationals | ❌ | Not implemented |
| Form C auto-generation PDF on check-in | ❌ | Not implemented |
| Submission tracking (status + 24h deadline) | ❌ | Not implemented |
| Deadline alerting (6h + overdue escalation) | ❌ | Not implemented |
| Immutable-after-submission amendment pattern | ❌ | Not implemented |

> [!CAUTION]
> **Phase 8 is 0% implemented.** This is a legal compliance requirement for Indian hotels hosting foreign nationals.

---

## Phase 9: Dynamic Broker Commission Engine + Module 11 (Broker)

| PRD Requirement | Status | Evidence |
|---|---|---|
| `broker_commission_rules` table | ❌ | Not in models.py |
| `broker_wallets` table | ❌ | Not in models.py |
| `commission_transactions` table | ❌ | Not in models.py |
| `commission_payouts` table | ❌ | Not in models.py |
| Broker module: Dashboard, Leads, Bookings, Commission view | ❌ | No broker feature in Flutter app |
| Commission accrual on payment confirmation | ❌ | Not implemented |
| Disbursement modes (auto/manual) | ❌ | Not implemented |
| Reversal on cancellation/refund | ❌ | Not implemented |
| Owner/Super Admin commission rule-builder UI | ❌ | Not implemented |

> [!CAUTION]
> **Phase 9 is 0% implemented.**

---

## Phase 10: Remaining Staff Roles (App)

| Role | PRD Module | Status | Evidence |
|---|---|---|---|
| Manager | Module 5 | ❌ | No dedicated Manager dashboard, staff-task-assignment, or performance views. General `staff/` screens exist but are not Manager-role-specific. |
| Receptionist | Module 6 | ⚠️ | Booking CRUD, check-in/out execution all exist in Flutter and backend. Missing: OCR-based ID scan flow, dedicated Receptionist role dashboard. |
| Housekeeping | Module 7 | ⚠️ | `housekeeping_screen.dart` exists. Backend has tasks, lost-found, maintenance. Missing: property-issue→maintenance escalation UI, checklist completion flow. |
| Kitchen | Module 8 | ⚠️ | `kitchen_screen.dart` exists. Backend has task management. Missing: folio integration (F&B charges added to booking folio), order-to-billing lifecycle UI. |
| Accountant | Module 9 | ❌ | No accountant-specific module. `pl_report_screen.dart` and `gst-returns` backend API exist, but no transaction reconciliation, no accounting entries, no GST filing package. |
| Security Guard | Module 10 | ❌ | No visitor logging, no vehicle logging, no immutable incident reporting. Entirely missing. |

---

## Phase 11: Offline-First Hardening

| PRD Requirement | Status | Evidence |
|---|---|---|
| Offline mutation queue (push/pull sync) | ✅ | `sync_service.dart` in Flutter app; `POST /sync/push`, `GET /sync/pull` on backend |
| Idempotency-key deduplication | ⚠️ | Sync engine uses entity ID + `updated_at` LWW. No explicit `idempotency_key` header/field. |
| Conflict-resolution UX (human-in-the-loop) | ❌ | Sync service on backend reports conflicts in response, but no human-resolution screen in Flutter app |
| Offline-validity-window enforcement (read-only degradation) | ❌ | No offline validity window check (e.g., 72-hour read-only mode without connectivity) |
| APK size / cold-start / memory budget CI gate | ❌ | No CI configuration found |
| Sync retry/backoff (30s/2min/10min schedule) | ⚠️ | `sync_worker.dart` exists but backoff schedule implementation unclear |

---

## Phase 12: QA, Performance, Compliance

| PRD Requirement | Status | Evidence |
|---|---|---|
| RBAC matrix tests | ❌ | No test files found in `pinesphere_backend` or `pinesphere_stay` |
| Performance benchmarks (<500ms p95, <3s dashboard) | ❌ | No benchmarking or load testing found |
| Redis caching on hot paths | ❌ | Redis is connected but no caching decorators or cache-aside patterns found |
| PII encryption at rest | ❌ | Passwords are hashed; no field-level encryption for Aadhaar/PAN/passport data |
| TLS 1.3 / certificate pinning | ❌ | TLS is deployment-level; no cert pinning in Flutter app |
| MFA on Super Admin | ❌ | No MFA implementation |
| Audit log completeness sweep | ❌ | Only `auth/login` and `auth/logout` write audit logs. Booking create/cancel, payment, staff changes do NOT |
| Business rules regression suite (21 rules in §5) | ❌ | No test suite |

---

## Database Models: Present vs. PRD Required

### ✅ Models that Exist
`Owner`, `Business`, `Property`, `Role`, `Permission`, `RolePermission`, `User`, `UserPropertyAccess`, `Device`, `UserDevice`, `UserSession`, `StaffInvitation`, `CredentialResetRequest`, `UserSyncLog`, `RoomCategory`, `Room`, `Guest`, `Booking`, `CheckIn`, `CheckOut`, `InvoiceItem`, `AuditLog`, `RoomAssignment`, `HousekeepingTask`, `MaintenanceTicket`, `LostAndFound`, `Invoice`, `Payment`, `SubscriptionPlan`, `Subscription`, `SubscriptionTransaction`, `PaymentTransaction`, `PendingDue`, `SplitPayment`, `Task`, `TaskLog`, `Notification`, `DailyKPISnapshot`, `ReportTemplate`, `ScheduledReport`, `SystemConfiguration`, `PropertySetting`

### ❌ Models Required by PRD but Missing
| Model | PRD Section |
|---|---|
| `pricing_plans` (with rule engine fields) | §18.2 |
| `billing_cycle_options` | §18.2 |
| `pricing_rules` | §18.2 |
| `subscription_price_calculations` | §18.2 |
| `role_permission_overrides` | §0.2 |
| `security_incidents` | §20.5 |
| `device_blacklist` | §20.5 |
| `guest_nationality_documents` | §28.5 |
| `form_c_records` | §28.5 |
| `form_c_amendments` | §28.5 |
| `broker_commission_rules` | §29.2 |
| `broker_wallets` | §29.2 |
| `commission_transactions` | §29.2 |
| `commission_payouts` | §29.2 |
| `FolioLineItem` (referenced in code, not in models.py) | §24 |

---

## Backend API Coverage Summary

| Module | Router Exists | Fully Implemented | Notes |
|---|---|---|---|
| `auth` | ✅ | ⚠️ | Missing `/resolve`, OTP, lockout |
| `bookings` | ✅ | ✅ | Core CRUD + check-in/out |
| `checkin` | ✅ | ⚠️ | Basic flow, no reason-code gates |
| `checkout` | ✅ | ⚠️ | Basic flow, no override enforcement |
| `guests` | ✅ | ✅ | CRUD implemented |
| `housekeeping` | ✅ | ⚠️ | Tasks, maintenance, L&F — missing current_user bug in POST routes |
| `payments` | ✅ | ⚠️ | Super Admin subscription payments only. Guest payments return 501. |
| `properties` | ✅ | ✅ | Full CRUD + rooms + upload |
| `subscriptions` | ✅ | ✅ | Plan CRUD, status toggle, license generation |
| `devices` | ✅ | ✅ | Full lifecycle (register/approve/lock/revoke/sync) |
| `reports` | ✅ | ✅ | KPI, P&L, GST returns, templates, scheduled reports |
| `audit` | ✅ | ⚠️ | Infrastructure complete; not called from most mutating endpoints |
| `portal` | ✅ | ⚠️ | Auth + folio. Service/order endpoints are stubs. |
| `users` | ✅ | ⚠️ | Basic user management |
| `staff` | ✅ | ⚠️ | Staff CRUD |
| `settings` | ✅ | ⚠️ | System & property settings exist |
| `tasks` | ✅ | ✅ | Task lifecycle with logs |
| `notifications` | ✅ | ⚠️ | In-app only; WhatsApp not integrated |
| `sync` | ✅ | ⚠️ | Push/pull works; no idempotency keys |
| `dashboard` | ✅ | ✅ | KPI dashboard data |
| `pricing` | ⚠️ | ❌ | Module exists but contains only a rooms subdir; no pricing rules |
| `onboarding` | ⚠️ | ❌ | Module exists as an empty `__init__.py` |
| `amenities` | ⚠️ | ❌ | Module exists; no router found |
| `inventory` | ⚠️ | ❌ | Module exists; no router found |
| `documents` | ⚠️ | ❌ | Module exists; no router or models for Form C |
| Broker module | ❌ | ❌ | Not created |

---

## Overall Implementation Score

| Phase | Completion |
|---|---|
| Phase 0 — Foundation | ~60% |
| Phase 1 — Unified Login | ~40% |
| Phase 2 — Super Admin Web | ~70% |
| Phase 3 — Owner App | ~65% |
| Phase 4 — Guest Portal | ~45% |
| Phase 5 — Onboarding Pipeline | ~35% |
| Phase 6 — Pricing Rule Engine | ~5% (schema only, no logic) |
| Phase 7 — Security Dashboard | ~10% |
| Phase 8 — Form C / FRRO | **0%** |
| Phase 9 — Broker Commission | **0%** |
| Phase 10 — Staff Roles | ~30% |
| Phase 11 — Offline Hardening | ~35% |
| Phase 12 — QA / Compliance | **0%** |

---

## Top Priority Gaps to Address

1. **Audit log completeness** — Most mutating endpoints (booking create/cancel, payment, staff create/disable) do NOT write audit logs. This violates a core PRD mandate.
2. **Phase 8 (Form C/FRRO)** — Legal compliance requirement. 0% done.
3. **Phase 6 (Pricing Rule Engine)** — The dynamic pricing engine is entirely absent. Current subscription module is a flat plan list, not a rule engine.
4. **Single Active Session enforcement** — No heartbeat timeout or concurrent-session auto-lock. Security gap.
5. **Payment gateway (guest)** — The guest-facing payment endpoint returns `HTTP 501`. Guests cannot currently pay via the portal.
6. **Phase 9 (Broker Commission)** — 0% done. All 4 database tables missing.
7. **Event Bus** — No Redis Streams / RabbitMQ integration. All cross-module communication is synchronous in-process, violating the communication matrix in §4.
8. **OCR + ID verification** — The `ocr.py` module is a stub. No ID document extraction is functional.
