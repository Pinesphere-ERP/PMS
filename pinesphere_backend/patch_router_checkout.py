import re

ROUTER_PATH = r"c:\projects\PMS\pinesphere_backend\app\modules\portal\router.py"

with open(ROUTER_PATH, "r", encoding="utf-8") as f:
    content = f.read()

schemas_import_pattern = r"from app\.modules\.portal\.schemas import \("
schemas_replacement = """from app.modules.portal.schemas import (
    PortalCheckoutStatusResponse,"""
content = re.sub(schemas_import_pattern, schemas_replacement, content, count=1)

new_block = """
# ── Phase 5: Checkout Lifecycle ───────────────────────────────────────────────

@router.get("/checkout/status", response_model=PortalCheckoutStatusResponse)
async def get_checkout_status(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task, CheckOut, FolioLineItem, Payment
    
    # Calculate Balance
    fl_stmt = select(FolioLineItem).where(FolioLineItem.booking_id == booking.booking_id, FolioLineItem.is_void == False)
    fl_res = await db.execute(fl_stmt)
    total_charges = sum(float(i.amount) for i in fl_res.scalars())
    
    pay_stmt = select(Payment).where(Payment.booking_id == booking.booking_id, Payment.is_void == False)
    pay_res = await db.execute(pay_stmt)
    total_paid = sum(float(p.amount) for p in pay_res.scalars())
    
    balance = round(total_charges - total_paid, 2)
    
    # Check if a checkout request task is pending
    task_stmt = select(Task).where(
        Task.booking_id == booking.booking_id,
        Task.task_type == 'checkout_request',
        Task.status.notin_(['completed', 'closed', 'cancelled'])
    )
    task_res = await db.execute(task_stmt)
    pending_task = task_res.scalars().first()
    
    # State evaluation
    from app.modules.portal.access_service import PortalAccessService
    
    if booking.booking_status == "completed":
        co_stmt = select(CheckOut).where(CheckOut.booking_id == booking.booking_id).order_by(CheckOut.created_at.desc())
        co_res = await db.execute(co_stmt)
        checkout = co_res.scalars().first()
        
        if PortalAccessService._is_in_grace_window(checkout):
            ct = checkout.checkout_time
            if ct.tzinfo is None:
                ct = ct.replace(tzinfo=timezone.utc)
            grace_ends = ct + timedelta(hours=PortalAccessService.GRACE_WINDOW_HOURS)
            return {
                "state": "COMPLETED",
                "balance": balance,
                "checkout_task_id": None,
                "grace_period_ends_at": grace_ends
            }
        else:
            return {
                "state": "REVOKED",
                "balance": balance,
                "checkout_task_id": None,
                "grace_period_ends_at": None
            }
            
    if pending_task:
        return {
            "state": "REQUESTED",
            "balance": balance,
            "checkout_task_id": pending_task.task_id,
            "grace_period_ends_at": None
        }
        
    return {
        "state": "ACTIVE",
        "balance": balance,
        "checkout_task_id": None,
        "grace_period_ends_at": None
    }

@router.post("/checkout/request")
async def request_checkout(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task, TaskLog
    
    if booking.booking_status != "checked_in":
        raise HTTPException(status_code=400, detail="Cannot request checkout. Stay is not active.")
        
    # Check idempotency
    stmt = select(Task).where(
        Task.booking_id == booking.booking_id,
        Task.task_type == 'checkout_request',
        Task.status.notin_(['completed', 'closed', 'cancelled'])
    )
    res = await db.execute(stmt)
    if res.scalars().first():
        return {"status": "success", "message": "Checkout already requested."}
        
    task_id = uuid.uuid4()
    task = Task(
        task_id=task_id,
        property_id=booking.property_id,
        task_type="checkout_request",
        status="pending",
        priority="high",
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        description="Guest requested express checkout via Portal.",
    )
    db.add(task)
    
    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=task_id,
        old_status=None,
        new_status="pending",
        notes="Checkout requested by Guest"
    )
    db.add(log)
    
    await db.commit()
    
    return {"status": "success", "task_id": str(task_id)}
"""

content = content + "\n\n" + new_block

with open(ROUTER_PATH, "w", encoding="utf-8") as f:
    f.write(content)

print("Router patched with checkout APIs successfully.")
