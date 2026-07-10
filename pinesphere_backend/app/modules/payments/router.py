from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from datetime import date

from app.infra.database import get_db
from app.infra.models import PaymentTransaction, Invoice, PendingDue, Property, Owner, Subscription

router = APIRouter()

def _fmt(amount) -> str:
    return f"${float(amount):,.2f}"


@router.get("/transactions")
async def get_transactions(db: AsyncSession = Depends(get_db)):
    q = (
        select(PaymentTransaction, Property, Owner, Subscription)
        .join(Property, PaymentTransaction.property_id == Property.property_id)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .outerjoin(Subscription, Subscription.property_id == Property.property_id)
        .order_by(PaymentTransaction.created_at.desc())
    )
    result = await db.execute(q)
    rows = result.unique().all()

    # deduplicate by tx.id
    seen = set()
    data = []
    for tx, prop, owner, sub in rows:
        if str(tx.id) in seen:
            continue
        seen.add(str(tx.id))
        data.append({
            "id": str(tx.id),
            "paymentId": tx.payment_id,
            "invoice": str(tx.invoice_id) if tx.invoice_id else "—",
            "property": prop.property_name,
            "owner": owner.full_name,
            "plan": sub.plan if sub else "—",
            "billingCycle": sub.billing_cycle if sub else "—",
            "amount": _fmt(tx.amount),
            "method": tx.method or "Unknown",
            "date": str(tx.created_at)[:10] if tx.created_at else "—",
            "status": tx.status,
            "collectedBy": "System",
            "bankRef": tx.bank_ref or "—",
        })
    return {"data": data}


@router.get("/pending")
async def get_pending_dues(db: AsyncSession = Depends(get_db)):
    q = (
        select(PendingDue, Property, Owner)
        .join(Property, PendingDue.property_id == Property.property_id)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .order_by(PendingDue.days_overdue.desc())
    )
    result = await db.execute(q)
    rows = result.all()

    data = [
        {
            "id": str(due.id),
            "property": prop.property_name,
            "owner": owner.full_name,
            "mobile": owner.mobile_number,
            "plan": due.plan,
            "dueDate": str(due.due_date),
            "amountDue": _fmt(due.amount_due),
            "daysOverdue": due.days_overdue,
            "reminderStatus": due.reminder_status or "Not Sent",
        }
        for due, prop, owner in rows
    ]
    return {"data": data}


@router.get("/invoices")
async def get_invoices(db: AsyncSession = Depends(get_db)):
    q = (
        select(Invoice, Property, Owner)
        .join(Property, Invoice.property_id == Property.property_id)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .order_by(Invoice.date.desc())
    )
    result = await db.execute(q)
    rows = result.all()

    data = [
        {
            "id": inv.invoice_number,
            "property": prop.property_name,
            "owner": owner.full_name,
            "plan": inv.plan,
            "date": str(inv.date),
            "dueDate": str(inv.due_date),
            "amount": _fmt(inv.amount),
            "gst": _fmt(inv.gst) if inv.gst else "—",
            "total": _fmt(float(inv.amount) + float(inv.gst or 0)),
            "status": inv.status,
        }
        for inv, prop, owner in rows
    ]
    return {"data": data}


@router.get("/kpis")
async def get_payment_kpis(db: AsyncSession = Depends(get_db)):
    # Total revenue (paid)
    total_rev_q = await db.execute(
        select(func.sum(Invoice.amount + func.coalesce(Invoice.gst, 0)))
        .where(Invoice.status == "Paid")
    )
    total_rev = float(total_rev_q.scalar() or 0)

    # Monthly revenue (current month)
    first_of_month = date.today().replace(day=1)
    monthly_rev_q = await db.execute(
        select(func.sum(Invoice.amount + func.coalesce(Invoice.gst, 0)))
        .where(Invoice.status == "Paid", Invoice.date >= first_of_month)
    )
    monthly_rev = float(monthly_rev_q.scalar() or 0)

    # Pending collections
    pending_q = await db.execute(select(func.sum(PendingDue.amount_due)))
    pending_total = float(pending_q.scalar() or 0)

    # Failed payments
    failed_q = await db.execute(
        select(func.count(PaymentTransaction.id))
        .where(PaymentTransaction.status == "Failed")
    )
    failed = int(failed_q.scalar() or 0)

    # Total invoices
    inv_count_q = await db.execute(select(func.count(Invoice.id)))
    inv_count = int(inv_count_q.scalar() or 0)

    # Collection rate
    paid_q = await db.execute(
        select(func.count(Invoice.id)).where(Invoice.status == "Paid")
    )
    paid_count = int(paid_q.scalar() or 0)
    rate = round((paid_count / max(inv_count, 1)) * 100)

    # Avg subscription value
    avg_q = await db.execute(select(func.avg(Invoice.amount)))
    avg_val = float(avg_q.scalar() or 0)

    return {"data": [
        {"name": "Total Revenue", "value": _fmt(total_rev), "icon": "DollarSign", "color": "text-green-600", "bg": "bg-green-50"},
        {"name": "Monthly Revenue", "value": _fmt(monthly_rev), "icon": "TrendingUp", "color": "text-pine", "bg": "bg-pine/10"},
        {"name": "Pending Collections", "value": _fmt(pending_total), "icon": "Clock", "color": "text-yellow-600", "bg": "bg-yellow-50"},
        {"name": "Failed Payments", "value": str(failed), "icon": "AlertTriangle", "color": "text-red-500", "bg": "bg-red-50"},
        {"name": "Total Invoices", "value": str(inv_count), "icon": "FileText", "color": "text-blue-500", "bg": "bg-blue-50"},
        {"name": "Avg Sub Value", "value": _fmt(avg_val), "icon": "ArrowUpRight", "color": "text-purple-600", "bg": "bg-purple-50"},
        {"name": "Collection Rate", "value": f"{rate}%", "icon": "CheckCircle2", "color": "text-emerald-500", "bg": "bg-emerald-50"},
    ]}


