# 7. Frontend Documentation (Super Admin Portal)

## Overview

The Super Admin Portal is a **React + Vite** single-page application used exclusively by the Pinesphere platform team to manage all properties, owners, subscriptions, devices, and users.

**Base path:** `web/admin/`  
**Dev server:** `npm run dev` (port 5173)  
**Entry:** `src/main.jsx` -> `src/App.jsx`

---

## Architecture

### fetchAPI — Universal API Client

**File:** `src/services/api.js`

All API calls go through `fetchAPI(endpoint, options)`:
- Reads `VITE_API_BASE_URL` env var (defaults to `http://localhost:8000/api/v1`)
- Injects `Authorization: Bearer <token>` from `localStorage.getItem('token')`
- Injects `X-Tenant-ID` if `options.tenantId` is provided
- Unwraps `StandardResponse` (returns `response.data` directly)
- On 401: clears `localStorage` and redirects to `/login`
- Throws an `Error` with the message from the API error response

---

### Route Protection

Two wrapper components in `App.jsx`:
- `ProtectedRoute` — redirects to `/login` if no token in localStorage
- `PublicRoute` — redirects to `/properties` if token already exists (prevents double login)

---

## Pages and Routes

### /login
**File:** `src/pages/Login.jsx`

**Purpose:** Authenticates the Super Admin user.

**Flow:**
1. User enters email + password.
2. `POST /auth/login` — receives `access_token`.
3. Stores token in `localStorage` as `token`.
4. Redirects to `/properties`.

---

### /properties — Property Dashboard
**File:** `src/pages/PropertyManagement/PropertyDashboard.jsx`

**Purpose:** Overview of all properties with statistics and quick actions.

**API Calls:**
- `GET /properties` — loads all properties
- `GET /users?scope=global` — loads user counts
- `GET /subscriptions` — loads subscription data

**Features:**
- Summary cards: Total Properties, Active Subscriptions, Pending Onboarding, Total Users
- Bar chart showing properties by type
- Property list table with filters (status, type, city)
- Quick action buttons: View, Add Room, Manage Users

---

### /properties/add — Add Property Wizard
**File:** `src/pages/PropertyManagement/AddPropertyWizard.jsx`

**Purpose:** 7-step wizard to create a new property end-to-end.

**Steps:**
1. **Basic Info** — property name, type, star category, year established, total floors, total rooms, description
2. **Contact** — WhatsApp number (for notifications)
3. **Location** — address, landmark, city, state, country, pincode, Google Maps URL, latitude, longitude
4. **Media** — property images upload
5. **Ownership** — owner name, mobile, email, PAN, designation
6. **Rooms** — define room categories with pricing, amenities, bed type, etc.
7. **Review & Submit** — preview all data and submit

**API Calls:**
- `POST /properties` — submits all form data at step 7
- `GET /owners` — (optional) to check if owner already exists

**State:** `useState` for `formData`, `rooms`, `currentStep`, `loading`, `error`

---

### /properties/:id — Property Details
**File:** `src/pages/PropertyManagement/PropertyDetails.jsx`

**Purpose:** Full detail view of a single property with tabbed navigation.

**Tabs:**
- **Overview** — basic info, owner, business details
- **Address** — map and address details
- **Rooms** — room list fetched from `/properties/{id}/rooms`
- **Images** — property gallery
- **Documents** — uploaded documents with verification status
- **Staff** — staff users for this property
- **Devices** — registered devices
- **Subscription** — subscription status
- **Verification** — verification checklist

**API Calls:**
- `GET /properties/{id}` — property data
- `GET /properties/{id}/rooms` — rooms tab
- `GET /users?property_id={id}` — staff tab
- `GET /devices?property_id={id}` — devices tab
- `GET /subscriptions?property_id={id}` — subscription tab

**Quick Action Links:**
- "View Rooms" -> `/properties/{id}/rooms`
- "Create User" -> `/properties/{id}/users/create`

---

### /properties/:id/rooms — Property Rooms
**File:** `src/pages/PropertyManagement/PropertyRooms.jsx`

**Purpose:** Dedicated rooms list page for a property.

**API Calls:**
- `GET /inventory/rooms?tenantId={id}` — loads rooms via tenant header
- `GET /properties/{id}` — loads property name for title

**Table Columns:** Room Number, Category, Status, Base Price

---

### /subscriptions/dashboard — Subscription Dashboard
**File:** `src/pages/SubscriptionManagement/SubscriptionDashboard.jsx`

**Purpose:** Overview of all subscriptions with revenue and expiry stats.

**API Calls:** `GET /subscriptions`, `GET /subscriptions/plans`

---

### /subscriptions/manage — Subscription Management
**File:** `src/pages/SubscriptionManagement/SubscriptionManagement.jsx`

**Purpose:** List and manage all property subscriptions.

**Features:** Table with Create, Edit, Suspend, and Renew actions.

---

### /subscriptions/plans — Subscription Plans
**File:** `src/pages/SubscriptionManagement/SubscriptionPlans.jsx`

