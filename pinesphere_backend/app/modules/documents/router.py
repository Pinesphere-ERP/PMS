"""
Foreign Guest Compliance — documents + Form C / FRRO submission tracking.
"""
import uuid
from datetime import datetime, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.database import get_db
from app.infra.models import (
    GuestNationalityDocument, FormCRecord, FormCAmendment, Guest, Booking, User
)
from app.core.dependencies import get_current_user, assert_property_access

router = APIRouter()

# ──────────────────────────────────────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────────────────────────────────────

class NationalityDocCreate(BaseModel):
    guest_id: uuid.UUID
    booking_id: Optional[uuid.UUID] = None
    property_id: uuid.UUID
    nationality: str
    passport_number: str
    passport_expiry: Optional[str] = None
    visa_number: Optional[str] = None
    visa_type: Optional[str] = None
    visa_expiry: Optional[str] = None
    port_of_arrival: Optional[str] = None
    arrival_date: Optional[str] = None
    document_front_url: Optional[str] = None
    document_back_url: Optional[str] = None

class FormCSubmitPayload(BaseModel):
    form_c_id: uuid.UUID
    property_id: uuid.UUID

class FormCAmendPayload(BaseModel):
    form_c_id: uuid.UUID
    property_id: uuid.UUID
    amendment_reason: str
    new_nationality: Optional[str] = None
    new_passport_number: Optional[str] = None
    new_visa_number: Optional[str] = None


