# 8. Mobile Application Documentation

## Overview

**Pinesphere Stay** mobile app is a **Flutter** application built for Android (primary), iOS, and Windows. It is the primary interface for hotel staff to perform day-to-day operations.

**Key design principle:** **Offline-first** — the app works without internet. All mutations are queued locally and synced when connectivity is restored.

**Entry point:** `lib/main.dart`

---

## Application Bootstrap

`main()` in `lib/main.dart`:
1. Initialize Flutter bindings.
2. Preserve native splash screen (`FlutterNativeSplash.preserve`).
3. Configure Google Fonts (suppress network errors when offline).
4. Initialize `DatabaseService` (opens ObjectBox store).
5. Run `PinesphereApp()` wrapped in `ProviderScope` (Riverpod).

The splash screen color is `#0d631b` (Pinesphere brand green).

---

## Navigation

**Router:** GoRouter (`go_router` package)

**File:** `lib/app/app.dart`

Routes include:
- `/splash` — boot screen (check auth, redirect)
- `/login` — authentication
- `/dashboard` — property dashboard
- `/bookings` — bookings list
- `/bookings/create` — create booking
- `/bookings/:id` — booking detail
- `/checkin/:booking_id` — check-in flow
- `/checkout/:booking_id` — check-out flow
- `/housekeeping` — housekeeping board
- `/rooms` — room directory
- `/guests` — guest directory
- `/payments` — payment entry
- `/reports` — reports
- `/settings` — app settings
- `/notifications` — notification feed
- `/tasks` — task management
- `/sync` — sync status panel

---

## Core Layer

### network/dio_client.dart

**Dio configuration:**
- Base URL: `https://pms-bvko.onrender.com/api/v1` (configurable via `API_URL` dart-define)
- Connect timeout: 90 seconds (to handle Render.com cold starts)
- Receive timeout: 90 seconds

**Interceptors (in order):**
1. `ApiInterceptor` — injects JWT + tenant headers
2. `OfflineOutboxInterceptor` — queues failed mutations to ObjectBox
3. `LogInterceptor` — logs all requests/responses (debug only)

**Fallback logic (OfflineOutboxInterceptor):**
- If the hosted backend (onrender.com) is unreachable, automatically retries against local server (`http://10.0.2.2:8000` on Android emulator or `http://localhost:8000` on other platforms).
- If still fails and it's a mutating request (POST/PUT/PATCH/DELETE), saves the operation to ObjectBox `SyncOperation` and returns a fake 202 response so the UI is not blocked.

### network/api_interceptor.dart

On every request, injects:
- `Authorization: Bearer <access_token>` — read from `flutter_secure_storage`
- `X-Tenant-ID: <tenant_id>` — property ID of logged-in user
- `X-Active-Property-Id: <active_property_id>` — for multi-property owners

On 401 response: **TODO — token refresh not implemented.** Currently falls through to error.

### network/connectivity_provider.dart

Uses `connectivity_plus` to monitor network status. Exposes a Riverpod provider that the app uses to show offline banners and enable/disable sync.

---

## State Management (Riverpod)

Every feature uses Riverpod:
- `@riverpod` annotation + `riverpod_generator` generates `.g.dart` files
- Providers are `ref.watch()`-ed in widgets
- `AsyncValue<T>` pattern for loading/data/error states

Key providers:
- `dioClientProvider` — singleton Dio instance
- `secureStorageProvider` — FlutterSecureStorage singleton
- `connectivityProvider` — internet status stream
- `tenantProvider` — reads active property ID

---

## Local Database (ObjectBox)

**Purpose:** Stores all data locally for offline-first operation.

**File:** `lib/objectbox-model.json` (schema)  
**Generated:** `lib/objectbox.g.dart` (291K lines — auto-generated, never edit)

