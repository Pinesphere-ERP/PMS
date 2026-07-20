# TRUST_TEST.md — Pinesphere Stay Trust, Isolation & Full-Feature Verification Flow

`FLOW.md` proves a single, clean, one-property happy path works end to end. **This document is different in purpose:** it exists to catch the failure mode that matters most in a multi-tenant hospitality platform — *a request, notification, payment, or piece of data reaching the wrong person, wrong account, wrong property, or wrong booking.* It is written as realistic human scenarios, not just API calls, and it deliberately builds a **multi-tenant world** (two Owners, four properties, overlapping/similar identities) because a single-tenant test world structurally cannot catch a cross-tenant leak — there is nothing else for data to leak *into*.

Feed this to the AI agent alongside `FLOW.md`. Where `FLOW.md` asks "does the feature work," this document asks **"does the feature only ever work for the right person, and never for anyone else, even when a real human makes a realistic mistake."** Output is not a pass/fail count — it is a **Trust & Reliability Report** (template at the end) classifying every finding by severity, because a misrouted payment notification is not the same class of bug as a mistyped button label.

---

## 0. Why This Matters More Than Functional Testing

In `FLOW.md`, every check was "did X happen." In this document, the more important checks are "did X happen **to the right target, and to no one else**." The highest-cost bugs in this system are not crashes — they are:

- A guest's OTP session returning *someone else's* booking.
- A commission credit landing in the wrong broker's wallet.
- A nightly WhatsApp summary with Property A's occupancy sent to Property B's Owner.
- A Housekeeping task from Property A1 visible/assignable to a staff member at Property A2.
- A Form C generated for the wrong guest, or omitted for the right one.
- A Security Guard at one property able to verify (and thus indirectly confirm the existence of) a guest at another property.

Every one of these is a silent, high-trust-damage failure — the system appears to work, and the person harmed may never find out. This document exists to force these into the open before real users do.

---

## 1. Test World Setup — Build a Real Multi-Tenant Environment First

Do not run any isolation test against a single-property world — build this full cast first, then run Sections 2–4 against it.

### 1.1 Customers / Owners (two entirely independent businesses)

| | Owner A | Owner B |
|---|---|---|
| Name | Rajesh Kumar | Priya Sharma |
| Business | Kumar Hospitality | Sharma Stays |
| Mobile | +91 98xxxxxx01 | +91 98xxxxxx02 |
| Properties | **A1** "Green Valley Cottage" (12 rooms), **A2** "Lakeside Retreat" (8 rooms) — both under Owner A, different physical locations | **B1** "Blue Ridge Resort" (20 rooms) |

### 1.2 Staff (deliberately not overlapping in name, so a leak is unambiguous when it happens)

