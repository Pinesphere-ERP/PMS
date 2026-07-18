# TASK.md — Pinesphere Stay Implementation Backlog

Derived from `PRD.md`. Each task cites its governing PRD section(s) — read that section fully before starting the task. Work phases in order; within a phase, tasks may be parallelized across agents/engineers unless a dependency is noted.

Legend: `[ ]` not started · `[~]` in progress · `[x]` done · **(PRD §x)** = spec reference

---

## PHASE 0 — Foundation & Cross-Cutting Infrastructure

Everything else depends on this phase. Do not begin Phase 1+ feature work until Phase 0's core items are complete.

- [ ] Provision PostgreSQL 15+, Redis 7+, MinIO/S3-compatible storage, and set up the FastAPI project skeleton with `/api/v1/` versioning **(§0)**
- [ ] Implement the non-hardcoded RBAC engine: `permissions`, `role_permissions`, `role_permission_overrides` tables and the permission-check middleware **(§0.2)**
- [ ] Implement JWT issuance (15 min access / 7 day rotating refresh) and the base auth middleware **(§0)**
- [ ] Implement audit-log infrastructure: `audit_logs` polymorphic table, insert-only DB trigger enforcement, and a shared `write_audit_log()` helper used by every module **(§1.8, §1.10)**
- [ ] Implement multi-property scoping helper: mandatory `property_id`/`booking_id` filtering at the repository layer **(§2.9, §3.10, §27.9)**
- [ ] Set up the event backbone (Redis Streams/RabbitMQ) and the base publish/subscribe pattern used across the Communication Matrix **(§4)**
- [ ] Set up Flutter Web project (Super Admin + Guest Portal builds) and Flutter App project (all other roles), confirming the two builds ship different module sets **(§0.3)**
- [ ] Set up the Kotlin platform-channel scaffold + ObjectBox + SQLite integration, with the dependency-scope lint/check described in §15.8 wired into CI **(§15.2, §15.8)**
- [ ] Implement global error-handling conventions (400/401/403/404/409/422/429/500) as shared FastAPI exception handlers **(§7)**
- [ ] Implement global field-validation helpers (email, mobile/E.164, currency, booking reference, file upload constraints) **(§6)**

**Phase 0 exit criteria:** a "hello world" authenticated request round-trips through JWT auth → RBAC check → audit log write → Redis-cached response, on both Web and App builds.

---

## PHASE 1 — Module 4: Unified Login & Platform Routing

Must land before any role-specific login screen, since every login attempt passes through this first **(§13)**.

- [ ] `POST /api/v1/auth/resolve` — role resolution + platform routing matrix, credential verification deferred until after routing decision **(§13.2.1, §13.2.2)**
- [ ] App → Web redirect flow (signed, single-use, 5-min-expiry deep link) for Super Admin/Guest identifiers submitted on App **(§13.2.1)**
- [ ] Web → App refusal flow (with store badges) for operational-role identifiers submitted on Web **(§13.2.1)**
- [ ] `client_platform` header validation against build signature (reject tampered header, 400) **(§13.2.1)**
- [ ] Single Active Session Enforcement: `login_sessions` table, heartbeat-timeout logic, concurrent-violation detection and auto-lock **(§13.7)**
- [ ] Account unlock flow: OTP re-verification + Super Admin action, both required **(§13.7, §20.3.2)**
- [ ] Unit + integration tests for the full routing matrix (§13.2.2) — one test per role × platform combination

---

## PHASE 2 — Module 1: Super Admin (Web)

- [ ] Platform dashboard: materialized views + 60s Redis cache + KPI tiles **(§1.6.1)**
- [ ] Customer (Owner account) lifecycle: create/edit/suspend/activate/archive/delete/transfer-ownership **(§1.6.2)**
- [ ] Property lifecycle: create/approve/edit/allocate-limit/backup/restore, tied to Onboarding Pipeline (Phase 5) **(§1.6.3)**
- [ ] Subscription plan CRUD + assignment/upgrade/downgrade/renew/suspend workflow, tied to Pricing Engine (Phase 6) **(§1.6.4)**
- [ ] User management for Owner accounts (reset password, disable/activate, login history) **(§1.6.5)**
- [ ] Device management: register/approve/lock/disable/logout/transfer/remote-wipe, tied to License Anti-Theft (Phase 4) **(§1.6.6)**
- [ ] Support tooling: force sync, view logs (PII-masked), remote diagnostics **(§1.6.7)**
- [ ] Global reports (property/financial/device/subscription), async export for >10k rows **(§1.6.8)**
- [ ] Super Admin UI shell: nav, tables, drawers, dialogs, empty/loading/error states **(§1.7)**

---

## PHASE 3 — Module 2: Owner (App)

