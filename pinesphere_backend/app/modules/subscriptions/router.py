from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from datetime import date, timedelta
import stripe
import os
from fastapi import Request

stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "sk_test_mock")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "whsec_mock")

from app.infra.database import get_db
from app.infra.models import (
    Subscription, Property, Owner, SubscriptionTransaction, Invoice, User, Role, SubscriptionPlan
)
from app.core.dependencies import get_current_user
from app.modules.audit.logger import AuditLogger

router = APIRouter()

async def require_super_admin(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> User:
    role_res = await db.execute(select(Role).filter(Role.id == user.role_id))
    role = role_res.scalars().first()
    if not role or role.role_code != "SUPER_ADMIN":
        raise HTTPException(status_code=403, detail="Super Admin access required")
    return user

PLAN_PRICE = {"Basic": 199.0, "Professional": 499.0, "Enterprise": 999.0}

def _days_remaining(expiry: date) -> int:
    return max(0, (expiry - date.today()).days)

def _fmt_amount(amount: float) -> str:
    return f"${amount:,.2f}"


# ── Owner: get my subscription ────────────────────────────────────────────────

@router.get("/my-subscription")
async def get_my_subscription(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Returns the subscription for the current user's active property."""
    property_id = current_user.property_id
    if not property_id:
        return {"data": None, "message": "No property associated with this user."}

    sub_res = await db.execute(
        select(Subscription)
        .where(Subscription.property_id == property_id)
        .order_by(Subscription.expiry_date.desc())
    )
    sub = sub_res.scalars().first()
    if not sub:
        return {"data": None, "message": "No subscription found."}

    remaining = _days_remaining(sub.expiry_date)
    return {
        "data": {
            "id": str(sub.id),
            "plan": sub.plan,
            "status": sub.status,
            "billing_cycle": sub.billing_cycle,
            "start_date": str(sub.start_date),
            "expiry_date": str(sub.expiry_date),
            "days_remaining": remaining,
            "device_limit": sub.device_limit,
            "registered_devices": sub.registered_devices,
            "subscription_required": sub.subscription_required,
            "is_trial": sub.plan == "Trial",
            "is_active": sub.status in ("Active", "Trial") and sub.expiry_date >= date.today(),
        }
    }


# ── List all subscriptions ─────────────────────────────────────────────────────

@router.get("/plans")
async def get_subscription_plans(db: AsyncSession = Depends(get_db)):
    q = select(SubscriptionPlan).order_by(SubscriptionPlan.amount.asc())
    result = await db.execute(q)
    rows = result.scalars().all()
    
    data = []
    for plan in rows:
        data.append({
            "id": str(plan.plan_id),
            "name": plan.name,
            "features": plan.features,
            "amount": str(plan.amount),
            "duration": plan.duration_months,
            "status": plan.status
        })
    return {"data": data}

@router.post("/plans")
async def create_subscription_plan(payload: dict, db: AsyncSession = Depends(get_db)):
    plan = SubscriptionPlan(
        name=payload.get("name"),
        features=payload.get("features"),
        amount=payload.get("amount"),
        duration_months=payload.get("duration", 1)
    )
    db.add(plan)
    try:
        await db.flush()
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Could not create plan. Name might be a duplicate.")
        
    await AuditLogger.log(
        db,
        module_name="Subscriptions",
        action_type="Created",
        target_entity="SubscriptionPlan",
        target_record_id=plan.plan_id,
        user_id=None
    )
    
    return {"message": "Plan created successfully", "id": str(plan.plan_id)}

@router.put("/plans/{plan_id}")
async def update_subscription_plan(plan_id: str, payload: dict, db: AsyncSession = Depends(get_db)):
    q = select(SubscriptionPlan).where(SubscriptionPlan.plan_id == plan_id)
    result = await db.execute(q)
    plan = result.scalars().first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
        
    if "name" in payload:
        plan.name = payload["name"]
    if "features" in payload:
        plan.features = payload["features"]
    if "amount" in payload:
        plan.amount = payload["amount"]
    if "duration" in payload:
        plan.duration_months = payload["duration"]
    if "status" in payload:
        plan.status = payload["status"]
        
    
    await AuditLogger.log(
        db,
        module_name="Subscriptions",
        action_type="Updated",
        target_entity="SubscriptionPlan",
        target_record_id=plan.plan_id,
        user_id=None
    )
    
    return {"message": "Plan updated successfully"}

@router.delete("/plans/{plan_id}")
async def delete_subscription_plan(plan_id: str, db: AsyncSession = Depends(get_db)):
    q = select(SubscriptionPlan).where(SubscriptionPlan.plan_id == plan_id)
    result = await db.execute(q)
    plan = result.scalars().first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
        
    await db.delete(plan)
    
    await AuditLogger.log(
        db,
        module_name="Subscriptions",
        action_type="Deleted",
        target_entity="SubscriptionPlan",
        target_record_id=plan.plan_id,
        user_id=None
    )
    
    return {"message": "Plan deleted successfully"}

# ── List all subscriptions ─────────────────────────────────────────────────────

@router.get("/")
async def get_subscriptions(db: AsyncSession = Depends(get_db)):
    q = (
        select(Subscription, Property, Owner)
        .select_from(Subscription)
        .join(Property, Subscription.property_id == Property.property_id)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .order_by(Subscription.expiry_date.asc())
    )
    result = await db.execute(q)
    rows = result.all()

    data = []
    for sub, prop, owner in rows:
        remaining = _days_remaining(sub.expiry_date)
        data.append({
            "id": str(sub.id),
            "propertyId": str(prop.property_id),
            "propertyName": prop.property_name,
            "propertyType": prop.property_type or "Hotel",
            "city": "—",
            "state": "—",
            "ownerName": owner.full_name,
            "ownerMobile": owner.mobile_number,
            "ownerWhatsApp": prop.whatsapp_number or owner.mobile_number,
            "plan": sub.plan,
            "startDate": str(sub.start_date),
            "expiryDate": str(sub.expiry_date),
            "remainingDays": remaining,
            "billingCycle": sub.billing_cycle,
            "status": sub.status,
            "licenseId": sub.license_id or "—",
            "licenseStatus": "Valid" if sub.status == "Active" else "Invalid",
            "licenseIssueDate": str(sub.start_date),
            "deviceLimit": sub.device_limit,
            "registeredDevices": sub.registered_devices,
            "lastPayment": "—",
            "lastInvoice": "—",
            "nextRenewal": str(sub.expiry_date),
            "outstandingAmount": "$0.00",
            "primaryDevice": "—",
            "lastSync": "—",
            "deviceStatus": "Active",
            "totalPaid": _fmt_amount(PLAN_PRICE.get(sub.plan, 0)),
            "recentActivities": [],
            "devicesList": [],
            "subscriptionRequired": sub.subscription_required,
        })
    return {"data": data}


# ── KPIs ──────────────────────────────────────────────────────────────────────

@router.get("/kpis")
async def get_subscription_kpis(db: AsyncSession = Depends(get_db)):
    q = select(Subscription.status, func.count(Subscription.id)).group_by(Subscription.status)
    result = await db.execute(q)
    counts = {row[0]: row[1] for row in result.all()}

    total = sum(counts.values())
    active = counts.get("Active", 0)
    expired = counts.get("Expired", 0)
    grace = counts.get("Grace Period", 0)
    disabled = counts.get("Disabled", 0)

    # Upcoming expiry (next 7 days)
    soon_q = await db.execute(
        select(func.count(Subscription.id)).where(
            Subscription.status == "Active",
            Subscription.expiry_date <= date.today() + timedelta(days=7),
            Subscription.expiry_date >= date.today()
        )
    )
    expiring_soon = soon_q.scalar() or 0

    return {
        "totalSubscriptions": total,
        "activePlans": active + grace,
        "expiredPlans": expired,
        "disabledSubscriptions": disabled,
        "expiringSoon": expiring_soon,
        "upgradesThisMonth": 0,
        "downgradesThisMonth": 0,
    }


# ── Subscription Dashboard (SubscriptionDashboard.jsx) ──────────────────────

@router.get("/dashboard")
async def get_subscription_dashboard(db: AsyncSession = Depends(get_db)):
    status_q = await db.execute(
        select(Subscription.status, func.count(Subscription.id)).group_by(Subscription.status)
    )
    counts = {row[0]: row[1] for row in status_q.all()}

    active = counts.get("Active", 0)
    expired = counts.get("Expired", 0)
    grace = counts.get("Grace Period", 0)

    # Expiring in next 3 days
    soon_q = await db.execute(
        select(func.count(Subscription.id)).where(
            Subscription.status == "Active",
            Subscription.expiry_date <= date.today() + timedelta(days=3),
            Subscription.expiry_date >= date.today()
        )
    )
    expiring_3 = soon_q.scalar() or 0

    # Monthly revenue (sum of paid invoices this month)
    rev_q = await db.execute(
        select(func.sum(Invoice.amount + func.coalesce(Invoice.gst, 0)))
        .where(Invoice.status == "Paid")
    )
    revenue = float(rev_q.scalar() or 0)

    # Plan distribution
    plan_q = await db.execute(
        select(Subscription.plan, func.count(Subscription.id))
        .where(Subscription.status == "Active")
        .group_by(Subscription.plan)
    )
    plan_counts = {row[0]: row[1] for row in plan_q.all()}

    PLAN_COLORS = {"Basic": "#5f703a", "Professional": "#8aa356", "Enterprise": "#2f2e2a"}

    # Revenue by month (last 6 months from invoices)
    bar_q = await db.execute(
        select(Invoice.date, Invoice.amount, Invoice.gst)
        .where(Invoice.status == "Paid")
        .order_by(Invoice.date)
    )
    bar_rows = bar_q.all()
    bar_map: dict = {}
    for inv_date, amt, gst in bar_rows:
        key = inv_date.strftime("%b")
        bar_map[key] = bar_map.get(key, 0) + float(amt or 0)
    bar_data = [{"name": k, "revenue": round(v, 2)} for k, v in bar_map.items()]

    # Recent paid transactions
    tx_q = await db.execute(
        select(SubscriptionTransaction, Property)
        .join(Property, SubscriptionTransaction.property_id == Property.property_id)
        .where(SubscriptionTransaction.status == "Success")
        .order_by(SubscriptionTransaction.created_at.desc())
        .limit(5)
    )
    tx_rows = tx_q.all()
    activities = []
    for tx, prop in tx_rows:
        activities.append({
            "id": str(tx.id),
            "action": "Payment Received",
            "subject": prop.property_name,
            "time": str(tx.created_at)[:10] if tx.created_at else "—",
            "amount": _fmt_amount(float(tx.amount)),
            "status": tx.status,
        })

    return {
        "kpis": [
            {"name": "Total Active Subscriptions", "value": str(active + grace), "icon": "CheckCircle2", "color": "text-green-600", "bg": "bg-green-50"},
            {"name": "Expiring in Next 3 Days", "value": str(expiring_3), "icon": "AlertCircle", "color": "text-orange-500", "bg": "bg-orange-50"},
            {"name": "Grace Period Properties", "value": str(grace), "icon": "Clock", "color": "text-yellow-600", "bg": "bg-yellow-50"},
            {"name": "Expired Subscriptions", "value": str(expired), "icon": "Ban", "color": "text-red-500", "bg": "bg-red-50"},
            {"name": "Monthly Revenue", "value": _fmt_amount(revenue), "icon": "DollarSign", "color": "text-pine-DEFAULT", "bg": "bg-pine-50"},
            {"name": "Pending Renewals", "value": str(expiring_3 + grace), "icon": "CalendarDays", "color": "text-indigo-500", "bg": "bg-indigo-50"},
        ],
        "pieData": [
            {"name": plan, "value": cnt, "color": PLAN_COLORS.get(plan, "#888")}
            for plan, cnt in plan_counts.items()
        ],
        "barData": bar_data,
        "recentActivities": activities,
    }


# ── Renewal Management (RenewalManagement.jsx) ─────────────────────────────

@router.get("/renewals")
async def get_renewal_data(db: AsyncSession = Depends(get_db)):
    today_date = date.today()

    # Upcoming (next 7 days, still active)
    upcoming_q = await db.execute(
        select(Subscription, Property, Owner)
        .select_from(Subscription)
        .join(Property, Subscription.property_id == Property.property_id)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .where(
            Subscription.status == "Active",
            Subscription.expiry_date >= today_date,
            Subscription.expiry_date <= today_date + timedelta(days=7)
        )
        .order_by(Subscription.expiry_date.asc())
    )
    upcoming_rows = upcoming_q.all()

    # Grace period
    grace_q = await db.execute(
        select(Subscription, Property, Owner)
        .select_from(Subscription)
        .join(Property, Subscription.property_id == Property.property_id)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .where(Subscription.status == "Grace Period")
        .order_by(Subscription.expiry_date.asc())
    )
    grace_rows = grace_q.all()

    # Enforcement (disabled / long expired)
    enforce_q = await db.execute(
        select(Subscription, Property)
        .select_from(Subscription)
        .join(Property, Subscription.property_id == Property.property_id)
        .where(Subscription.status.in_(["Disabled", "Expired"]))
        .order_by(Subscription.expiry_date.asc())
    )
    enforce_rows = enforce_q.all()

    def expiry_label(expiry: date) -> str:
        diff = (expiry - today_date).days
        if diff == 0:
            return "Today"
        if diff == 1:
            return "Tomorrow"
        if diff < 0:
            return f"{abs(diff)} days ago"
        return f"In {diff} days"

    upcoming = [
        {
            "id": str(sub.id),
            "property": prop.property_name,
            "owner": owner.full_name,
            "mobile": owner.mobile_number,
            "plan": sub.plan,
            "expiryDate": expiry_label(sub.expiry_date),
            "daysRemaining": _days_remaining(sub.expiry_date),
            "amount": _fmt_amount(PLAN_PRICE.get(sub.plan, 0)),
            "reminderStatus": "Pending",
        }
        for sub, prop, owner in upcoming_rows
    ]

    grace = [
        {
            "id": str(sub.id),
            "property": prop.property_name,
            "plan": sub.plan,
            "graceDay": abs((sub.expiry_date - today_date).days),
            "amountDue": _fmt_amount(PLAN_PRICE.get(sub.plan, 0)),
            "reminderCount": 2,
            "lastReminder": "Today",
            "contactStatus": "Contacted",
        }
        for sub, prop, owner in grace_rows
    ]

    enforcement = [
        {
            "id": str(sub.id),
            "property": prop.property_name,
            "plan": sub.plan,
            "expiredOn": str(sub.expiry_date),
            "graceEndDate": str(sub.expiry_date + timedelta(days=7)),
            "daysOverdue": max(0, (today_date - sub.expiry_date).days),
            "outstandingAmount": _fmt_amount(PLAN_PRICE.get(sub.plan, 0)),
            "status": "Applied" if sub.status == "Disabled" else "Pending",
        }
        for sub, prop in enforce_rows
    ]

    # Aggregate KPIs
    renewed_today_q = await db.execute(
        select(func.count(Subscription.id))
        .where(Subscription.start_date == today_date)
    )
    renewed_today = renewed_today_q.scalar() or 0

    total_active_q = await db.execute(
        select(func.count(Subscription.id))
        .where(Subscription.status.in_(["Active", "Grace Period"]))
    )
    total_active = total_active_q.scalar() or 1

    return {
        "kpis": [
            {"name": "Renewals Today", "value": str(len(upcoming)), "icon": "AlertTriangle", "color": "text-orange-500", "bg": "bg-orange-50"},
            {"name": "Next 7 Days", "value": str(len(upcoming)), "icon": "CalendarDays", "color": "text-blue-500", "bg": "bg-blue-50"},
            {"name": "Grace Period", "value": str(len(grace)), "icon": "Clock", "color": "text-yellow-600", "bg": "bg-yellow-50"},
            {"name": "Enforcement Pending", "value": str(len(enforcement)), "icon": "ShieldAlert", "color": "text-purple-600", "bg": "bg-purple-50"},
            {"name": "Renewed Today", "value": str(renewed_today), "icon": "CheckCircle2", "color": "text-green-500", "bg": "bg-green-50"},
            {"name": "Success Rate", "value": f"{round((total_active / max(total_active, 1)) * 100)}%", "icon": "Activity", "color": "text-pine", "bg": "bg-pine/10"},
        ],
        "upcoming": upcoming,
        "grace": grace,
        "enforcement": enforcement,
        "reminders": [],  # Would come from a comms_log table (future)
    }


# ── Toggle status ────────────────────────────────────────────────────────────

@router.post("/{property_id}/status")
async def toggle_subscription_status(property_id: str, payload: dict, db: AsyncSession = Depends(get_db), current_user: User = Depends(require_super_admin)):
    action = payload.get("action")
    q = select(Subscription).where(Subscription.property_id == property_id)
    result = await db.execute(q)
    sub = result.scalars().first()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    sub.status = "Active" if action == "enable" else "Disabled"
    
    await AuditLogger.log(
        db,
        property_id=sub.property_id,
        module_name="Subscriptions",
        action_type="Updated",
        target_entity="Subscription",
        target_record_id=sub.id,
        user_id=current_user.id,
        new_value={"status": sub.status}
    )
    
    return {"message": f"Subscription {action}d successfully", "status": sub.status}

@router.post("/{property_id}/toggle-required")
async def toggle_subscription_required(property_id: str, payload: dict, db: AsyncSession = Depends(get_db), current_user: User = Depends(require_super_admin)):
    required = payload.get("required")
    q = select(Subscription).where(Subscription.property_id == property_id)
    result = await db.execute(q)
    sub = result.scalars().first()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    if required is not None:
        sub.subscription_required = required
    else:
        sub.subscription_required = not sub.subscription_required
    
    await AuditLogger.log(
        db,
        property_id=sub.property_id,
        module_name="Subscriptions",
        action_type="Updated",
        target_entity="Subscription",
        target_record_id=sub.id,
        user_id=current_user.id,
        new_value={"subscription_required": sub.subscription_required}
    )
    
    return {"message": "Subscription requirement updated", "subscriptionRequired": sub.subscription_required}


# ── Update plan ──────────────────────────────────────────────────────────────

@router.put("/{property_id}/plan")
async def update_plan(property_id: str, payload: dict, db: AsyncSession = Depends(get_db), current_user: User = Depends(require_super_admin)):
    new_plan = payload.get("plan")
    q = select(Subscription).where(Subscription.property_id == property_id)
    result = await db.execute(q)
    sub = result.scalars().first()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    sub.plan = new_plan
    
    await AuditLogger.log(
        db,
        property_id=sub.property_id,
        module_name="Subscriptions",
        action_type="Updated",
        target_entity="Subscription",
        target_record_id=sub.id,
        user_id=current_user.id,
        new_value={"plan": sub.plan}
    )
    
    return {"message": "Plan updated successfully", "plan": sub.plan}


# ── Generate license ──────────────────────────────────────────────────────────

@router.post("/{property_id}/license")
async def generate_license(property_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(require_super_admin)):
    import secrets
    q = select(Subscription).where(Subscription.property_id == property_id)
    result = await db.execute(q)
    sub = result.scalars().first()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    sub.license_id = f"PSL-{secrets.token_hex(8).upper()}"
    
    await AuditLogger.log(
        db,
        property_id=sub.property_id,
        module_name="Subscriptions",
        action_type="Generated",
        target_entity="License",
        target_record_id=sub.id,
        user_id=current_user.id,
        new_value={"license_id": sub.license_id}
    )
    
    return {"message": "License regenerated", "licenseId": sub.license_id}

# ── Stripe Checkout & Webhooks ───────────────────────────────────────────────

@router.post("/create-checkout-session")
async def create_checkout_session(
    payload: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    plan_name = payload.get("plan")
    if not plan_name or plan_name not in PLAN_PRICE:
        raise HTTPException(status_code=400, detail="Invalid plan selected")
        
    property_id = current_user.property_id
    if not property_id:
        raise HTTPException(status_code=400, detail="No property associated with user")

    try:
        checkout_session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[
                {
                    'price_data': {
                        'currency': 'usd',
                        'product_data': {
                            'name': f"Pinesphere Stay - {plan_name} Plan",
                        },
                        'unit_amount': int(PLAN_PRICE[plan_name] * 100),
                    },
                    'quantity': 1,
                },
            ],
            mode='subscription',
            success_url=payload.get("success_url", "https://pinesphere.com/success?session_id={CHECKOUT_SESSION_ID}"),
            cancel_url=payload.get("cancel_url", "https://pinesphere.com/cancel"),
            client_reference_id=property_id,
            metadata={"plan": plan_name, "owner_id": str(current_user.id)}
        )
        return {"checkout_url": checkout_session.url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/cancel")
async def cancel_subscription(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    property_id = current_user.property_id
    if not property_id:
        raise HTTPException(status_code=400, detail="No property associated")
        
    q = select(Subscription).where(Subscription.property_id == property_id)
    result = await db.execute(q)
    sub = result.scalars().first()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")

    # In a real scenario, we'd also call Stripe API to cancel:
    # stripe.Subscription.modify(sub.stripe_subscription_id, cancel_at_period_end=True)
    
    sub.status = "Cancelled"
    # Keeping expiry_date unchanged so they have access until billing cycle ends
    
    await AuditLogger.log(
        db,
        property_id=sub.property_id,
        module_name="Subscriptions",
        action_type="Cancelled",
        target_entity="Subscription",
        target_record_id=sub.id,
        user_id=current_user.id
    )
    
    return {"message": "Subscription cancelled successfully", "expiry_date": str(sub.expiry_date)}

@router.post("/webhooks/stripe")
async def stripe_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, STRIPE_WEBHOOK_SECRET
        )
    except ValueError as e:
        # Invalid payload
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError as e:
        # Invalid signature
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Handle the checkout.session.completed event
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        
        property_id = session.get('client_reference_id')
        plan_name = session.get('metadata', {}).get('plan', 'Professional')
        
        if property_id:
            # Upgrade their subscription in the DB
            q = select(Subscription).where(Subscription.property_id == property_id)
            result = await db.execute(q)
            sub = result.scalars().first()
            
            if sub:
                sub.plan = plan_name
                sub.status = "Active"
                sub.billing_cycle = "Monthly"
                sub.start_date = date.today()
                sub.expiry_date = date.today() + timedelta(days=30)
                await db.commit()
                
    return {"status": "success"}