| Property | Manager | Receptionist | Housekeeping | Kitchen | Accountant | Security Guard | Broker |
|---|---|---|---|---|---|---|---|
| A1 | Sunita Rao | Vikram Nair | Meena Iyer | Farhan Ali | Deepa Menon | Suresh Pillai | Ramesh Gupta (Broker X) |
| A2 | Anita Bose | Karan Malhotra | — (shares A1 pool? **No** — create a distinct staff member to test property-level, not just customer-level, isolation) Lata Joshi | — | — | — | Ramesh Gupta (Broker X, if the property config allows one broker across an Owner's properties — see Test T-08) |
| B1 | — | Ayesha Khan | Ritu Verma | — | — | — | Nisha Reddy (Broker Y) |

### 1.3 Guests (the identity-collision cases are intentional)

| Guest | Nationality | Property | Note |
|---|---|---|---|
| Guest 1 — "Arjun Mehta", +91 90xxxxxx11 | Indian | A1 | Baseline guest |
| Guest 2 — "John Whitfield" | Foreign (UK), Passport GB1234567 | A1 | Triggers Form C |
| Guest 3 — "Arjun Mehta", +91 90xxxxxx33 (**same name, different mobile, different everything else**) | Indian | B1 | Deliberately collides in name only with Guest 1, at a completely unrelated property/customer |
| Guest 4 — "Arjun Mehta" (**same name AND booked the same week**) | Indian | A2 | Same name as Guest 1/3, this time at Owner A's *other* property — tests property-level isolation within the same Owner |
| Guest 5 — "Aiko Tanaka" | Foreign (Japan) | B1 | Second foreign-guest/Form C instance, independent property, to confirm Form C isolation across customers |

### 1.4 Bookings

- Booking 1: Guest 1 @ A1, direct, Receptionist Vikram Nair.
- Booking 2: Guest 2 @ A1, direct, Receptionist Vikram Nair — foreign, Form C.
- Booking 3: Guest 3 @ B1, direct, Receptionist Ayesha Khan.
- Booking 4: Guest 4 @ A2, direct, Receptionist Karan Malhotra.
- Booking 5: Guest 5 @ B1, broker-sourced via Broker Y (Nisha Reddy) — foreign, Form C **and** commission, at a property with no connection to Broker X.
- Booking 6: A guest referred by Broker X (Ramesh Gupta) but who ends up booking **directly** at A1 without going through the broker flow (walk-in coincidence) — tests that commission is never accidentally attributed just because a broker happens to know the guest.

---

## 2. Full-Feature Coverage Matrix

Every feature in `PRD.md` must be exercised at least once across this document plus `FLOW.md`. Use this table as a coverage checklist — mark each row covered only once a test in Section 3 or `FLOW.md` has actually exercised it against the multi-tenant world above (not the single-tenant world), since several PRD business rules are only meaningfully testable with two+ tenants.

| PRD Section | Feature Area | Covered By |
|---|---|---|
| §1 | Super Admin (all sub-features) | T-01, T-02, T-13, T-14 |
| §2 | Owner (all sub-features) | T-03, T-05, T-06, T-09 |
| §3 | Guest Portal | T-04, T-07, T-15 |
| §4 | Cross-Module Communication | T-06, T-09, T-11, T-12 |
| §13 | Login & Platform Routing | T-01 |
| §13.7 | Session Lock | T-16 |
| §14 | Subscription Paywall | T-17 |
| §15 | Offline Data Layer | T-18 |
| §16 | License Anti-Theft | T-19 |
| §17 | Onboarding Pipeline | Setup (Section 1) |
| §18 | Dynamic Pricing | T-20 |
| §19 | App Integrity | T-19 |
| §20 | Security Dashboard | T-16, T-19 |
| §21 | Manager | T-05, T-08 |
| §22 | Receptionist | T-03, T-04, T-07 |
| §23 | Housekeeping | T-05, T-08 |
| §24 | Kitchen | T-05 |
| §25 | Accountant | T-13 |
| §26 | Security Guard | T-14 |
| §27 | Broker | T-11, T-12 |
| §28 | Form C / FRRO | T-09, T-10 |
| §29 | Broker Commission | T-11, T-12 |

If any row cannot be marked covered after running both documents, that is itself a finding — report it as a **Coverage Gap**, not a pass.

---

## 3. Trust & Isolation Test Suite

Each test states the **real human trigger** (what a person actually did) and the **trust assertion** (what must never happen as a result).

### Property-Level Isolation (same Owner, different property)

**T-01 — Cross-property login/routing sanity.** Manager Sunita Rao (A1) attempts to act on Property A2 by supplying A2's `property_id` in a request while authenticated with her A1-scoped token.
`GET $BASE/manager/properties/{A2_id}/dashboard` with Sunita's token → **must be 403/404, never 200.** (§2.9's `property_ids` JWT scoping, applied per-staff not just per-Owner)

**T-02 — Owner viewing "all properties" aggregate.** Owner A views the aggregate Dashboard. Confirm the combined figures are the sum of A1+A2 only — Owner B's B1 figures must never appear, even partially (e.g. in a global average miscalculation). Cross-check the raw per-property numbers against T-06's independently observed figures.

**T-03 — Booking created at A1 must never be visible/editable from A2's booking list.** Receptionist Karan Malhotra (A2) searches for Guest 4's overlapping-name counterpart, Guest 1 (booked at A1).
`GET $BASE/receptionist/bookings?search=Arjun+Mehta` with Karan's A2 token → must return **only Guest 4's A2 booking**, never Guest 1's A1 booking.

**T-04 — Guest 1 and Guest 4 (identical name, different property, overlapping stay) must never cross-resolve.** Both authenticate via OTP around the same time.
Verify Guest 1's session token, when used against any endpoint, always resolves to Booking 1/A1 — never Booking 4/A2 — and vice versa. Specifically test: does the OTP delivery for Guest 4 ever get sent to Guest 1's contact info, or vice versa, due to a name-based (rather than ID-based) lookup bug in the OTP service?

