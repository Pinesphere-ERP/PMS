# 12. Subscription and Paywall

## Overview

Pinesphere Stay requires a paid subscription for property-level operational features. The subscription system controls:
- Which operational modules are accessible (paywall gate)
- How many devices a property can register
- The billing cycle and expiry tracking

---

## Subscription Model

```python
class Subscription:
    id: UUID
    property_id: UUID       # One subscription per property
    plan: str               # "Free Trial", "Basic", "Pro", "Enterprise"
    billing_cycle: str      # "Monthly", "Annual"
    start_date: date
    expiry_date: date
    status: str             # "Active", "Expired", "Suspended"
    license_id: str         # Unique license code
    device_limit: int       # Max devices allowed (default 5)
    registered_devices: int # Current device count
    subscription_required: bool
```

---

## Paywall Gate

**File:** `app/core/subscription_gate.py`

**Applied to:** All property-level endpoints via `_paywall = [Depends(require_active_subscription)]` in `api.py`.

**Exempt routes (no paywall):**
- `/auth/*` — authentication
- `/properties/*` — property CRUD (needed to manage subscriptions)
- `/subscriptions/*` — subscription management itself
- `/devices/*` — device management
- `/payments/*` — payment processing
- `/portal/*` — guest portal

**Logic:**
```python
async def require_active_subscription(current_user, db):
    # Super Admin is ALWAYS exempt
    if role.role_code == "SUPER_ADMIN":
        return
    
    # Find active property subscription
    subscription = await db.get_subscription(property_id=active_property_id)
    
    # Auto-create Free Trial if no subscription exists
    if subscription is None:
        create_free_trial(property_id, expiry=today + 5 years)
        return
    
    # Check subscription status
    if subscription.status not in ("Active", "active"):
        raise HTTP 402 "Subscription is {status}"
    
    # Check expiry
    if subscription.expiry_date < today:
        raise HTTP 402 "Subscription expired on {date}"
```

**Free Trial:** When a property is created and has no subscription, the system auto-creates a 5-year Free Trial subscription. This gives new properties immediate access without manual subscription setup.

---

## Subscription Plans

Stored in `subscription_plans` table:

| Plan | Features | Amount | Duration |
|------|---------|--------|---------|
| Free Trial | All features | ₹0 | 5 years (auto-created) |
| Basic | Core PMS features | ₹X/month | Monthly |
| Pro | All features + advanced reports | ₹X/month | Monthly |
| Enterprise | All features + custom limits | ₹X/month | Annual |

**Plan features** are stored as a text field (`features`) in the `subscription_plans` table. The specific feature gating per plan is not yet implemented at the permission level — currently all plans give access to all features.

---

## Subscription Transactions

`subscription_transactions` table tracks all subscription payments:
```python
class SubscriptionTransaction:
    id: UUID
    payment_id: str      # Razorpay payment ID
    invoice_id: UUID     # FK to invoices
    property_id: UUID
    amount: float
    method: str          # e.g., "upi", "card"
    status: str          # "Processing", "Completed", "Failed"
    bank_ref: str
```

---

## Renewal Management

**Pending Dues** are tracked in `pending_dues`:
```python
class PendingDue:
    property_id: UUID
    plan: str
    due_date: date
    amount_due: float
    days_overdue: int
    reminder_status: str
```

**Renewal flow:**
1. Admin creates a new subscription or extends expiry via `PATCH /subscriptions/{id}`.
2. `PendingDue` record is cleared.
3. New `SubscriptionTransaction` is created.

---

## Admin Portal Subscription Management

### /subscriptions/dashboard
- Summary cards: Active, Expiring Soon, Expired, Total Revenue
- Chart: Subscriptions by plan type
- Table: All subscriptions with status and expiry

### /subscriptions/manage
- Full table of all subscriptions
- Actions: Create new, Extend, Suspend, Reactivate

### /subscriptions/plans
- CRUD for subscription plan definitions

### /subscriptions/payments
- All subscription payment transactions

### /subscriptions/renewals
- Properties with subscriptions expiring in next 30 days
- Properties with expired subscriptions
- Quick renew action

---

## Device Limit Enforcement

When a new device attempts to register:
1. `POST /devices/register` — backend checks `Subscription.registered_devices < device_limit`.
2. If at limit: `403 Forbidden, "Device limit reached for this subscription"`.
3. On successful device approval: `Subscription.registered_devices += 1`.
4. On device revocation: `Subscription.registered_devices -= 1`.

---

## Cross-References

- Subscription models: [04-database.md](./04-database.md)
- Device management: [15-device-management.md](./15-device-management.md)
- Payments: [05-backend.md](./05-backend.md)
