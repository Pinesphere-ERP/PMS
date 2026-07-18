# AGENT.md — Pinesphere Stay Engineering Agent Guide

This file instructs any AI coding agent (Claude Code, or equivalent) working in this repository. It is not the specification itself — the specification is `PRD.md` (Pinesphere_Stay_PRD.md). This file tells the agent **how to work against that spec** correctly and safely.

---

## 1. Source of Truth

- `PRD.md` is the single source of truth for behavior, business rules, data model, API contracts, and UI requirements. Section numbers in `PRD.md` (e.g. §2.6.3, §18.3) are stable references — cite them in commit messages, PR descriptions, and code comments where a non-obvious rule is implemented, so future readers can trace code back to spec.
- `TASK.md` is the current implementation backlog derived from `PRD.md`. Work top-to-bottom within a phase unless told otherwise; do not start a task whose dependencies (listed in `TASK.md`) are incomplete.
- If an instruction from a person conflicts with `PRD.md`, treat `PRD.md` as authoritative unless the person is explicitly amending it — in that case, update `PRD.md` first, then implement, so spec and code never diverge.
- If `PRD.md` is ambiguous or silent on a case, stop and ask rather than inventing a business rule — this system has many interlocking rules (RBAC, subscription gating, offline sync, dynamic pricing) where a locally-reasonable guess can silently violate a rule defined elsewhere in the document.

## 2. Tech Stack (do not substitute without explicit instruction)

| Layer | Technology |
|---|---|
| Backend | FastAPI (Python 3.11+) |
| Web Frontend | Flutter Web — Super Admin and Guest Portal only |
| App Frontend | Flutter (Android/iOS) — all other roles |
| App local data layer | ObjectBox (primary) + SQLite (relational mirror, sync-queue, audit shadow log), accessed through a **thin Kotlin platform-channel layer** |
| Server DB | PostgreSQL 15+ |
| Cache | Redis 7+ |
| Object Storage | MinIO / S3-compatible |
| Auth | JWT (15 min access / 7 day rotating refresh) |
| Event Backbone | Redis Streams / RabbitMQ |

## 3. Non-Negotiable Architectural Boundaries

These are structural rules, not style preferences. Violating them is a defect even if the immediate feature "works."

1. **No cross-module database access.** A service never queries another module's tables directly. All inter-module communication is REST, an event, a queue, or offline sync (PRD §4/§11). If a feature seems to need this, it needs a new API endpoint or event, not a shortcut join.
2. **Everything is permission-based, never hardcoded by role name.** Check `role_permissions` / the Permission Registry (PRD §0.2 and each module's §X.5), never `if role == "owner"`. Adding a new role or changing what a role can do must never require touching business-logic code.
3. **Kotlin is a data-access layer only** (PRD §15.2). It must never contain UI code, business validation, or workflow decisions. If you find yourself writing a business rule in Kotlin, move it to Dart (client-side check) and/or FastAPI (authoritative check) instead.
4. **Server is always the authority.** Every client-side check (Flutter validation, Kotlin sync logic) is a UX convenience; the FastAPI backend re-validates independently. Never trust a client-reported "success" (see PRD §3.6.5's payment-webhook rule as the canonical example).
5. **No hardcoded pricing, commission, or permission thresholds.** These come from the Dynamic Pricing Rule Engine (§18) and Dynamic Broker Commission Engine (§29) tables. If a number like "15%" or "₹100/room" appears as a literal in code outside a migration/seed script, that's a bug.
6. **Every mutating action produces an audit log entry.** No exceptions. If you add a new mutating endpoint, add its audit-log write in the same PR.
7. **Multi-property scoping is mandatory everywhere.** Every query against property-scoped tables must filter by `property_id` (Owner/staff JWT claim) or `booking_id` (Guest JWT claim) at the repository/query layer — never trust a client-supplied ID alone (PRD §2.9, §3.10, §27.9).

## 4. Module Map (for navigating PRD.md and the codebase)

| PRD Section | Module | Platform |
|---|---|---|
| §1 | Super Admin | Web |
| §2 | Owner | App |
| §3 | Guest Portal | Web |
| §13 | Unified Login & Platform Routing | Both |
| §14 | Subscription Paywall Enforcement | App (middleware) |
| §15 | Offline App Data Layer | App |
| §16 | License Anti-Theft Sync | App |
| §17 | Owner Registration & Property Onboarding | Both |
| §18 | Dynamic Subscription & Pricing Rule Engine | Backend (Super Admin UI) |
| §19 | App Integrity & Anti-Piracy | App |
| §20 | Super Admin Security Dashboard | Web |
| §21 | Manager | App |
| §22 | Receptionist | App |
| §23 | Housekeeping | App |
| §24 | Kitchen | App |
| §25 | Accountant | App |
| §26 | Security Guard | App |
| §27 | Broker | App |
| §28 | Foreign Guest Compliance (Form C/FRRO) | App/Backend |
| §29 | Dynamic Broker Commission Engine | Backend |

Mirror this structure in the repo: one FastAPI router/service package per module (`app/modules/booking`, `app/modules/pricing_engine`, etc.), one Flutter feature module per role.

## 5. Definition of Done (apply to every task)

- [ ] Behavior matches the cited PRD section, including its Business Rules and Edge Cases, not just the happy path.
- [ ] Every listed Validation Rule for touched fields is enforced server-side (client-side validation is additive, never a substitute).
- [ ] Every listed Acceptance Criteria checkbox for the feature is covered by an automated test.
- [ ] Permission checks use the Permission Registry, not a hardcoded role check.
- [ ] Audit log entry is written for any create/edit/delete/approve/override action.
- [ ] If the feature is App-facing and operational (not Super Admin/Guest-only), it works offline per §15 and is tested with connectivity toggled off mid-flow.
- [ ] If the feature touches money (payment, commission, subscription pricing), the calculation is traceable to a persisted record (`subscription_price_calculations`, `commission_transactions`, `payments`) — never a value computed and discarded.
- [ ] No new hardcoded role name, price, percentage, or duration was introduced outside a migration/seed/config.

## 6. Security & Compliance Reminders

- PII (mobile, email, ID documents, passport/visa data) is encrypted at rest and access-logged per view (§1.9, §3.10, §22.9, §28.6).
- Foreign-national guest check-in is blocked without complete passport/visa data (§28.2); Form C generation is automatic at check-in, never a manual trigger the agent should make optional.
- Session/license/integrity checks (§13.7, §16, §19) run on a schedule, not just at login — don't optimize them away as "redundant."
- Never implement a workaround that lets a role bypass the Web/App platform boundary (§0.3/§13) "for convenience" during development; use test accounts seeded on the correct platform instead.

## 7. When Extending the Spec

If a task requires a decision `PRD.md` doesn't cover, propose the addition as a PRD edit (new subsection, following the existing template: Purpose / Preconditions / Inputs / Outputs / Validations / Workflow / Business Rules / Notifications / Audit / Acceptance Criteria) before writing code against it. Keep `PRD.md`, `TASK.md`, and the codebase in sync — a spec that drifts from the code is worse than no spec.