### Customer-Level Isolation (different Owners entirely)

**T-05 — Housekeeping task assignment cannot cross customers.** Manager Sunita Rao (Owner A, A1) attempts to assign a cleaning task to Ritu Verma (Owner B's B1 Housekeeping staff), e.g. via a staff-picker that wasn't properly filtered.
`POST $BASE/manager/tasks/{id}/assign {staff_id: ritu_verma_id}` → **must be 403/422**, and the staff-picker's underlying list endpoint must never have returned Ritu Verma to Sunita's client in the first place (defense in depth: server list-filtering, not just assignment-time rejection).

**T-06 — Nightly WhatsApp Summary must never cross Owners.** Trigger the nightly cron for both A1/A2 (Owner A) and B1 (Owner B) on the same simulated night.
Verify: Owner A's WhatsApp number receives exactly two messages (one per property, or one combined if configured), each containing **only that property's figures**; Owner B's number receives exactly one message with **only B1's figures**. Explicitly diff the message bodies to confirm zero figure cross-contamination (e.g. A1's occupancy number must never appear inside B1's message even by a template-variable bug).

**T-07 — Guest 1 (A1) and Guest 3 (B1) — identical name, unrelated customers.** Both request OTP within the same minute.
Verify OTP delivery, session scope, dashboard content, invoice, and feedback submission are fully independent — run the full Guest Portal flow (§3.6) for both simultaneously and diff every response field between the two sessions to confirm zero bleed.

**T-08 — Broker X (Owner A only) must never see or affect Owner B's properties.** Ramesh Gupta (Broker X) attempts a Booking Request against B1 (a property he has no relationship with).
`POST $BASE/broker/booking-requests {property_id: B1_id, ...}` with Broker X's token → must be 403, since Broker X's account is not associated with Property B1's Owner. Also verify Broker X's Dashboard/Leads/Commission views never enumerate or reference B1 in any way.

**T-09 — Form C isolation.** Guest 2 (foreign, A1) and Guest 5 (foreign, B1) both check in on the same day.
Verify each Form C record is scoped to its own `property_id`/`guest_id`; Super Admin's Global Compliance report (§28.4/§1.6.8) correctly attributes each to the right property, and Owner A's own compliance view never shows Guest 5's (B1's) Form C, nor vice versa for Owner B.

**T-10 — Form C submission responsibility routing.** Confirm the "approaching deadline"/"overdue" alerts for Guest 2's Form C go to **A1's** Manager+Owner (Sunita/Rajesh), never to B1's staff or Owner B, even though both Form C deadlines may be counting down in parallel.

### Broker Commission Trust (real money — highest scrutiny)

**T-11 — Commission must land in the correct broker's wallet, not a same-named or adjacent broker.** Run Booking 5 (Guest 5 @ B1, sourced from Broker Y/Nisha Reddy) and independently run a same-day payment on a Broker-X-sourced booking at A1.
After both payments confirm, verify: Broker Y's wallet increased by exactly her booking's commission and **not** Broker X's; Broker X's wallet increased by exactly his booking's commission and **not** Broker Y's. Pull both `commission_transactions` lists and confirm each entry's `booking_id` and `broker_id` are mutually exclusive between the two brokers.

**T-12 — Commission must never be attributed on a booking that wasn't actually broker-sourced (Booking 6).** Booking 6 is a guest who knows Broker X socially but booked directly (walk-in, `booking_source: direct`, no linked `booking_request`).
Verify Broker X's wallet is **unaffected** by Booking 6's payment — confirm no `commission_transactions` record was created for it under any broker_id. This directly tests §29.7 rule 2 ("a booking not sourced from a Broker never generates a commission transaction") against a realistic near-miss scenario, not just an obviously-unrelated booking.

### Account & Session Trust

**T-13 — Accountant at A1 must never see B1's financial data, even in aggregate reports.** Deepa Menon (A1 Accountant) runs a Profit & Loss report.
Verify the report contains only A1 transactions; specifically check the underlying query isn't accidentally aggregating across `property_id` due to a missing WHERE clause that would only manifest with real multi-property data (this class of bug is invisible in a single-property test world, which is why T-13 must run here, not in `FLOW.md`).

