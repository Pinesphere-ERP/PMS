# 1. Product Overview

## What is Pinesphere Stay?

**Pinesphere Stay** is an **offline-first, multi-tenant Property Management System (PMS)** built for hotels, resorts, homestays, and guesthouses. The platform digitizes every operational workflow of a hospitality property — from guest booking, check-in, and check-out to housekeeping, payments, reporting, and compliance.

The defining differentiator of Pinesphere Stay is its **offline-first architecture**: the mobile application continues to function without internet connectivity and automatically synchronizes data with the cloud when connectivity is restored.

---

## Business Problem It Solves

Traditional PMS products require continuous internet access, making them unusable in areas with poor connectivity (hill stations, remote resorts, etc.). They also tend to be expensive, server-heavy, and complex to operate.

Pinesphere Stay solves:
1. **Connectivity Dependency**: Works fully offline via local ObjectBox database on the device.
2. **Complexity**: Provides role-based screens so each staff member only sees what is relevant to their job.
3. **Compliance**: Built-in Form C for foreign guest compliance, audit trails, and GST tracking.
4. **Multi-property Management**: One owner can manage multiple properties from a single account.
5. **Real-time collaboration**: All staff at the same property sync their actions through the cloud.

---

## Target Users

| User | Description |
|------|-------------|
| Super Admin | Platform operator (Pinesphere team). Manages all properties, subscriptions, devices, and users across the entire system. |
| Owner | Hotel or property owner. Manages their own properties, views reports, and manages staff. |
| Property Manager | Day-to-day operations. Can perform all front desk actions. |
| Receptionist | Handles booking, check-in, and check-out. |
| Housekeeping Staff | Views assigned rooms and updates cleaning status. |
| Kitchen Staff | Views food/F&B orders linked to rooms. |
| Accountant | Views financial reports, payments, and invoices. |
| Security Guard | Logs visitors, vehicles, and property incidents. |
| Broker | Refers guests for bookings and earns commission. |
| Guest | Accesses the guest portal to view their booking, request services, and track their bill. |

---

## User Roles (Role Codes)

Defined in the `roles` table in the database. Each role has a `role_code` used for programmatic checks.

| role_code | Description |
|-----------|-------------|
| SUPER_ADMIN | Platform-level admin (bypasses all property-level restrictions) |
| OWNER | Property owner (can access all their properties) |
| PROPERTY_MANAGER | Senior staff with full operational access |
| RECEPTIONIST | Front desk operations |
| HOUSEKEEPING | Room cleaning and status updates |
| KITCHEN | F&B order tracking |
| ACCOUNTANT | Financial view and reporting |
| SECURITY_GUARD | Visitor and vehicle log management |
| BROKER | Commission-based referral |
| GUEST | Read-only portal access for their own booking |

---

## Overall System Workflow

```
[Guest Arrives]
      |
      v
[Receptionist creates Booking]
      |
      v
[Guest Check-In] --> Room assigned, WhatsApp welcome sent, Guest Portal activated
      |
      v
[During Stay]
  - Guest requests service via Guest Portal
  - Staff receives Task notification
  - Housekeeping updates room status
  - Kitchen logs F&B orders
  - Security logs visitors
      |
      v
[Guest Check-Out]
  - Folio computed (room + F&B + extras + taxes)
  - Payment collected (multi-mode: cash, UPI, card)
  - Invoice generated
  - WhatsApp bill summary sent
      |
      v
[Reports] --> Manager/Owner/Accountant views daily KPIs, revenue, occupancy
```

---

## Multi-Tenant Architecture

Pinesphere Stay uses a **hybrid multi-tenancy model**:

- **Platform Level** (`public` schema): Owners, Properties, Subscriptions, Devices, Users, Roles.
- **Property Level** (per-request `search_path`): All operational data (Bookings, Rooms, Guests, Payments) is logically isolated per property using `property_id` foreign keys on every table.
- On PostgreSQL (production), the system uses `SET search_path TO property_{id}, public` on each database connection, routing tenant queries to a property-specific schema.
- On SQLite (development), schemas are not supported, so all data is in a single `pinesphere.db` file, isolated purely by `property_id` column values.

**Why this approach?**
- Schema-per-tenant provides strong isolation guarantees.
- Avoids the complexity of separate database servers per tenant.
- Allows cross-tenant queries at the `public` schema level (e.g., Super Admin views all properties).

---

## Property Architecture

Each property is an independent operational unit:

```
Owner
  └── Business (GST entity)
        └── Property (Hotel/Resort)
              ├── Address
              ├── Images
              ├── Documents (legal)
              ├── Bank Account
              ├── Verification Status
              ├── Amenities
              ├── Room Categories
              │     └── Rooms (individual units)
              ├── Staff Users
              ├── Devices (tablets/phones)
              ├── Subscription
              └── All operational data (Bookings, Payments, etc.)
```

---

## High-Level User Hierarchy

```
Pinesphere Platform (Super Admin)
  |
  └── Owner (manages 1..N properties)
        |
        └── Property
              |
              ├── Property Manager
              ├── Receptionists
              ├── Housekeeping
              ├── Kitchen
              ├── Accountant
              ├── Security Guard
              └── Brokers
```

---

## Cross-References

- Architecture: [02-architecture.md](./02-architecture.md)
- Roles and Permissions: [09-auth-security.md](./09-auth-security.md)
- Property Onboarding: [13-onboarding.md](./13-onboarding.md)
- Booking Flow: [14-booking-flow.md](./14-booking-flow.md)