# ──────────────────────────────────────────────────────────────────────────────
# Nationality Documents
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/nationality", status_code=status.HTTP_201_CREATED)
async def register_nationality_document(
    payload: NationalityDocCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Register passport/visa details for a foreign national guest."""
    await assert_property_access(payload.property_id, current_user, db)

    from datetime import date
    def _parse_date(s):
        if not s:
            return None
        try:
            return date.fromisoformat(s)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid date format: {s}. Use YYYY-MM-DD.")

    doc = GuestNationalityDocument(
        id=uuid.uuid4(),
        guest_id=payload.guest_id,
        booking_id=payload.booking_id,
        property_id=payload.property_id,
        nationality=payload.nationality,
        passport_number=payload.passport_number,
        passport_expiry=_parse_date(payload.passport_expiry),
        visa_number=payload.visa_number,
        visa_type=payload.visa_type,
        visa_expiry=_parse_date(payload.visa_expiry),
        port_of_arrival=payload.port_of_arrival,
        arrival_date=_parse_date(payload.arrival_date),
        document_front_url=payload.document_front_url,
        document_back_url=payload.document_back_url,
        verified=False,
    )
    db.add(doc)
    await db.commit()
    await db.refresh(doc)
    return {"id": str(doc.id), "message": "Nationality document registered successfully."}


@router.get("/nationality/{guest_id}")
async def get_nationality_documents(
    guest_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = select(GuestNationalityDocument).where(
        GuestNationalityDocument.guest_id == guest_id,
        GuestNationalityDocument.property_id == property_id,
    )
    result = await db.execute(stmt)
    docs = result.scalars().all()
    return [
        {
            "id": str(d.id),
            "nationality": d.nationality,
            "passport_number": d.passport_number,
            "passport_expiry": str(d.passport_expiry) if d.passport_expiry else None,
            "visa_number": d.visa_number,
            "visa_type": d.visa_type,
            "verified": d.verified,
        }
        for d in docs
    ]


@router.post("/nationality/{doc_id}/verify")
async def verify_nationality_document(
    doc_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Mark a nationality document as verified by staff."""
    await assert_property_access(property_id, current_user, db)
    stmt = select(GuestNationalityDocument).where(
        GuestNationalityDocument.id == doc_id,
        GuestNationalityDocument.property_id == property_id,
    )
    result = await db.execute(stmt)
    doc = result.scalars().first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    doc.verified = True
    doc.verified_at = datetime.utcnow()
    doc.verified_by = current_user.id
    await db.commit()
    return {"message": "Document verified."}


# ──────────────────────────────────────────────────────────────────────────────
# Form C Records
# ──────────────────────────────────────────────────────────────────────────────

async def create_form_c_on_checkin(
    db: AsyncSession,
    guest_id: uuid.UUID,
    booking_id: uuid.UUID,
    property_id: uuid.UUID,
    nationality_doc_id: Optional[uuid.UUID] = None,
) -> FormCRecord:
    """Called internally by check-in service when nationality != Indian."""
    record = FormCRecord(
        id=uuid.uuid4(),
        guest_id=guest_id,
        booking_id=booking_id,
        property_id=property_id,
        nationality_doc_id=nationality_doc_id,
        status="generated",
        deadline_at=datetime.utcnow() + timedelta(hours=24),
    )
    db.add(record)
    await db.flush()
    return record


@router.get("/form-c")
async def list_form_c_records(
    property_id: uuid.UUID = Query(...),
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List Form C records for a property with optional status filter."""
    await assert_property_access(property_id, current_user, db)
    stmt = select(FormCRecord).where(FormCRecord.property_id == property_id)
    if status_filter:
        stmt = stmt.where(FormCRecord.status == status_filter)
    stmt = stmt.order_by(FormCRecord.deadline_at.asc())
    result = await db.execute(stmt)
    records = result.scalars().all()
    now = datetime.utcnow()
    return [
        {
            "id": str(r.id),
            "guest_id": str(r.guest_id),
            "booking_id": str(r.booking_id),
            "status": r.status,
            "generated_at": r.generated_at.isoformat() if r.generated_at else None,
            "deadline_at": r.deadline_at.isoformat() if r.deadline_at else None,
            "hours_remaining": round((r.deadline_at - now).total_seconds() / 3600, 1) if r.deadline_at and r.deadline_at > now else 0,
            "submitted_at": r.submitted_at.isoformat() if r.submitted_at else None,
        }
        for r in records
    ]


@router.post("/form-c/submit")
async def submit_form_c(
    payload: FormCSubmitPayload,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Mark a Form C as submitted (cannot be undone; use amendments for corrections)."""
    await assert_property_access(payload.property_id, current_user, db)
    stmt = select(FormCRecord).where(
        FormCRecord.id == payload.form_c_id,
        FormCRecord.property_id == payload.property_id,
    )
    result = await db.execute(stmt)
    record = result.scalars().first()
    if not record:
        raise HTTPException(status_code=404, detail="Form C record not found")
    if record.status == "submitted":
        raise HTTPException(status_code=409, detail="Form C already submitted. Use the amendment endpoint for corrections.")
    record.status = "submitted"
    record.submitted_at = datetime.utcnow()
    record.submitted_by = current_user.id
    await db.commit()
    return {"message": "Form C submitted successfully.", "id": str(record.id)}


@router.post("/form-c/amend")
async def amend_form_c(
    payload: FormCAmendPayload,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create an amendment record for a submitted Form C (immutable append)."""
    await assert_property_access(payload.property_id, current_user, db)
    stmt = select(FormCRecord).where(FormCRecord.id == payload.form_c_id)
    result = await db.execute(stmt)
    record = result.scalars().first()
    if not record:
        raise HTTPException(status_code=404, detail="Form C not found")
    if record.status != "submitted":
        raise HTTPException(status_code=400, detail="Only submitted Form C records can be amended.")

    old_data = {
        "nationality_doc_id": str(record.nationality_doc_id) if record.nationality_doc_id else None,
        "status": record.status,
    }
    new_data = payload.model_dump(exclude_unset=True)

    amendment = FormCAmendment(
        id=uuid.uuid4(),
        form_c_id=record.id,
        amended_by=current_user.id,
        amendment_reason=payload.amendment_reason,
        old_data_json=old_data,
        new_data_json=new_data,
    )
    db.add(amendment)
    record.status = "amended"
    await db.commit()
    return {"message": "Amendment recorded.", "amendment_id": str(amendment.id)}


# ──────────────────────────────────────────────────────────────────────────────
# Deadline Alert Check (called by background task / Celery)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/form-c/check-deadlines", include_in_schema=False)
async def check_form_c_deadlines(db: AsyncSession = Depends(get_db)):
    """
    Internal endpoint for background tasks to mark overdue Form C records
    and trigger owner notifications. Call this every 30 minutes via cron.
    """
    now = datetime.utcnow()
    stmt = select(FormCRecord).where(
        FormCRecord.status == "generated",
        FormCRecord.deadline_at < now,
    )
    result = await db.execute(stmt)
    overdue_records = result.scalars().all()
    count = 0
    for record in overdue_records:
        record.status = "overdue"
        count += 1
    await db.commit()
    return {"marked_overdue": count}
