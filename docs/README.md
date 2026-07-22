# Pinesphere Stay — Complete Developer Knowledge Base

> **Version:** 1.0 | **Generated:** 2026-07-22 | **Stack:** FastAPI + React + Flutter

---

## Table of Contents

| # | Document | Description |
|---|----------|-------------|
| 1 | [Product Overview](./01-product-overview.md) | Business, roles, architecture summary |
| 2 | [System Architecture](./02-architecture.md) | Tech stack, components, communication |
| 3 | [Folder Structure](./03-folder-structure.md) | Every directory explained |
| 4 | [Database Documentation](./04-database.md) | All tables, relations, ER diagram |
| 5 | [Backend Documentation](./05-backend.md) | All modules, routers, services |
| 6 | [API Reference](./06-api-reference.md) | Every endpoint documented |
| 7 | [Frontend Documentation](./07-frontend.md) | All admin portal pages and components |
| 8 | [Mobile App Documentation](./08-mobile.md) | Flutter app — all screens and flows |
| 9 | [Authentication and Security](./09-auth-security.md) | JWT, sessions, RBAC, CORS |
| 10 | [Sync Engine](./10-sync-engine.md) | Offline-first sync architecture |
| 11 | [Notification System](./11-notifications.md) | WhatsApp, in-app, push |
| 12 | [Subscription and Paywall](./12-subscriptions.md) | Plans, billing, gate |
| 13 | [Property Onboarding](./13-onboarding.md) | Multi-step wizard, verification |
| 14 | [Booking Flow](./14-booking-flow.md) | Create, Check-in, Check-out |
| 15 | [Device Management](./15-device-management.md) | Registration, approval, binding |
| 16 | [User Management](./16-user-management.md) | Creation, roles, RBAC |
| 17 | [Deployment Guide](./17-deployment.md) | Render, env vars, migrations |
| 18 | [Developer Guide](./18-developer-guide.md) | Setup, run locally, contribute |

---

## Quick Navigation by Role

| Role | Where to Start |
|------|---------------|
| New Backend Developer | Architecture -> Backend -> API Reference -> Database |
| New Frontend Developer | Architecture -> Frontend -> API Reference |
| New Mobile Developer | Architecture -> Mobile -> Sync Engine |
| DevOps | Deployment -> Architecture -> Env Config |
| Product Manager | Product Overview -> Booking Flow -> Onboarding |
| QA Engineer | API Reference -> Booking Flow -> Auth and Security |

---

## Implementation Status

| Module | Status |
|--------|--------|
| Authentication (login/logout/OTP) | Implemented |
| Property CRUD | Implemented |
| Property Onboarding Wizard (7 steps) | Implemented |
| Room Management | Implemented (floor column requires migration on local SQLite) |
| Guest Management | Implemented |
| Booking Management | Implemented |
| Check-In / Check-Out | Implemented |
| Housekeeping and Maintenance | Implemented |
| Payments (guest-level) | Implemented |
| Subscriptions and Paywall | Implemented |
| Device Management | Implemented |
| Sync Engine (offline-first) | Implemented |
| Audit Logs | Implemented |
| Notifications (WhatsApp) | Implemented (requires WHATSAPP_* env vars) |
| Push Notifications | Partially Implemented (FCM not yet connected) |
| Reports and Analytics | Implemented |
| Security Module (incidents, cameras, watchlist) | Implemented |
| Broker Commission Engine | Implemented |
| Foreign Guest Compliance (Form C) | Implemented |
| Dynamic Pricing Rules | Implemented |
| Guest Portal | Implemented |
| Manager Operations | Implemented |
| Accountant Operations | Implemented |
| Token Refresh (mobile) | Not Implemented (TODO in ApiInterceptor) |
| Email Notifications | Not Implemented |
| SMS Notifications | Not Implemented |
| MinIO File Storage | Optional (falls back to local /uploads directory) |
| Redis Caching | Optional (disabled locally, no cache used in code paths yet) |