**T-14 — Security Guard verification must not leak cross-property guest existence.** Suresh Pillai (A1 Security Guard) queries the guest-verification endpoint for "Room 101" — a room number that happens to also exist at B1 (different property, coincidentally same room-numbering scheme).
`GET $BASE/guard/verify?room_number=101` with Suresh's A1-scoped token → must resolve **only against A1's Room 101**, never accidentally matching B1's Room 101 (a realistic collision given many properties number rooms 101, 102, ... independently).

**T-15 — Guest Portal must never allow booking-reference guessing to reach another guest's data.** Using Guest 1's real booking reference pattern, attempt a request against a structurally similar but incorrect reference belonging to Guest 3 or Guest 4.
Verify 401/404 with no information disclosure (no "closer" hint that the reference format was almost right) — consistent with §3.10's scope-locking rule, now tested against *plausible* adjacent references, not just obviously wrong ones.

**T-16 — Concurrent session lock must trigger on genuine misuse, and must NOT false-positive on legitimate multi-property Owner activity.** Owner A logs into the App on a phone to check A1, then, without logging out, opens the App on a tablet to check A2 within the heartbeat window.
This is a **single account, two devices, both actively used** — per §13.7 this should genuinely trigger a lock (the rule is per-account, not per-property), which is realistic and correct, but confirm the lock message clearly explains *why* rather than looking like a bug, and that Owner A can recover via the documented unlock flow (§20.3.2) without data loss on either property.

### Platform Integrity & Subscription Trust

**T-17 — Subscription lapse at A1 must never affect A2 or B1.** Force-suspend only A1's subscription.
Verify A2 (same Owner, different property, different subscription) remains fully functional, and B1 (different Owner entirely) is obviously unaffected. This directly tests that the paywall gate (§14) is subscription-scoped, not Owner-scoped or global.

