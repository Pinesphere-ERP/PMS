from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, and_
from datetime import date, timedelta
from typing import List

from app.infra.database import get_db
from app.infra.models import Property, Owner, Business, Subscription, AuditLog
from app.modules.properties.schemas import PropertyCreateInput

router = APIRouter()


def _property_status(onboarding_status: str, sub_status: str | None) -> str:
    if sub_status == "Disabled":
        return "Suspended"
    if onboarding_status == "completed":
        return "Active"
    return "Pending"


def _verification_status(onboarding_status: str) -> str:
    return "Verified" if onboarding_status == "completed" else "Pending"


@router.post("")
async def create_property(payload: PropertyCreateInput, db: AsyncSession = Depends(get_db)):
    # Create Owner
    new_owner = Owner(
        full_name=payload.owner_name,
        mobile_number=payload.owner_mobile,
        email=payload.owner_email,
        pan_number=payload.owner_pan,
    )
    db.add(new_owner)
    await db.flush()

    # Create Business
    new_business = Business(
        owner_id=new_owner.owner_id,
        business_name=payload.business_name,
        business_reg_number=payload.business_reg_number,
        gst_number=payload.business_gst,
        pan_number=payload.business_pan,
    )
    db.add(new_business)
    await db.flush()

    # Create Property
    new_property = Property(
        business_id=new_business.business_id,
        owner_id=new_owner.owner_id,
        property_name=payload.property_name,
        property_type=payload.property_type,
        star_category=payload.star_category,
        year_established=payload.year_established,
        total_floors=payload.total_floors,
        total_rooms=payload.total_rooms,
        description=payload.description,
        onboarding_status="draft",
    )
    db.add(new_property)
    await db.commit()
    await db.refresh(new_property)

    return {"message": "Property created successfully", "property_id": str(new_property.property_id)}


@router.get("")
async def get_properties(db: AsyncSession = Depends(get_db)):
    """List all properties joined with owner, business and latest subscription."""
    q = (
        select(Property, Owner, Business, Subscription)
        .select_from(Property)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .join(Business, Property.business_id == Business.business_id)
        .outerjoin(Subscription, Subscription.property_id == Property.property_id)
    )
    result = await db.execute(q)
    rows = result.unique().all()

    # De-duplicate: one row per property (take first subscription found)
    seen = {}
    for prop, owner, biz, sub in rows:
        pid = str(prop.property_id)
        if pid not in seen:
            seen[pid] = (prop, owner, biz, sub)

    data = []
    for pid, (prop, owner, biz, sub) in seen.items():
        status = _property_status(prop.onboarding_status, sub.status if sub else None)
        data.append({
            "id": pid,
            "name": prop.property_name,
            "property_name": prop.property_name,
            "type": prop.property_type or "Hotel",
            "property_type": prop.property_type or "Hotel",
            "owner": owner.full_name,
            "mobile": owner.mobile_number,
            "city": "Unknown",  # city not in current schema; extend Property model to add
            "rooms": prop.total_rooms or 0,
            "status": status,
            "verificationStatus": _verification_status(prop.onboarding_status),
            "subscriptionStatus": sub.status if sub else "No Subscription",
            "plan": sub.plan if sub else "N/A",
            "business": biz.business_name,
            "lastUpdated": str(prop.updated_at)[:10] if prop.updated_at else "N/A",
            "onboarding": "100%" if prop.onboarding_status == "completed" else "50%",
            "lastSync": "N/A",
        })
    return data


@router.get("/kpis")
async def get_property_kpis(db: AsyncSession = Depends(get_db)):
    """Aggregate KPI counts for the Property Management dashboard."""
    total_q = await db.execute(select(func.count(Property.property_id)))
    total = total_q.scalar() or 0

    active_q = await db.execute(
        select(func.count(Property.property_id))
        .where(Property.onboarding_status == "completed")
    )
    active = active_q.scalar() or 0

    pending_q = await db.execute(
        select(func.count(Property.property_id))
        .where(Property.onboarding_status != "completed")
    )
    pending = pending_q.scalar() or 0

    suspended_q = await db.execute(
        select(func.count(Subscription.id))
        .where(Subscription.status == "Disabled")
    )
    suspended = suspended_q.scalar() or 0

    return [
        {"name": "Total Properties", "value": str(total), "icon": "Building2", "color": "text-pine-DEFAULT", "bg": "bg-pine-50"},
        {"name": "Active", "value": str(active), "icon": "CheckCircle2", "color": "text-green-600", "bg": "bg-green-50"},
        {"name": "Pending Verification", "value": str(pending), "icon": "Clock", "color": "text-yellow-600", "bg": "bg-yellow-50"},
        {"name": "Suspended", "value": str(suspended), "icon": "Ban", "color": "text-red-500", "bg": "bg-red-50"},
    ]