**Purpose:** Manage available subscription plan tiers.

**API Calls:** `GET /subscriptions/plans`, `POST /subscriptions/plans`

---

### /subscriptions/payments — Payment Management
**File:** `src/pages/SubscriptionManagement/PaymentManagement.jsx`

**Purpose:** View all subscription payment transactions.

---

### /subscriptions/renewals — Renewal Management
**File:** `src/pages/SubscriptionManagement/RenewalManagement.jsx`

**Purpose:** View and manage upcoming and overdue subscription renewals.

---

### /devices/global — Global Device Console
**File:** `src/pages/DeviceManagement/GlobalDeviceConsole.jsx`

**Purpose:** View and manage all registered devices across all properties.

**API Calls:**
- `GET /devices/global` — all devices
- `PATCH /devices/{id}/approve` — approve device
- `PATCH /devices/{id}/revoke` — revoke device

**Table Columns:** Device Name, Property, Status, OS Type, Registered At, Actions

---

### /users — User Management
**File:** `src/pages/UserManagement/UserManagement.jsx`

**Purpose:** View and manage all users on the platform.

**API Calls:**
- `GET /users` — all users
- `GET /users?property_id={id}` — property-scoped users

**Features:**
- Filter by property, role, status
- Search by name/email/username
- Create User button -> Opens create user modal or navigates to create page

---

### /properties/:id/users/create — Create User For Property
**File:** `src/pages/UserManagement/CreateUserForProperty.jsx`

**Purpose:** Create a staff user for a specific property.

**Pre-filled:** `property_id` from the URL param.

**API Calls:**
- `GET /properties/{id}` — to display property name
- `GET /roles?property_id={id}` — to populate role dropdown
- `POST /users` — submit new user

**Validation:**
- `property_id` must be a valid UUID
- `role_id` must be a valid UUID
- Mobile and username must be unique

---

### /owners — Owner List
**File:** `src/pages/OwnerManagement/OwnerList.jsx`

**Purpose:** View all property owners on the platform.

**API Calls:** `GET /owners`

---

### /audit — Audit Logs
**File:** `src/pages/AuditManagement/AuditLogs.jsx`

**Purpose:** View tamper-evident audit trail for all operations.

**API Calls:** `GET /audit` with date/module/action filters

**Features:**
- Date range filter
- Module filter (bookings, checkin, checkout, users, etc.)
- Action type filter (CREATE, UPDATE, DELETE)
- Property filter (Super Admin view)

---

### /settings/system — System Settings
**File:** `src/pages/SystemManagement/SystemSettings.jsx`

**Purpose:** Manage global system configuration.

**Status:** Partially Implemented

---

## Shared Components

### DataTable
**File:** `src/components/ui/DataTable.jsx`

Reusable table component used on every list page.

**Props:**
- `columns` — array of `{ header, accessor, render, sortable }`
- `data` — array of data objects
- `loading` — shows skeleton/spinner
- `error` — shows error message
- `emptyStateMessage` — shows empty state
- `searchPlaceholder` — enables search input
- `pagination` — enables pagination controls

---

### AdminLayout
**File:** `src/layouts/AdminLayout.jsx`

Shell layout wrapping all authenticated pages with:
- Left sidebar with navigation links
- Top bar with user info and logout
- Main content area (renders child routes via `<Outlet />`)

---

## CSS Design System

**File:** `src/index.css`

Uses CSS custom properties (variables):
- `--color-pine` — brand green
- `--color-pine-dark` — darker variant
- `--color-surface` — card background
- `--color-border` — border color
- `--font-sans` — system font stack

Common utility classes:
- `.saas-input` — form input styling
- `.saas-button` — primary button
- `.saas-button-secondary` — secondary button
- `.saas-card` — card container
- `.animate-slide-in-right` — step animation in wizard

---

## State Management

No global state library is used. State is managed with:
- `useState` — local component state
- `useEffect` — side effects (API calls on mount/param change)
- `useParams` — URL parameters
- `useNavigate` — programmatic navigation
- `localStorage` — persists auth token only

---

## Frontend-to-Backend Data Flow Example (Create User)

```
User fills form on /properties/:id/users/create
  |
  v
CreateUserForProperty.jsx handleSubmit()
  |
  v
fetchAPI('/users', { method: 'POST', body: JSON.stringify(payload) })
  |-- Authorization: Bearer <token>
  |
  v
Backend POST /api/v1/users
  |--> get_current_user() validates JWT
  |--> require_super_admin() checks role
  |--> Validates property_id is a valid UUID
  |--> Creates User record in DB
  |--> Returns StandardResponse{ data: user }
  |
  v
fetchAPI unwraps response.data
  |
  v
Component shows success toast
  |
  v
Navigate to /users
```

---

## Cross-References

- API calls: [06-api-reference.md](./06-api-reference.md)
- Authentication: [09-auth-security.md](./09-auth-security.md)
- Property Onboarding: [13-onboarding.md](./13-onboarding.md)
