"""
Seed router — call POST /api/v1/seed to insert all mock data.
Only available in development. Remove or guard with auth in production.
"""
import uuid
from datetime import date, timedelta, datetime
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.database import get_db
from app.infra.models import (
    Owner, Business, Property, Role, User, Device,
    RoomCategory, Room, Guest, Subscription, Invoice,
    PaymentTransaction, PendingDue, AuditLog
)
from app.modules.seed.audit_test_seed import main as run_audit_seed

router = APIRouter()

def uid(): return uuid.uuid4()
today = date.today()

PLAN_PRICE = {"Basic": 199.0, "Professional": 499.0, "Enterprise": 999.0}


@router.post("")
async def run_seed(db: AsyncSession = Depends(get_db)):
    """Insert realistic mock data into all tables. Safe to call multiple times — checks existing data first."""

    # Guard: skip if data already exists
    existing = await db.execute(select(Owner))
    if existing.scalars().first():
        return {"message": "Database already seeded. No changes made."}

    # ── Owners ────────────────────────────────────────────────────────────────
    owner_data = [
        dict(owner_id=uid(), full_name="Rajesh Kumar", designation="Owner",
             mobile_number="9876543210", email="rajesh@grandplaza.com",
             mobile_verified=True, email_verified=True, pan_number="AABCP1234C"),
        dict(owner_id=uid(), full_name="Priya Sharma", designation="Managing Director",
             mobile_number="9876543211", email="priya@seaview.com",
             mobile_verified=True, email_verified=True, pan_number="BBBCP2234C"),
        dict(owner_id=uid(), full_name="Amit Patel", designation="Owner",
             mobile_number="9876543212", email="amit@mountaininn.com",
             mobile_verified=True, email_verified=False, pan_number="CCCCP3334C"),
        dict(owner_id=uid(), full_name="Sunita Devi", designation="Director",
             mobile_number="9876543213", email="sunita@citylights.com",
             mobile_verified=False, email_verified=False),
        dict(owner_id=uid(), full_name="Mohammed Ali", designation="Owner",
             mobile_number="9876543214", email="mali@sunsetresort.com",
             mobile_verified=True, email_verified=True, pan_number="DDDCP4434C"),
        dict(owner_id=uid(), full_name="Kavitha Nair", designation="Partner",
             mobile_number="9876543215", email="kavitha@lakeside.com",
             mobile_verified=True, email_verified=True, pan_number="EEECP5534C"),
    ]
    owner_objs = [Owner(**o) for o in owner_data]
    db.add_all(owner_objs)
    await db.flush()

    # ── Businesses ────────────────────────────────────────────────────────────
    biz_names = [
        "Grand Plaza Hospitality Pvt Ltd", "Sea View Hotels Ltd",
        "Mountain Inn & Resorts", "City Lights Hospitality",
        "Sunset Resorts Group", "Lakeside Retreats",
    ]
    business_objs = []
    for i, owner in enumerate(owner_objs):
        b = Business(
            business_id=uid(), owner_id=owner.owner_id,
            business_name=biz_names[i], business_type="Hotel",
            gst_number=f"27AABCP{1000+i}C1Z{i}",
            pan_number=owner_data[i].get("pan_number"),
        )
        business_objs.append(b)
    db.add_all(business_objs)
    await db.flush()

    # ── Properties ────────────────────────────────────────────────────────────
    prop_configs = [
        ("Grand Plaza Hotel", "Hotel", "completed"),
        ("Sea View Resort", "Resort", "completed"),
        ("Mountain Inn", "Inn", "completed"),
        ("City Lights Hostel", "Hostel", "draft"),
        ("Sunset Villa", "Villa", "completed"),
        ("Lakeside Cabins", "Guesthouse", "completed"),
    ]
    property_objs = []
    for i, (name, ptype, status) in enumerate(prop_configs):
        p = Property(
            property_id=uid(),
            business_id=business_objs[i].business_id,
            owner_id=owner_objs[i].owner_id,
            property_name=name,
            property_type=ptype,
            star_category=4 if i < 3 else 3,
            total_floors=6 + i,
            total_rooms=20 + (i * 10),
            whatsapp_number=owner_data[i]["mobile_number"],
            onboarding_status=status,
            description=f"A premium {ptype.lower()} property managed via Pinesphere."
        )
        property_objs.append(p)
    db.add_all(property_objs)
    await db.flush()

    # ── Role ──────────────────────────────────────────────────────────────────
    front_desk_role = Role(
        id=uid(), property_id=None,
        role_code="FRONT_DESK", role_name="Front Desk Staff",
        is_system_role=True, description="Front desk operations"
    )
    db.add(front_desk_role)
    await db.flush()

    # ── Users ────────────────────────────────────────────────────────────────
    user_objs = []
    for i, prop in enumerate(property_objs):
        u = User(
            id=uid(), property_id=prop.property_id,
            role_id=front_desk_role.id,
            name=f"Staff - {owner_data[i]['full_name']}",
            mobile_number=f"8000{i:06d}",
            email=f"staff{i}@pinesphere.com",
            is_primary_owner=(i == 0),
            status="ACTIVE"
        )
        user_objs.append(u)
    db.add_all(user_objs)
    await db.flush()

    # ── Devices ────────────────────────────────────────────────────────────────
    device_statuses = ["active", "active", "pending_approval", "locked", "active", "active"]
    device_objs = []
    for i, prop in enumerate(property_objs):
        d = Device(
            id=uid(),
            device_uid=f"DEV-{1000+i:04d}-{str(prop.property_id).replace('-','')[:8].upper()}",
            property_id=prop.property_id,
            primary_user_id=user_objs[i].id,
            device_name=f"Tablet-{prop.property_name[:8].replace(' ','-')}",
            os_type="android",
            status=device_statuses[i]
        )
        device_objs.append(d)
    db.add_all(device_objs)
    await db.flush()

    # ── Room Categories + Rooms ───────────────────────────────────────────────
    for prop in property_objs:
        cat = RoomCategory(
            room_category_id=uid(), property_id=prop.property_id,
            room_name="Standard Room", number_of_rooms=10, base_price=2500.0
        )
        db.add(cat)
        await db.flush()
        for j in range(1, 6):
            db.add(Room(
                room_id=uid(), room_category_id=cat.room_category_id,
                room_number=f"{j:02d}", housekeeping_status="clean", occupancy_status="vacant"
            ))

    # ── Subscriptions ─────────────────────────────────────────────────────────
    plan_configs = [
        ("Basic", "Monthly", "Active"),
        ("Professional", "Monthly", "Active"),
        ("Enterprise", "Annual", "Active"),
        ("Basic", "Monthly", "Disabled"),
        ("Professional", "Quarterly", "Active"),
        ("Enterprise", "Annual", "Grace Period"),
    ]
    sub_objs = []
    for i, prop in enumerate(property_objs):
        plan, cycle, status = plan_configs[i]
        start = today - timedelta(days=30 * (i + 1))
        expiry = start + timedelta(days=365 if cycle == "Annual" else 30)
        if status == "Grace Period":
            expiry = today - timedelta(days=3)
        sub = Subscription(
            id=uid(), property_id=prop.property_id,
            plan=plan, billing_cycle=cycle,
            start_date=start, expiry_date=expiry,
            status=status,
            license_id=f"PSL-{2025000+i:07d}",
            device_limit=5 if plan == "Basic" else 10,
            registered_devices=1
        )
        sub_objs.append(sub)
    db.add_all(sub_objs)
    await db.flush()

    # ── Invoices ──────────────────────────────────────────────────────────────
    inv_statuses = ["Paid", "Paid", "Paid", "Overdue", "Pending", "Pending"]
    invoice_objs = []
    for i, sub in enumerate(sub_objs):
        amt = PLAN_PRICE[sub.plan]
        inv = Invoice(
            invoice_id=uid(),
            invoice_number=f"INV-2025-{1000+i:04d}",
            property_id=sub.property_id,
            plan=sub.plan,
            date=sub.start_date,
            due_date=sub.start_date + timedelta(days=7),
            amount=amt,
            gst=round(amt * 0.18, 2),
            status=inv_statuses[i]
        )
        invoice_objs.append(inv)
    db.add_all(invoice_objs)
    await db.flush()

    # ── Payment Transactions ──────────────────────────────────────────────────
    methods = ["UPI", "Net Banking", "Credit Card", "UPI"]
    tx_statuses = ["Success", "Success", "Success", "Failed"]
    for i in range(4):
        amt = PLAN_PRICE[sub_objs[i].plan]
        db.add(PaymentTransaction(
            id=uid(),
            payment_id=f"PAY-{9000000+i:08d}",
            invoice_id=invoice_objs[i].invoice_id,
            property_id=invoice_objs[i].property_id,
            amount=amt + round(amt * 0.18, 2),
            method=methods[i],
            status=tx_statuses[i],
            bank_ref=f"REF{8000000+i:08d}" if tx_statuses[i] == "Success" else None
        ))

    # ── Pending Dues ──────────────────────────────────────────────────────────
    for sub in sub_objs:
        if sub.status in ("Grace Period", "Disabled"):
            amt = PLAN_PRICE[sub.plan]
            db.add(PendingDue(
                id=uid(), property_id=sub.property_id, plan=sub.plan,
                due_date=sub.expiry_date,
                amount_due=amt + round(amt * 0.18, 2),
                days_overdue=max(0, (today - sub.expiry_date).days),
                reminder_status="2 Reminders Sent"
            ))

    # ── Audit Logs (with proper hash chain) ───────────────────────────────────
    from app.modules.audit.service import _compute_entry_hash, GENESIS_HASH

    audit_actions = [
        ("Property Added", "PROPERTY"),
        ("Verification Approved", "PROPERTY"),
        ("Subscription Renewed", "SUBSCRIPTION"),
        ("Payment Received", "PAYMENT"),
        ("Device Registered", "DEVICE"),
        ("Plan Upgraded", "SUBSCRIPTION"),
    ]
    prev_hash = GENESIS_HASH
    for i, (action, module) in enumerate(audit_actions):
        ts = datetime.utcnow() - timedelta(hours=i * 4)
        new_val = {"status": "updated"}
        entry_hash = _compute_entry_hash(prev_hash, ts, None, action, new_val, None)
        db.add(AuditLog(
            log_id=uid(),
            property_id=property_objs[i % len(property_objs)].property_id,
            timestamp=ts,
            module_name=module,
            action_type=action,
            target_entity=module,
            target_record_id=property_objs[i % len(property_objs)].property_id,
            new_value_snapshot=new_val,
            previous_log_hash=prev_hash,
            entry_hash=entry_hash,
        ))
        prev_hash = entry_hash

    return {
        "message": "✅ Seed complete!",
        "summary": {
            "owners": len(owner_objs),
            "businesses": len(business_objs),
            "properties": len(property_objs),
            "subscriptions": len(sub_objs),
            "invoices": len(invoice_objs),
            "devices": len(device_objs),
        }
    }