- [ ] Owner Dashboard (property-scoped KPIs, offline-capable rendering from local snapshot) **(§2.6.1)**
- [ ] Room Management: CRUD, pricing rules, amenities, photo upload, status state machine **(§2.6.2)**
- [ ] Booking Management: creation with distributed-lock + exclusion-constraint availability check, edit/cancel/confirm, offline conflict flagging **(§2.6.3)**
- [ ] Check-In/Check-Out with override + reason-code gating **(§2.6.4)**
- [ ] Payments: collect/refund-approve (segregation of duties)/generate invoice **(§2.6.5)**
- [ ] Staff Management: create/edit/disable within `staff_limit`, device assignment, token blacklist on disable **(§2.6.6)**
- [ ] Housekeeping/Kitchen/Maintenance oversight views **(§2.6.7)**
- [ ] Reports (daily/weekly/monthly/occupancy/revenue/staff/housekeeping/payment) **(§2.6.8)**
- [ ] Settings (business/WhatsApp/tax/notification/security) **(§2.6.9)**
- [ ] Nightly WhatsApp Business Summary cron job + retry/fallback **(§2.6.10)**

---

## PHASE 4 — Module 3: Guest Portal (Web) + License/Integrity Systems

- [ ] Guest OTP authentication (booking-scoped session, rate limits, lockout) **(§3.6.1)**
- [ ] Guest Dashboard / Booking Details / Room Details / Stay Duration **(§3.6.2–3.6.3)**
- [ ] Service Requests: Housekeeping/Food/Laundry/Extra Bed/Extra Towels/Maintenance/Luggage **(§3.6.4)**
- [ ] Payments: pay outstanding (server-side webhook-confirmed), download invoice **(§3.6.5)**
- [ ] Documents: ID upload + OCR + nationality branching → Form C trigger (Phase 8) **(§3.6.6, §28.2)**
- [ ] Feedback: housekeeping/food/stay ratings (upsert semantics), Google Review redirect **(§3.6.8)**
- [ ] Post-checkout 30-day access + hard expiry enforcement (server-side, overrides token's own `exp`) **(§3.6.9–3.6.10)**
- [ ] License Anti-Theft Continuous Sync: heartbeat endpoint, device-fingerprint mismatch handling, revocation propagation **(§16)**
- [ ] App Integrity & Anti-Piracy: signature pinning, Play Integrity/App Attest, certificate pinning, runtime self-check **(§19)**
- [ ] Subscription Paywall Enforcement middleware on every App mutating request **(§14)**

---

## PHASE 5 — Owner Registration & Property Onboarding Pipeline

Depends on Phase 2 (Super Admin) and Phase 3 (Owner) basics being in place.

- [ ] Self-service Owner registration flow (App) **(§17.2 Path A)**
- [ ] Admin-Assisted registration flow (Super Admin creates Customer + Owner) with mandatory `assistance_reason` **(§17.2 Path B)**
- [ ] Pipeline state machine: Draft → PendingApproval → Approved → SubscriptionAssigned → DeviceRegistered → LicenseGenerated → Active **(§17.3)**
- [ ] Fill Basic Details / Save Draft screens **(§17.4.3–17.4.4)**
- [ ] Approve Property gate (blocks all downstream steps until approved) **(§17.4.5)**
- [ ] Assign Subscription step wired to the Pricing Engine (Phase 6) — quote, payment confirmation, `room_limit` fixing **(§17.4.6)**
- [ ] Register Device + Generate License steps, both hard-blocked pre-`subscription.active` **(§17.4.7–17.4.8)**
- [ ] Activate Property — final unlock, tested against the Subscription Gate (§14) and License Sync (§16)

---

## PHASE 6 — Dynamic Subscription & Pricing Rule Engine

- [ ] `pricing_plans`, `billing_cycle_options`, `pricing_rules`, `subscription_price_calculations` schema **(§18.2)**
- [ ] Rule evaluation engine: condition matching, priority resolution, auto-revert logic **(§18.3)**
- [ ] Worked-example regression test: launch-phase weekend (+15%) vs. standard-phase weekend (+20%) vs. weekday (base) **(§18.3)**
- [ ] Room-based access determination: `room_limit` derived from confirmed payment at effective rate **(§18.5)**
- [ ] Super Admin rule-builder UI with live preview **(§18.6)**
- [ ] Quote API (`GET /pricing/plans/{id}/quote`) and rule-CRUD API **(§18.6)**
- [ ] Equal-priority rule conflict rejection (409) **(§18.7)**

---

## PHASE 7 — Super Admin Security Dashboard

Depends on Phase 1 (Session Enforcement) and Phase 4 (Integrity/License systems) emitting events.

- [ ] `security_incidents`, `device_blacklist` schema **(§20.5)**
- [ ] Real-time incident feed (WebSocket + polling fallback) subscribing to lock/integrity/mismatch events **(§20.3.1)**
- [ ] Account unlock endpoint (OTP-verification-gated) **(§20.3.2)**
- [ ] Device fingerprint blacklist endpoint + enforcement at integrity-check layer **(§20.3.3)**
- [ ] Security KPI tiles (locked accounts, integrity failures, mismatches, repeat offenders, time-to-unlock) **(§20.3.4)**

---

## PHASE 8 — Foreign Guest Compliance (Form C / FRRO)

Depends on Phase 3 (Owner/Booking) and Phase 4 (Guest Documents).

- [ ] `guest_nationality_documents`, `form_c_records`, `form_c_amendments` schema **(§28.5)**
- [ ] Nationality-branched registration UI + validation (Receptionist and Guest Portal upload paths) **(§28.2)**
- [ ] Check-in gate: block Foreign National check-in without complete verified passport/visa data **(§28.2)**
- [ ] Form C auto-generation on verified foreign-guest check-in (PDF render) **(§28.3)**
- [ ] Submission tracking (status: generated/submitted/submitted_late/overdue) + 24h deadline clock **(§28.3)**
- [ ] Deadline alerting: 6h-before + overdue escalation notifications **(§28.4)**
- [ ] Foreign Guest Compliance report (Owner + Super Admin Global Reports) **(§28.4)**
- [ ] Immutable-after-submission + amendment-record pattern **(§28.3)**

---

## PHASE 9 — Dynamic Broker Commission Engine + Module 11 (Broker)

Depends on Phase 3 (Payment Service) being complete.

- [ ] `broker_commission_rules`, `broker_wallets`, `commission_transactions`, `commission_payouts` schema **(§29.2)**
- [ ] Broker module: Dashboard, Leads, Booking Requests (non-locking), Commission view **(§27.6.1–27.6.4)**
- [ ] Real-time commission accrual triggered synchronously on payment confirmation **(§29.3)**
- [ ] Worked-example regression test: ₹1,000 payment × 10% rule → ₹100 wallet credit, same transaction cycle **(§29.3)**
- [ ] Disbursement modes: immediate auto-payout, scheduled auto-payout, manual payout **(§29.4)**
- [ ] Reversal on cancellation/refund, including negative-balance offset handling **(§29.5)**
- [ ] Owner/Super Admin commission rule-builder UI + API **(§29.6)**

---

## PHASE 10 — Remaining Staff Roles (App)

Can be parallelized once Phase 0, 1, 3 are done — each is largely independent of the others.

- [ ] **Module 5 — Manager**: dashboard, staff task assignment/attendance/performance, booking view/modify/confirm, maintenance ticket lifecycle, reports **(§21)**
- [ ] **Module 6 — Receptionist**: dashboard, guest registration/OCR/nationality branching, booking CRUD, check-in/out execution, payment collection **(§22)**
- [ ] **Module 7 — Housekeeping**: dashboard, cleaning task lifecycle, guest-request fulfillment, property-issue → maintenance escalation, lost & found **(§23)**
- [ ] **Module 8 — Kitchen**: dashboard, order lifecycle with folio integration, billing view **(§24)**
- [ ] **Module 9 — Accountant**: dashboard, transaction reconciliation, accounting entries, GST reports/filing package, financial reports, invoicing **(§25)**
- [ ] **Module 10 — Security Guard**: dashboard, visitor entry/exit/verify (PII-minimized), vehicle logging, incident reporting (immutable) **(§26)**

---

## PHASE 11 — Offline-First Hardening (App-Wide, Cross-Cutting)

Run against every operational module built in Phases 3, 5, 9, 10.

- [ ] Offline mutation queue + idempotency-key dedup end-to-end test per module (booking, payment, housekeeping, kitchen, maintenance) **(§8, §15.3)**
- [ ] Conflict-resolution UX: server-authoritative rejection surfaced as a human-in-the-loop resolution screen, never silent auto-merge on room/date exclusivity **(§8)**
- [ ] Offline-validity-window enforcement (read-only degradation without connectivity) **(§15.4)**
- [ ] APK size / cold-start / memory budget CI gate **(§15.8)**
- [ ] Sync retry/backoff schedule verification (30s / 2min / 10min) **(§8)**

---

## PHASE 12 — QA, Performance, and Compliance Sign-Off

- [ ] Full RBAC matrix test: every role × every permission it should NOT have, verifying 403 **(§0.2, all module §X.5 sections)**
- [ ] Performance benchmarks against §10 targets (API <500ms p95, dashboard <3s, search <1s)
- [ ] Security review: PII encryption at rest, TLS 1.3, certificate pinning, MFA on Super Admin **(§1.9, §3.10, §19)**
- [ ] Audit-log completeness sweep: every mutating endpoint has a corresponding audit write
- [ ] Global Business Rules regression suite — one test per rule in §5 (all 21 rules)
- [ ] Cross-module communication contract tests against the full Matrix in §4
- [ ] Accessibility/empty-state/loading-state/error-state UI review across all module UIs (§1.7, §2.7, §3.7, and each staff module's §X.7)

---

## Backlog Hygiene

- Update this file's checkboxes as work lands; do not let it drift from actual repo state.
- If a task is split into sub-tasks during implementation, nest them under the parent bullet rather than creating untracked ad-hoc work.
- Any new task discovered that isn't traceable to a `PRD.md` section should trigger a PRD update first (see `AGENT.md` §7) before being added here.
