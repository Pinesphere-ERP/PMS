# 3. Folder Structure

## Root (PMS/)

```
PMS/
├── pinesphere_backend/   Backend (Python / FastAPI)
├── pinesphere_stay/      Mobile app (Flutter / Dart)
├── web/                  Web applications
│   ├── admin/            Super Admin Portal (React + Vite)
│   └── guest-portal/     Guest-facing portal (React + Vite)
├── docs/                 This knowledge base
├── render.yaml           Render.com deployment config
├── .gitignore
└── package.json          Root workspace (minimal)
```

---

## Backend: pinesphere_backend/

```
pinesphere_backend/
├── app/
│   ├── main.py           FastAPI app: lifespan, CORS, rate limiting, error handlers
│   ├── api.py            Central router: imports all module routers, applies paywall
│   ├── core/
│   │   ├── config.py     Pydantic settings (reads from .env)
│   │   ├── dependencies.py  Auth deps: get_current_user, require_super_admin, RBAC
│   │   ├── security.py   JWT creation/decoding, bcrypt hashing
│   │   ├── responses.py  StandardResponse model + helpers
│   │   ├── notifications.py  WhatsAppService class
│   │   ├── subscription_gate.py  require_active_subscription FastAPI dep
│   │   ├── limiter.py    SlowAPI limiter instance
│   │   └── ocr.py        OCR API helper for document scanning
│   ├── infra/
│   │   ├── database.py   Engine, session factory, Base, TimestampMixin, SyncMixin, get_db
│   │   └── models.py     ALL SQLAlchemy ORM models (1108 lines, 40+ tables)
│   └── modules/          One directory per business domain:
│       ├── auth/         Login, OTP, refresh, logout, offline bootstrap
│       ├── properties/   Property + rooms + categories + images + docs + amenities
│       ├── bookings/     Guest creation + booking CRUD + availability check
│       ├── checkin/      Check-in workflow + ID verification
│       ├── checkout/     Check-out + folio calculation + invoice generation
│       ├── housekeeping/ HK tasks + maintenance tickets + room status + lost & found
│       ├── kitchen/      F&B orders
│       ├── payments/     Payments + Razorpay integration + split payments
│       ├── subscriptions/ Subscription plans + subscription CRUD
│       ├── devices/      Device register/approve/list
│       ├── users/        User CRUD (for Super Admin)
│       ├── staff/        Staff management + invitations + credential reset
│       ├── owners/       Owner listing
│       ├── portal/       Guest portal auth (booking_reference + OTP)
│       ├── notifications/ In-app notification CRUD
│       ├── audit/        Audit log + immutable entry service
│       ├── reports/      KPI snapshots, scheduled reports
│       ├── settings/     SystemConfiguration + PropertySetting
│       ├── sync/         Offline sync push/pull (used by mobile)
│       ├── onboarding/   7-step property onboarding wizard
│       ├── inventory/    Room inventory
│       ├── pricing/      Dynamic pricing rules
│       ├── documents/    Form C / FRRO foreign guest compliance
│       ├── broker/       Commission rules, wallets, transactions, payouts
│       ├── security/     Security incidents, cameras, watchlist, blacklisted devices
│       ├── security_guard/ Visitor logs, vehicle logs, property incident reports
│       ├── manager/      Manager-level aggregated views
│       ├── accountant/   Accountant financial views
│       ├── dashboard/    Dashboard KPI endpoint
│       ├── tasks/        Shared task management
│       ├── guests/       Guest module (CRUD separate from bookings module)
│       ├── amenities/    Amenity catalog
│       └── service_requests/ Guest-initiated service requests
├── alembic/              Database migrations
│   ├── env.py
│   ├── versions/         Individual migration scripts
│   └── README
├── alembic.ini           Alembic configuration
├── .env                  Environment variables (never commit)
├── .env.example          Template for env vars
├── requirements.txt      Python dependencies
├── render.yaml           Render.com deployment config (at project root)
├── docker-compose.yml    Local Docker setup (PostgreSQL + Redis + MinIO)
├── pinesphere.db         SQLite dev database (local only)
├── run_local.sh          Script to start uvicorn locally
├── seed_admin.py         Script to seed initial Super Admin user
├── init_db.py            Script to initialize DB tables
└── uploads/              Local file uploads directory (served as /api/v1/uploads)
```

**Module Pattern** — every module follows the same structure:
```
module_name/
├── __init__.py     Exports router
├── router.py       FastAPI router with all endpoints
├── schemas.py      Pydantic request/response schemas
└── service.py      Business logic functions (called by router)
```

---

## Frontend: web/admin/