@router.post("/audit-test")
async def seed_audit_test_data(db: AsyncSession = Depends(get_db)):
    """
    Seed comprehensive booking workflows that generate a full audit trail
    with proper SHA-256 hash chains. Creates:
      - 5 bookings, 2 updates, 1 cancel
      - 3 check-ins, 2 check-outs, 1 check-in cancel
      - 12+ audit log entries with verified hash chain

    Safe to call multiple times (checks existing data first).
    """
    from app.modules.seed.audit_test_seed import (
        PROPERTY_ID, main as _run_audit_seed,
    )

    # Guard: skip if the test property already exists
    existing = await db.execute(
        select(Property).where(Property.property_id == PROPERTY_ID)
    )
    if existing.scalar_one_or_none():
        return {"message": "Audit test data already seeded. No changes made."}

    await _run_audit_seed()
    return {
        "message": "✅ Audit test seed complete!",
        "property_id": str(PROPERTY_ID),
        "details": {
            "bookings_created": 5,
            "bookings_updated": 2,
            "bookings_cancelled": 1,
            "check_ins_performed": 3,
            "check_outs_performed": 2,
            "check_ins_cancelled": 1,
            "expected_audit_entries": 12,
        },
        "endpoints": {
            "list_all_logs": f"/api/v1/audit/?property_id={PROPERTY_ID}",
            "filter_by_bookings": f"/api/v1/audit/?property_id={PROPERTY_ID}&module_name=bookings",
            "filter_by_checkin": f"/api/v1/audit/?property_id={PROPERTY_ID}&module_name=checkin",
            "filter_by_checkout": f"/api/v1/audit/?property_id={PROPERTY_ID}&module_name=checkout",
            "verify_chain": f"/api/v1/audit/verify?property_id={PROPERTY_ID}",
        },
    }
