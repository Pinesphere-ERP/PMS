import re

ROUTER_PATH = r"c:\projects\PMS\pinesphere_backend\app\modules\portal\router.py"

with open(ROUTER_PATH, "r", encoding="utf-8") as f:
    content = f.read()

# Add new schemas to import
schemas_import_pattern = r"from app\.modules\.portal\.schemas import \("
schemas_replacement = """from app.modules.portal.schemas import (
    GuestFeedbackCreate, GuestFeedbackResponse, PortalComplaintCreate,"""
content = re.sub(schemas_import_pattern, schemas_replacement, content, count=1)

# Add require_can_submit_feedback dependency import if not present
# Wait, it's actually defined IN router.py! Let's check if it is defined. Yes, I saw it in grep: "async def require_can_submit_feedback..."

new_block = """# ── Phase 4D: Guest Feedback & Ratings ────────────────────────────────────────

@router.post("/feedback", response_model=GuestFeedbackResponse)
async def submit_guest_feedback(
    payload: GuestFeedbackCreate,
    booking: Booking = Depends(require_can_submit_feedback),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import GuestFeedback
    
    # Check if a feedback already exists for this booking (and task_id)
    stmt = select(GuestFeedback).where(
        GuestFeedback.booking_id == booking.booking_id
    )
    if payload.task_id:
        stmt = stmt.where(GuestFeedback.task_id == payload.task_id)
    else:
        stmt = stmt.where(GuestFeedback.task_id.is_(None))
        
    res = await db.execute(stmt)
    existing = res.scalars().first()
    
    if existing:
        # Update existing feedback
        if payload.overall_rating is not None: existing.overall_rating = payload.overall_rating
        if payload.food_rating is not None: existing.food_rating = payload.food_rating
        if payload.service_rating is not None: existing.service_rating = payload.service_rating
        if payload.staff_rating is not None: existing.staff_rating = payload.staff_rating
        if payload.comments is not None: existing.comments = payload.comments
        existing.is_anonymous = payload.is_anonymous
        await db.flush()
        return existing
        
    # Create new feedback
    new_feedback = GuestFeedback(
        id=uuid.uuid4(),
        property_id=booking.property_id,
        booking_id=booking.booking_id,
        guest_id=booking.guest_id if not payload.is_anonymous else None,
        task_id=payload.task_id,
        overall_rating=payload.overall_rating,
        food_rating=payload.food_rating,
        service_rating=payload.service_rating,
        staff_rating=payload.staff_rating,
        comments=payload.comments,
        is_anonymous=payload.is_anonymous
    )
    db.add(new_feedback)
    await db.flush()
    return new_feedback

@router.get("/feedback", response_model=List[GuestFeedbackResponse])
async def get_guest_feedback(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import GuestFeedback
    stmt = select(GuestFeedback).where(
        GuestFeedback.booking_id == booking.booking_id,
        GuestFeedback.is_deleted == False
    ).order_by(GuestFeedback.created_at.desc())
    res = await db.execute(stmt)
    return res.scalars().all()

@router.post("/complaints")
async def create_portal_complaint(
    payload: PortalComplaintCreate,
    booking: Booking = Depends(require_can_submit_feedback),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task, TaskLog
    
    task_id = uuid.uuid4()
    task = Task(
        task_id=task_id,
        property_id=booking.property_id,
        task_type="complaint",
        status="pending",
        priority="high",
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        description=payload.description,
    )
    db.add(task)
    
    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=task_id,
        old_status=None,
        new_status="pending",
        notes="Guest submitted a complaint via portal"
    )
    db.add(log)
    
    await db.commit()
    
    return {
        "status": "success",
        "task_id": str(task_id),
        "message": "Complaint registered successfully."
    }

@router.get("/complaints")
async def get_portal_complaints(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task
    stmt = select(Task).where(
        Task.booking_id == booking.booking_id,
        Task.task_type == 'complaint'
    ).order_by(Task.created_at.desc())
    res = await db.execute(stmt)
    tasks = res.scalars().all()
    
    return [
        {
            "task_id": t.task_id,
            "status": t.status,
            "description": t.description,
            "created_at": t.created_at
        } for t in tasks
    ]
"""

content = content + "\n\n" + new_block

with open(ROUTER_PATH, "w", encoding="utf-8") as f:
    f.write(content)

print("Router patched with feedback APIs successfully.")