```
web/admin/
├── src/
│   ├── main.jsx          React entry point
│   ├── App.jsx           Route definitions (BrowserRouter, ProtectedRoute)
│   ├── App.css           Global app styles
│   ├── index.css         CSS design tokens, utility classes
│   ├── assets/           Static images and logos
│   ├── components/
│   │   └── ui/
│   │       └── DataTable.jsx   Reusable data table (pagination, search, sort)
│   ├── layouts/
│   │   └── AdminLayout.jsx     Sidebar + top bar shell for all authenticated pages
│   ├── services/
│   │   ├── api.js              fetchAPI() - universal HTTP client wrapper
│   │   ├── deviceService.js    Device-specific API calls
│   │   ├── ownerService.js     Owner-specific API calls
│   │   ├── paymentService.js   Payment API calls
│   │   ├── propertyService.js  Property-specific API calls
│   │   └── subscriptionService.js  Subscription API calls
│   └── pages/
│       ├── Login.jsx
│       ├── PropertyManagement/
│       │   ├── PropertyDashboard.jsx    List of all properties + stats
│       │   ├── AddPropertyWizard.jsx    7-step property creation wizard
│       │   ├── PropertyDetails.jsx      Full property detail + tabbed view
│       │   ├── PropertyRooms.jsx        Rooms list for a property
│       │   └── AllProperties.jsx        Alternative flat list view
│       ├── SubscriptionManagement/
│       │   ├── SubscriptionDashboard.jsx
│       │   ├── SubscriptionManagement.jsx
│       │   ├── SubscriptionPlans.jsx
│       │   ├── PaymentManagement.jsx
│       │   └── RenewalManagement.jsx
│       ├── DeviceManagement/
│       │   ├── GlobalDeviceConsole.jsx  Admin view of all devices
│       │   ├── MyDevicesPanel.jsx       Owner's devices
│       │   └── DeviceDiagnosticsPanel.jsx  Support diagnostics
│       ├── UserManagement/
│       │   ├── UserManagement.jsx       Super admin user list
│       │   └── CreateUserForProperty.jsx  Create staff user for a property
│       ├── OwnerManagement/
│       │   └── OwnerList.jsx
│       ├── AuditManagement/
│       │   └── AuditLogs.jsx
│       ├── SystemManagement/
│       │   └── SystemSettings.jsx
│       ├── Reports/                     (Placeholder)
│       ├── Security/                    (Placeholder)
│       ├── Settings/                    (Placeholder)
│       ├── Support/                     (Placeholder)
│       ├── Dashboard/                   (Placeholder)
│       ├── CustomerManagement/          (Placeholder)
│       ├── LicenseManagement/           (Placeholder)
│       └── Onboarding/                  (Placeholder)
└── package.json
```

---

## Mobile: pinesphere_stay/

```
pinesphere_stay/lib/
├── main.dart                 Entry point: initializes ObjectBox, wraps in ProviderScope
├── app/
│   └── app.dart              MaterialApp with GoRouter, theme, splash removal
├── core/
│   ├── auth/                 JWT storage, session management
│   ├── database/
│   │   └── database_service.dart  ObjectBox init, store access
│   ├── error/                Error types, Either wrappers
│   ├── files/                File handling utilities
│   ├── network/
│   │   ├── dio_client.dart   Dio setup, OfflineOutboxInterceptor, base URL
│   │   ├── api_interceptor.dart  Injects JWT + tenant headers on every request
│   │   ├── connectivity_provider.dart  Monitors internet status (connectivity_plus)
│   │   └── tenant_provider.dart  Reads active property ID from secure storage
│   ├── permissions/          Device permission wrappers (camera, storage)
│   ├── presentation/         Base state classes
│   ├── security/             Encryption utilities
│   ├── storage/              Key-value secure storage helpers
│   ├── sync/
│   │   ├── engine/           Sync orchestrator (pulls, pushes)
│   │   └── queue/
│   │       └── sync_operation.dart  ObjectBox model for pending offline ops
│   ├── theme/                App colors, typography, theme data
│   ├── utils/                Date formatters, string helpers
│   └── widgets/              Shared UI widgets
├── features/
│   ├── auth/                 Login screen, OTP, PIN, biometric
│   ├── bookings/             Booking list, create, detail
│   ├── checkin/              Check-in workflow
│   ├── checkout/             Check-out, payment, invoice
│   ├── dashboard/            Property dashboard KPIs
│   ├── guests/               Guest directory
│   ├── housekeeping/         Room status board, task management
│   ├── kitchen/              F&B orders
│   ├── notifications/        In-app notification feed
│   ├── payments/             Payment recording
│   ├── portal/               Guest portal features
│   ├── property_onboarding/  Property setup wizard
│   ├── reports/              Report generation
│   ├── requests/             Service request management
│   ├── rooms/                Room directory
│   ├── settings/             App settings
│   ├── splash/               Splash screen and boot flow
│   ├── staff/                Staff management
│   ├── subscription_management/ Subscription status view
│   ├── sync/                 Sync status and control UI
│   ├── tasks/                Task management
│   ├── user_role_management/ User and role management
│   ├── audit/                Audit log viewer
│   ├── accountant/           Accountant views
│   ├── manager/              Manager views
│   ├── device_management/    Device management
│   └── payments/             Payment module
├── objectbox-model.json      ObjectBox schema
└── objectbox.g.dart          ObjectBox generated bindings (291K lines)
```

**Feature Structure Pattern** (Clean Architecture per feature):
```
feature_name/
├── data/
│   ├── models/       Data models (JSON-serializable, ObjectBox annotated)
│   ├── datasources/  Remote datasource (API calls via Dio)
│   └── repositories/ Repository implementations
├── domain/
│   ├── entities/     Pure business objects
│   └── repositories/ Abstract repository interfaces
└── presentation/
    ├── screens/      Flutter screen widgets
    ├── widgets/      Feature-specific widgets
    └── providers/    Riverpod providers (state management)
```

---

## Cross-References

- Backend modules detail: [05-backend.md](./05-backend.md)
- Frontend pages detail: [07-frontend.md](./07-frontend.md)
- Mobile app screens: [08-mobile.md](./08-mobile.md)
