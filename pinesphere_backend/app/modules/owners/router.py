import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, require_super_admin
from app.infra.database import get_db
from app.infra.models import Owner, Property, User
from app.modules.audit.logger import AuditLogger
from app.modules.owners.schemas import OwnerCreateRequest, OwnerResponse, OwnerUpdateRequest

router = APIRouter()


@router.get("", response_model=List[OwnerResponse])
async def list_owners(
    _: User = Depends(require_super_admin),
    db: AsyncSession = Depends(get_db),
):
    """List all owners with their property count. Super Admin only."""
    # Count properties per owner
    count_stmt = (
        select(Property.owner_id, func.count(Property.property_id).label("prop_count"))
        .group_by(Property.owner_id)
        .subquery()
    )
    stmt = (
        select(Owner, func.coalesce(count_stmt.c.prop_count, 0).label("property_count"))
        .outerjoin(count_stmt, Owner.owner_id == count_stmt.c.owner_id)
        .order_by(Owner.created_at.desc())
    )
    result = await db.execute(stmt)
    rows = result.all()

    owners = []
    for owner, prop_count in rows:
        owners.append(
            OwnerResponse(
                owner_id=owner.owner_id,
                full_name=owner.full_name,
                mobile_number=owner.mobile_number,
                email=owner.email,
                designation=owner.designation,
                pan_number=owner.pan_number,
                aadhaar_number=owner.aadhaar_number,
                alternate_contact=owner.alternate_contact,
                property_count=prop_count or 0,
            )
        )
    return owners


@router.post("", response_model=OwnerResponse, status_code=status.HTTP_201_CREATED)
async def create_owner(
    payload: OwnerCreateRequest,
    current_user: User = Depends(require_super_admin),
    db: AsyncSession = Depends(get_db),
):
    """Create a standalone Owner entity (no property required). Super Admin only."""
    # Check for duplicate email
    dup_email = (
        await db.execute(select(Owner).where(Owner.email == payload.email))
    ).scalar_one_or_none()
    if dup_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An owner with this email already exists.",
        )

    # Check for duplicate mobile
    dup_mobile = (
        await db.execute(
            select(Owner).where(Owner.mobile_number == payload.mobile_number)
        )
    ).scalar_one_or_none()
    if dup_mobile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An owner with this mobile number already exists.",
        )

    owner = Owner(
        owner_id=uuid.uuid4(),
        full_name=payload.full_name,
        mobile_number=payload.mobile_number,
        email=payload.email,
        designation=payload.designation,
        pan_number=payload.pan_number,
        aadhaar_number=payload.aadhaar_number,
        alternate_contact=payload.alternate_contact,
    )
    db.add(owner)
    await db.flush()

    await AuditLogger.log(
        db,
        module_name="ownerManagement",
        action_type="owner_create",
        target_entity="owner",
        target_record_id=owner.owner_id,
        user_id=current_user.id,
        new_value={"full_name": owner.full_name, "email": owner.email},
    )

    await db.commit()
    await db.refresh(owner)

    return OwnerResponse(
        owner_id=owner.owner_id,
        full_name=owner.full_name,
        mobile_number=owner.mobile_number,
        email=owner.email,
        designation=owner.designation,
        pan_number=owner.pan_number,
        aadhaar_number=owner.aadhaar_number,
        alternate_contact=owner.alternate_contact,
        property_count=0,
    )


@router.get("/{owner_id}", response_model=OwnerResponse)
async def get_owner(
    owner_id: uuid.UUID,
    _: User = Depends(require_super_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get owner details with their property count."""
    owner = (
        await db.execute(select(Owner).where(Owner.owner_id == owner_id))
    ).scalar_one_or_none()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    prop_count_res = await db.execute(
        select(func.count(Property.property_id)).where(
            Property.owner_id == owner_id
        )
    )
    prop_count = prop_count_res.scalar() or 0

    return OwnerResponse(
        owner_id=owner.owner_id,
        full_name=owner.full_name,
        mobile_number=owner.mobile_number,
        email=owner.email,
        designation=owner.designation,
        pan_number=owner.pan_number,
        aadhaar_number=owner.aadhaar_number,
        alternate_contact=owner.alternate_contact,
        property_count=prop_count,
    )


@router.patch("/{owner_id}", response_model=OwnerResponse)
async def update_owner(
    owner_id: uuid.UUID,
    payload: OwnerUpdateRequest,
    current_user: User = Depends(require_super_admin),
    db: AsyncSession = Depends(get_db),
):
    """Update owner profile details. Super Admin only."""
    owner = (
        await db.execute(select(Owner).where(Owner.owner_id == owner_id))
    ).scalar_one_or_none()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    for field in ("full_name", "mobile_number", "email", "designation", "pan_number", "aadhaar_number", "alternate_contact"):
        value = getattr(payload, field)
        if value is not None:
            setattr(owner, field, value)

    await AuditLogger.log(
        db,
        module_name="ownerManagement",
        action_type="owner_update",
        target_entity="owner",
        target_record_id=owner.owner_id,
        user_id=current_user.id,
    )

    await db.commit()
    await db.refresh(owner)

    prop_count_res = await db.execute(
        select(func.count(Property.property_id)).where(
            Property.owner_id == owner_id
        )
    )
    prop_count = prop_count_res.scalar() or 0

    return OwnerResponse(
        owner_id=owner.owner_id,
        full_name=owner.full_name,
        mobile_number=owner.mobile_number,
        email=owner.email,
        designation=owner.designation,
        pan_number=owner.pan_number,
        aadhaar_number=owner.aadhaar_number,
        alternate_contact=owner.alternate_contact,
        property_count=prop_count,
    )


@router.get("/{owner_id}/properties")
async def get_owner_properties(
    owner_id: uuid.UUID,
    _: User = Depends(require_super_admin),
    db: AsyncSession = Depends(get_db),
):
    """Return all properties belonging to this owner."""
    owner = (
        await db.execute(select(Owner).where(Owner.owner_id == owner_id))
    ).scalar_one_or_none()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    props = (
        await db.execute(
            select(Property).where(Property.owner_id == owner_id)
        )
    ).scalars().all()

    return [
        {
            "property_id": str(p.property_id),
            "property_name": p.property_name,
            "property_type": p.property_type,
            "city": p.city,
            "total_rooms": p.total_rooms,
            "onboarding_status": p.onboarding_status,
        }
        for p in props
    ]