**Models stored in ObjectBox:**
- Bookings, Rooms, RoomCategories, Guests, Payments, CheckIns, CheckOuts
- HousekeepingTasks, MaintenanceTickers
- Users, Roles, RolePermissions
- Tasks, TaskLogs
- SyncOperations (offline queue)

**DatabaseService** (`lib/core/database/database_service.dart`):
- Opens ObjectBox store
- Provides type-safe `Box<T>` accessors

---

## Features

### auth/ — Authentication

**Screens:**
- `LoginScreen` — email/username/mobile + password form
- `OtpScreen` — OTP verification
- `PinSetupScreen` — set 4-6 digit PIN for quick login
- `BiometricPromptScreen` — fingerprint/face ID

**Flow on first login:**
1. Enter credentials.
2. `POST /auth/login` — receive tokens.
3. Store `access_token`, `refresh_token`, `tenant_id` in `flutter_secure_storage`.
4. `GET /auth/offline-bootstrap` — download full user profile, permissions, and property data.
5. Store bootstrap data in ObjectBox.
6. Navigate to Dashboard.

**Subsequent logins (if still connected):**
1. PIN or biometric verification on device.
2. `POST /auth/pin-login` or `POST /auth/biometric-login`.
3. Receive new access token.

**Offline login:**
1. PIN or biometric verified locally against cached PIN hash.
2. App uses cached token (if not expired) or uses offline session.

---

### dashboard/ — Property Dashboard

**Screen:** `DashboardScreen`

**Displays:**
- Today's arrivals count
- Today's departures count
- Occupied / Vacant rooms
- Pending payments
- Revenue today
- Recent bookings list
- Quick action buttons (New Booking, Check-In, Housekeeping)

**API:** `GET /dashboard`

**Offline behavior:** Shows cached dashboard data from last sync.

---

### bookings/ — Booking Management

**Screens:**
- `BookingListScreen` — searchable/filterable list of bookings
- `BookingCreateScreen` — multi-step booking creation form
- `BookingDetailScreen` — full booking detail with guest info

**Create booking flow:**
1. Search/select existing guest or create new guest.
2. Select room (shows availability status).
3. Set check-in / check-out dates.
4. Set pricing (base rent, discount, taxes, deposit).
5. Review and confirm.
6. `POST /bookings`

**Offline:** New bookings created offline are queued in ObjectBox and synced when online.

---

### checkin/ — Check-In

**Screen:** `CheckInScreen`

**Flow:**
1. Scan or search booking by booking_reference.
2. Verify guest ID (checkbox).
3. Collect deposit amount.
4. `POST /checkin/{booking_id}`
5. Print check-in receipt (PDF, optional).
6. Sends WhatsApp welcome message (backend side).

---

### checkout/ — Check-Out

**Screen:** `CheckOutScreen`

**Flow:**
1. Search active check-in.
2. View current folio (room charges + F&B + extras + taxes).
3. Apply discounts if any.
4. Select payment mode.
5. `POST /checkout/{booking_id}`
6. Generate PDF invoice.
7. WhatsApp bill summary sent by backend.

---

### housekeeping/ — Housekeeping Board

**Screens:**
- `HousekeepingBoardScreen` — color-coded room grid (clean/dirty/cleaning/maintenance)
- `TaskDetailScreen` — task assignments and checklist

**Staff actions:**
- Mark room as "cleaning" (start)
- Update checklist items
- Mark room as "clean" (complete)
- Report maintenance issue

**API Calls:**
- `GET /housekeeping/rooms` — room status board
- `PATCH /housekeeping/rooms/{room_id}/status`
- `GET /housekeeping/tasks` — assigned tasks
- `PATCH /housekeeping/tasks/{task_id}` — update task

---

### kitchen/ — Kitchen / F&B

**Screen:** `KitchenOrderScreen`

**Purpose:** Kitchen staff views food orders linked to rooms.

**API:** `GET /kitchen/orders`

**Staff can:** Mark orders as "preparing", "ready", "delivered"

---