**T-18 — Offline conflict resolution must never merge two different guests' data.** Simulate Karan Malhotra (A2) and Vikram Nair (A1) both offline-creating a guest record with the coincidentally identical name "Arjun Mehta" at the same time, then both reconnecting.
Verify sync produces **two distinct guest records**, correctly attributed to their respective properties/bookings — never a merged or duplicate-collapsed record just because the names matched (§8's conflict handling was specified for room/date exclusivity; this test extends the same rigor to guest-identity records, which have no natural uniqueness constraint on name alone).

**T-19 — A device registered to A1 must not function against A2 or B1, even under the same Owner account.** Take a device licensed/heartbeat-validated for A1, and attempt an operation scoped to A2.
Verify device-to-property binding is enforced independently of Owner-account identity — a device is not just "trusted because it's Owner A's," it is trusted only for the specific property it was registered against (confirm this against §1.6.6/§16's device model; if the current design licenses per-Owner rather than per-property, this test should surface that as a **design gap to flag**, not silently pass).

**T-20 — Dynamic pricing rule changes at A1 must never affect A2's or B1's quoted rates.** Super Admin (or Owner A, if property-level rule override is permitted) changes a pricing rule scoped to A1.
Verify a same-day quote for A2 and B1 is unaffected — pricing rules must resolve per `property_id`/`plan_id`, never leak across properties sharing the same Owner or Super Admin template.

---

## 4. Real-World Human Scenarios (Narrative)

These are written as a real front-desk/ops day would actually unfold, specifically to surface the "did this go to the right person" class of bug that a clean, linear test script tends to miss.

**Scenario S-1 — The Wrong-Number Slip.** Vikram Nair is registering Guest 1 and fat-fingers the mobile number, transposing two digits so it accidentally matches a number already on file for an unrelated past guest. Verify: does the system flag "this mobile is already associated with a different guest name" (a mismatch worth surfacing), or does it silently attach Guest 1's new booking to the old guest's history? Either way, verify the OTP for Guest 1's actual portal access goes to the number Vikram just typed — not to whoever the old number's real owner is — since an OTP misdelivery here is a real privacy incident, not just a data-quality one.

**Scenario S-2 — The Double-Booked Broker Guest.** Broker Y (Nisha Reddy) submits a Booking Request for Guest 5 at B1. Before Front Desk confirms it, the same guest also calls B1 directly and Receptionist Ayesha Khan — unaware of the pending broker request — creates a second, direct booking for the same dates. Verify: does the system detect the duplicate (same guest, same dates, two booking paths) and prevent double-charging/double-commission, or does it silently create two bookings, one of which incorrectly generates commission for Nisha on a guest who ultimately used the direct channel?

**Scenario S-3 — The Wrong Property in the Picker.** Owner A, managing both A1 and A2 from the same App session, is reviewing A2's maintenance tickets, then switches the property selector to A1 to check something else — but a background request initiated just before the switch (e.g. "Assign Technician") completes *after* the switch. Verify the in-flight request still resolves against A2 (the property it was created for), not A1 (the property now selected in the UI) — a classic stale-context race condition.

**Scenario S-4 — The Same-Day Room Turnover.** Guest 1 checks out of Room 5 at A1 at 11:00 AM. A new guest checks into Room 5 at 2:00 PM the same day. Verify the new guest's Guest Portal dashboard, service-request history, and invoice show zero trace of Guest 1's stay — no leftover pending requests, no old folio balance, no stale "assigned staff" from the prior guest's housekeeping task.

**Scenario S-5 — The Almost-Right Booking Reference.** A real guest, trying to help, reads their booking reference over the phone slightly wrong to a family member who then tries to log into the Guest Portal on the guest's behalf using the near-miss reference. Verify this fails cleanly (T-15) and, separately, that Front Desk has a legitimate assisted-access path (e.g. Receptionist looks up the guest and provides the correct reference) rather than the system tempting anyone toward an insecure workaround.

**Scenario S-6 — The Foreign Guest Who "Looks" Domestic.** A guest with an Indian-sounding name but a foreign passport (e.g. an NRI or dual national) checks in. Verify the Receptionist UI does not pre-assume nationality from name and correctly requires the passport/visa path once "Foreign National" is selected — and, just as important, verify an Indian national is never incorrectly pushed down the Form C path by an over-eager heuristic.

**Scenario S-7 — The Late-Night Owner Confusion.** Owner A receives Property A1's nightly WhatsApp summary at 10:00 PM and, ten minutes later, also expects A2's — but A2's summary is configured for 11:00 PM in Settings. Verify Owner A isn't left thinking A2's summary "didn't send" (a trust/communication issue even if technically correct) — confirm the message or in-app state makes each property's configured send time clear.

**Scenario S-8 — The Departing Guest's Lingering Access.** Guest 2 (foreign, A1) checks out. Thirty-one days later they attempt portal access (expected 410 per T-existing tests) — but also verify that in the 25th–30th day window, the "portal expiring soon" reminder (§3.12) is sent to Guest 2's actual contact, not to Guest 1 or Guest 4 despite all three having overlapping stay windows at different properties.

---

## 5. Trust & Reliability Report (produce this after running Sections 3–4)

Do not report simple pass/fail. Classify every finding:

```
PINESPHERE STAY — TRUST & RELIABILITY REPORT
Run date: <date>       Environment: <env/branch/commit>
Test world: 2 Owners / 4 Properties / 5 Guests / 2 Brokers / 12 Staff (Section 1)

SEVERITY DEFINITIONS
- CRITICAL: Data, money, or access crossed a tenant/property/person boundary that should be impermeable
            (e.g. commission to wrong broker, guest data leak, cross-property booking visibility).
- HIGH:     A boundary held under normal conditions but failed under a realistic edge case
            (e.g. name collision, race condition, near-miss reference).
- MEDIUM:   Correct behavior but confusing/untrustworthy from the human's perspective
            (e.g. S-7's timing confusion) — not a security issue, but a trust issue.
- LOW:      Cosmetic or minor inconsistency with no isolation/trust implication.

FINDINGS

| ID | Test/Scenario | Severity | What Happened | Expected (PRD §) | Root Cause | Fix Applied | Re-Test Result |
|----|----------------|----------|----------------|-------------------|------------|--------------|-----------------|
| ... | T-11 | CRITICAL | ... | §29.2 | ... | ... | ... |

COVERAGE SUMMARY
- Section 2 Feature Coverage Matrix: <X of 22 rows> confirmed covered.
- Any uncovered rows: list explicitly with reason (not yet testable / feature not yet built / deferred).

TRUST VERDICT
One paragraph, plain language: can this platform currently be trusted to keep every Owner's,
Guest's, and Broker's data and money strictly separate from every other tenant's, including
under realistic human error? State yes/no/conditionally, and list the CRITICAL findings (if any)
that must close before the answer can be "yes."
```