@router.get("/dashboard")
async def get_dashboard_data(db: AsyncSession = Depends(get_db)):
    # Monthly trend
    trend_q = await db.execute(
        select(Invoice.date, Invoice.amount, Invoice.gst)
        .where(Invoice.status == "Paid")
        .order_by(Invoice.date)
    )
    trend_rows = trend_q.all()
    monthly_map: dict = {}
    for d, amt, gst in trend_rows:
        key = d.strftime("%b")
        monthly_map[key] = monthly_map.get(key, 0) + float(amt or 0) + float(gst or 0)
    monthly_trend = [{"name": k, "revenue": round(v, 2)} for k, v in monthly_map.items()]

    # Plan revenue breakdown
    plan_rev_q = await db.execute(
        select(Invoice.plan, func.sum(Invoice.amount + func.coalesce(Invoice.gst, 0)))
        .where(Invoice.status == "Paid")
        .group_by(Invoice.plan)
    )
    plan_rows = plan_rev_q.all()
    plan_colors = {"Basic": "#5f703a", "Professional": "#8aa356", "Enterprise": "#2f2e2a"}
    plan_revenue = [
        {"name": plan, "value": round(float(rev), 2), "color": plan_colors.get(plan, "#888")}
        for plan, rev in plan_rows
    ]

    # Payment method breakdown
    method_q = await db.execute(
        select(PaymentTransaction.method, func.sum(PaymentTransaction.amount))
        .where(PaymentTransaction.status == "Success")
        .group_by(PaymentTransaction.method)
    )
    method_rows = method_q.all()
    method_colors = {"UPI": "#6366f1", "Net Banking": "#8aa356", "Credit Card": "#f59e0b", "Cheque": "#64748b"}
    method_revenue = [
        {"name": method or "Other", "value": round(float(amt), 2), "color": method_colors.get(method, "#888")}
        for method, amt in method_rows
    ]

    # Outstanding dues
    outstanding_q = await db.execute(
        select(PendingDue, Property)
        .join(Property, PendingDue.property_id == Property.property_id)
        .order_by(PendingDue.days_overdue.desc())
        .limit(5)
    )
    outstanding_rows = outstanding_q.all()
    outstanding = [
        {
            "property": prop.property_name,
            "amount": _fmt(due.amount_due),
            "daysOverdue": due.days_overdue,
        }
        for due, prop in outstanding_rows
    ]

    return {"data": {
        "monthlyTrend": monthly_trend,
        "planRevenue": plan_revenue,
        "methodRevenue": method_revenue,
        "outstanding": outstanding,
    }}


@router.post("/pending/{due_id}/mark-paid")
async def mark_due_as_paid(due_id: str, db: AsyncSession = Depends(get_db)):
    import uuid
    try:
        uid = uuid.UUID(due_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid due ID")
    result = await db.execute(select(PendingDue).where(PendingDue.id == uid))
    due = result.scalars().first()
    if not due:
        raise HTTPException(status_code=404, detail="Pending due not found")
    await db.delete(due)
    await db.commit()
    return {"message": "Marked as paid and removed from pending dues"}


@router.post("/pending/{due_id}/remind")
async def send_reminder(due_id: str, db: AsyncSession = Depends(get_db)):
    import uuid
    try:
        uid = uuid.UUID(due_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid due ID")
    result = await db.execute(select(PendingDue).where(PendingDue.id == uid))
    due = result.scalars().first()
    if not due:
        raise HTTPException(status_code=404, detail="Pending due not found")
    due.reminder_status = "Reminded"
    await db.commit()
    return {"message": "Reminder queued successfully"}


@router.post("/pending/{due_id}/link")
async def send_payment_link(due_id: str, db: AsyncSession = Depends(get_db)):
    return {"message": "Payment link sent via WhatsApp/SMS", "link": f"https://pay.pinesphere.in/{due_id}"}