### guests/ — Guest Directory

**Screen:** `GuestDirectoryScreen`

**Features:** Search guests by name/mobile/email, view stay history.

**API:** `GET /bookings/guests?search=...`

---

### payments/ — Payment Entry

**Screen:** `PaymentEntryScreen`

**Features:**
- Link payment to a booking
- Select mode (cash, UPI, card, bank transfer)
- Enter amount and reference number
- Multi-mode split payments
- `POST /payments`

---

### notifications/ — Notification Feed

**Screen:** `NotificationFeedScreen`

**API:** `GET /notifications`

Displays unread count badge on app bottom navigation.

---

### tasks/ — Task Management

**Screens:** Task list, task detail, task creation.

**Cross-role:** Receptionists, managers, and housekeeping all interact with the task system.

**API:** `GET /tasks`, `POST /tasks`, `PATCH /tasks/{id}`

---

### sync/ — Sync Status

**Screen:** `SyncStatusScreen`

**Displays:**
- Last sync timestamp
- Pending operations count
- Sync now button (manual trigger)
- Failed operations list

**Background:** WorkManager job runs sync every 15 minutes when app is backgrounded.

---

### reports/ — Reports

**Screen:** `ReportsScreen`

**Features:**
- Occupancy report
- Revenue report by date range
- Export as PDF or Excel

**API:** `GET /reports/kpi`, `GET /reports/revenue`, `GET /reports/occupancy`

---

### settings/ — App Settings

**Screen:** `SettingsScreen`

**Options:**
- Change PIN
- Enable/disable biometrics
- Change active property (for multi-property users)
- Sync settings
- App version info
- Logout

---

## Security Model

- Access token stored in `flutter_secure_storage` (encrypted on device keychain).
- PIN hash verified locally (also stored in secure storage).
- Biometric auth uses device biometrics — actual credential is a device-level key.
- All API calls go over HTTPS.
- Device fingerprint (`device_uid`) embedded in JWT and verified by backend on each request.

---

## Offline-First Strategy

```
User Action (e.g., Create Booking)
        |
        v
Dio POST request
        |
        +--> Online? --> Request succeeds --> Update UI
        |
        +--> Offline? --> OfflineOutboxInterceptor catches error
                    |
                    v
                SyncOperation saved to ObjectBox
                (entityType, entityId, operation, payload, createdAt)
                    |
                    v
                Return fake 202 response to UI
                (UI thinks it worked)
                    |
                    v
                When connectivity restored:
                WorkManager triggers SyncEngine
                    |
                    v
                POST /sync/push (batches all pending SyncOperations)
                    |
                    v
                Backend merges records (conflict resolution by HLC timestamp)
                    |
                    v
                Remove synced operations from ObjectBox
```

**HLC (Hybrid Logical Clock):**
The `last_modified_hlc` field combines a physical timestamp with a logical counter to ensure strict ordering of updates even when device clocks drift.

---

## Background Processing

**WorkManager** (`workmanager` package) is used for background tasks:
- Sync engine runs every 15 minutes in background.
- Notification polling (if push not configured).

**Battery optimization:** WorkManager respects Doze mode and battery optimization. Sync may be delayed when device is on battery saver.

---

## Push Notifications

**Status: Partially Implemented**

The architecture supports FCM (Firebase Cloud Messaging) but the FCM token registration and server-side trigger are not yet connected. Currently, notifications are only delivered via:
- In-app polling (`GET /notifications`)
- WhatsApp messages (for guests)

---

## PDF Generation

Uses `pdf` Dart package to generate:
- Check-in receipt
- Check-out invoice
- Reports

PDFs are saved locally and can be opened with `open_filex` or shared.

---

## Cross-References

- Sync engine detail: [10-sync-engine.md](./10-sync-engine.md)
- Auth flow: [09-auth-security.md](./09-auth-security.md)
- API reference: [06-api-reference.md](./06-api-reference.md)