@router.get("/dashboard")
async def get_property_dashboard(db: AsyncSession = Depends(get_db)):
    """Super Admin overview dashboard: KPIs + recent audit activity."""
    # --- KPIs ---
    total_q = await db.execute(select(func.count(Property.property_id)))
    total = total_q.scalar() or 0

    active_q = await db.execute(
        select(func.count(Property.property_id))
        .where(Property.onboarding_status == "completed")
    )
    active = active_q.scalar() or 0

    pending_q = await db.execute(
        select(func.count(Property.property_id))
        .where(Property.onboarding_status == "draft")
    )
    pending = pending_q.scalar() or 0

    sub_active_q = await db.execute(
        select(func.count(Subscription.id))
        .where(Subscription.status == "Active")
    )
    active_subs = sub_active_q.scalar() or 0

    sub_expired_q = await db.execute(
        select(func.count(Subscription.id))
        .where(Subscription.status == "Expired")
    )
    expired_subs = sub_expired_q.scalar() or 0

    sub_disabled_q = await db.execute(
        select(func.count(Subscription.id))
        .where(Subscription.status == "Disabled")
    )
    disabled_subs = sub_disabled_q.scalar() or 0

    # --- Recent activity from audit_logs ---
    audit_q = (
        select(AuditLog, Property)
        .outerjoin(Property, AuditLog.property_id == Property.property_id)
        .order_by(AuditLog.timestamp.desc())
        .limit(6)
    )
    audit_result = await db.execute(audit_q)
    audit_rows = audit_result.all()

    STATUS_BADGE = {
        "CREATE": "bg-yellow-500/20 text-yellow-300 border-yellow-500/30",
        "UPDATE": "bg-green-500/20 text-green-300 border-green-500/30",
        "DELETE": "bg-red-500/20 text-red-300 border-red-500/30",
    }

    def time_ago(ts):
        diff = (date.today() - ts.date()) if ts else None
        if diff is None:
            return "Unknown"
        if diff.days == 0:
            return "Today"
        if diff.days == 1:
            return "Yesterday"
        return f"{diff.days} days ago"

    activities = []
    for log, prop in audit_rows:
        activities.append({
            "id": str(log.log_id),
            "action": log.action_type or "System Action",
            "subject": prop.property_name if prop else "System",
            "time": time_ago(log.timestamp),
            "status": log.module_name or "System",
            "badge": STATUS_BADGE.get(log.action_type, "bg-gray-500/20 text-gray-300 border-gray-500/30")
        })

    return {
        "kpis": [
            {"name": "Total Properties", "value": str(total), "icon": "Building2", "color": "text-pine-light", "glow": "shadow-pine-light/20"},
            {"name": "Active Properties", "value": str(active), "icon": "CheckCircle2", "color": "text-green-400", "glow": "shadow-green-400/20"},
            {"name": "Pending Verification", "value": str(pending), "icon": "Clock", "color": "text-yellow-400", "glow": "shadow-yellow-400/20"},
            {"name": "Suspended", "value": str(disabled_subs), "icon": "Ban", "color": "text-red-400", "glow": "shadow-red-400/20"},
            {"name": "Expired Subscriptions", "value": str(expired_subs), "icon": "AlertCircle", "color": "text-orange-400", "glow": "shadow-orange-400/20"},
            {"name": "Active Subscriptions", "value": str(active_subs), "icon": "CreditCard", "color": "text-indigo-400", "glow": "shadow-indigo-400/20"},
        ],
        "recentActivities": activities
    }


@router.get("/{property_id}")
async def get_property_detail(property_id: str, db: AsyncSession = Depends(get_db)):
    """Return a single property with owner, subscription, device info."""
    try:
        import uuid as _uuid
        pid = _uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property ID format")

    q = (
        select(Property, Owner, Business, Subscription)
        .select_from(Property)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .join(Business, Property.business_id == Business.business_id)
        .outerjoin(Subscription, Subscription.property_id == Property.property_id)
        .where(Property.property_id == pid)
    )
    result = await db.execute(q)
    row = result.first()
    if not row:
        raise HTTPException(status_code=404, detail="Property not found")

    prop, owner, biz, sub = row
    return {
        "id": str(prop.property_id),
        "name": prop.property_name,
        "type": prop.property_type,
        "rooms": prop.total_rooms,
        "floors": prop.total_floors,
        "owner": owner.full_name,
        "mobile": owner.mobile_number,
        "email": owner.email,
        "business": biz.business_name,
        "onboarding_status": prop.onboarding_status,
        "description": prop.description,
        "subscription": {
            "plan": sub.plan if sub else None,
            "status": sub.status if sub else None,
            "expiry": str(sub.expiry_date) if sub else None,
        }
    }
