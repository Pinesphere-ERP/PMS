import uuid
from datetime import datetime, date, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, delete
from sqlalchemy.exc import IntegrityError

from app.infra.database import get_db, provision_tenant_schema
from app.infra.models import Owner, Business, Property, User, Role, Subscription, StaffInvitation
from app.core.security import get_password_hash
from app.modules.onboarding.schemas import (
    OwnerRegistrationRequest, OwnerRegistrationResponse,
    AcceptInviteRequest, AcceptInviteResponse,
)
from app.modules.audit.logger import AuditLogger
from app.core.dependencies import get_current_user, require_super_admin
from app.core.limiter import limiter
from fastapi import Request

router = APIRouter()

@router.post("/register", response_model=OwnerRegistrationResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register_owner(request: Request, payload: OwnerRegistrationRequest, background_tasks: BackgroundTasks, db: AsyncSession = Depends(get_db)):
    """
    Public endpoint for self-service owner registration and property creation.
    """
    # 1. Check if owner with email or mobile already exists
    owner_stmt = select(Owner).where(
        or_(Owner.email == payload.email, Owner.mobile_number == payload.mobile_number)
    )
    existing_owner = (await db.execute(owner_stmt)).scalar_one_or_none()
    
    if existing_owner:
        raise HTTPException(status_code=400, detail="An owner with this email or mobile number already exists.")

    # 2. Check if User with email already exists
    user_stmt = select(User).where(User.email == payload.email)
    existing_user = (await db.execute(user_stmt)).scalar_one_or_none()
    if existing_user:
        raise HTTPException(status_code=400, detail="A user with this email already exists.")

    try:
        # Create Owner
        owner_id = uuid.uuid4()
        new_owner = Owner(
            owner_id=owner_id,
            full_name=payload.owner_name,
            email=payload.email,
            mobile_number=payload.mobile_number,
            email_verified=False,
            mobile_verified=False
        )
        db.add(new_owner)
        await db.flush()

        # Create Business
        business_id = uuid.uuid4()
        new_business = Business(
            business_id=business_id,
            owner_id=owner_id,
            business_name=payload.business_name
        )
        db.add(new_business)
        await db.flush()

        # Create Property
        property_id = uuid.uuid4()
        new_property = Property(
            property_id=property_id,
            business_id=business_id,
            owner_id=owner_id,
            property_name=payload.property_name,
            property_type=payload.property_type,
            star_category=payload.star_category,
            year_established=datetime.now().year,
            onboarding_status="pending_approval"  # Requires Super Admin approval
        )
        db.add(new_property)
        await db.flush()

        # Provision Tenant Schema
        background_tasks.add_task(provision_tenant_schema, str(property_id))

        # Get or Create OWNER Role
        role_stmt = select(Role).where(Role.role_code == "OWNER")
        owner_role = (await db.execute(role_stmt)).scalar_one_or_none()
        if not owner_role:
            owner_role = Role(
                id=uuid.uuid4(),
                role_code="OWNER",
                role_name="Property Owner",
                is_system_role=True,
                description="Default role for Property Owners"
            )
            db.add(owner_role)
            await db.flush()

        # Create User for the Owner
        user_id = uuid.uuid4()
        new_user = User(
            id=user_id,
            email=payload.email,
            mobile_number=payload.mobile_number,
            password_hash=get_password_hash(payload.password),
            name=payload.owner_name,
            role_id=owner_role.id,
            property_id=property_id,
            status="ACTIVE",
            is_primary_owner=True
        )
        db.add(new_user)
        await db.flush()

        # Create a 14-day Trial subscription automatically
        trial_expiry = date.today() + timedelta(days=14)
        trial_sub = Subscription(
            id=uuid.uuid4(),
            property_id=property_id,
            plan="Trial",
            billing_cycle="trial",
            start_date=date.today(),
            expiry_date=trial_expiry,
            status="Trial",
            device_limit=3,
            registered_devices=0,
            subscription_required=False,  # Trial doesn't gate access
        )
        db.add(trial_sub)
        await db.flush()

        await AuditLogger.log(
            db,
            module_name="onboarding",
            action_type="owner_registered",
            target_entity="owner",
            target_record_id=owner_id,
            user_id=user_id,
            new_value={"email": payload.email, "property_id": str(property_id)},
        )

        # Commit everything
        await db.commit()

        return OwnerRegistrationResponse(
            success=True,
            message="Registration successful. Your property is under review. You may use the trial period while awaiting approval.",
            owner_id=str(owner_id),
            property_id=str(property_id),
            user_id=str(user_id),
            onboarding_status="pending_approval",
            trial_days=14,
        )

    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

@router.post("/seed_roles")
async def seed_roles(db: AsyncSession = Depends(get_db)):
    # Cleanup old incorrect roles
    await db.execute(delete(Role).where(Role.role_code.in_(["FRONT_DESK", "RESTAURANT", "VALET"])))

    roles = [
        {"role_code": "RECEPTIONIST", "role_name": "Receptionist", "description": "Handles guest check-ins and front desk operations"},
        {"role_code": "HOUSEKEEPING", "role_name": "Housekeeping", "description": "Manages room cleaning and status"},
        {"role_code": "MAINTENANCE", "role_name": "Maintenance", "description": "Handles repair and maintenance tasks"},
        {"role_code": "KITCHEN", "role_name": "Kitchen Staff", "description": "Manages dining and room service orders"},
        {"role_code": "MANAGER", "role_name": "Property Manager", "description": "Oversees daily operations"},
        {"role_code": "ACCOUNTANT", "role_name": "Accountant", "description": "Manages billing, invoicing, and finances"},
        {"role_code": "SECURITY", "role_name": "Security Guard", "description": "Monitors property security and visitor logs"},
        {"role_code": "BROKER", "role_name": "Broker", "description": "Manages guest acquisition and broker commissions"}
    ]
    created = 0
    for r in roles:
        stmt = select(Role).where(Role.role_code == r["role_code"])
        result = await db.execute(stmt)
        if not result.scalars().first():
            role = Role(
                id=uuid.uuid4(),
                role_code=r["role_code"],
                role_name=r["role_name"],
                is_system_role=True,
                description=r["description"]
            )
            db.add(role)
            created += 1
    await db.commit()
    return {"message": f"Seeded PRD roles. Added {created} new roles."}


# ──────────────────────────────────────────────────────────────────────────────
# POST /accept-invite — Invite-link flow (staff invited by owner)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/accept-invite", response_model=AcceptInviteResponse, status_code=status.HTTP_201_CREATED)
async def accept_invite(payload: AcceptInviteRequest, db: AsyncSession = Depends(get_db)):
    """Accept a staff invitation, set password + PIN, and activate the user account."""
    if payload.password != payload.confirm_password:
        raise HTTPException(status_code=400, detail="Passwords do not match.")

    invite_stmt = select(StaffInvitation).where(
        StaffInvitation.invitation_token == payload.invitation_token,
        StaffInvitation.status == "PENDING",
    )
    invite_res = await db.execute(invite_stmt)
    invite = invite_res.scalar_one_or_none()

    if not invite:
        raise HTTPException(status_code=404, detail="Invitation not found or already used.")

    if invite.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invitation has expired. Please ask the owner to resend.")

    # Find the pre-created user for this invite (matched by mobile + property)
    user_stmt = select(User).where(
        User.mobile_number == invite.mobile_number,
        User.property_id == invite.property_id,
        User.status == "INACTIVE",
    )
    user_res = await db.execute(user_stmt)
    user = user_res.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="No pending user account found for this invitation.")

    user.password_hash = get_password_hash(payload.password)
    user.pin_hash = get_password_hash(payload.pin)
    user.status = "ACTIVE"
    invite.status = "ACCEPTED"

    await AuditLogger.log(
        db,
        module_name="onboarding",
        action_type="invite_accepted",
        target_entity="user",
        target_record_id=user.id,
        user_id=user.id,
        property_id=invite.property_id,
    )
    await db.commit()

    return AcceptInviteResponse(
        success=True,
        message="Account activated. You can now log in with your credentials.",
        user_id=str(user.id),
    )


# ──────────────────────────────────────────────────────────────────────────────
# POST /properties/{property_id}/approve  (Super Admin only)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/properties/{property_id}/approve")
async def approve_property(
    property_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    """Super Admin approves a property. Transitions PENDING_APPROVAL → approved."""
    try:
        pid = uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property_id.")

    prop_res = await db.execute(select(Property).where(Property.property_id == pid))
    prop = prop_res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found.")

    if prop.onboarding_status not in ("pending_approval", "rejected"):
        raise HTTPException(
            status_code=400,
            detail=f"Property is in '{prop.onboarding_status}' state and cannot be approved.",
        )

    prop.onboarding_status = "approved"
    await AuditLogger.log(
        db,
        module_name="onboarding",
        action_type="property_approved",
        target_entity="property",
        target_record_id=pid,
        user_id=current_user.id,
    )
    await db.commit()
    return {"message": "Property approved successfully.", "onboarding_status": "approved"}


# ──────────────────────────────────────────────────────────────────────────────
# POST /properties/{property_id}/reject  (Super Admin only)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/properties/{property_id}/reject")
async def reject_property(
    property_id: str,
    payload: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_super_admin),
):
    """Super Admin rejects a property with a reason. Transitions PENDING_APPROVAL → rejected."""
    try:
        pid = uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property_id.")

    prop_res = await db.execute(select(Property).where(Property.property_id == pid))
    prop = prop_res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found.")

    reason = payload.get("reason", "No reason provided.")
    prop.onboarding_status = "rejected"
    await AuditLogger.log(
        db,
        module_name="onboarding",
        action_type="property_rejected",
        target_entity="property",
        target_record_id=pid,
        user_id=current_user.id,
        new_value={"reason": reason},
    )
    await db.commit()
    return {"message": "Property rejected.", "onboarding_status": "rejected", "reason": reason}


# ──────────────────────────────────────────────────────────────────────────────
# POST /properties/{property_id}/go-live  (Owner only — post approval + subscription)
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/properties/{property_id}/go-live")
async def go_live(
    property_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Transitions an approved property to 'live' state after confirming active subscription."""
    try:
        pid = uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property_id.")

    prop_res = await db.execute(select(Property).where(Property.property_id == pid))
    prop = prop_res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found.")

    if prop.onboarding_status != "approved":
        raise HTTPException(
            status_code=400,
            detail=f"Property must be in 'approved' state to go live. Current: '{prop.onboarding_status}'.",
        )

    # Verify an active or trial subscription exists
    sub_res = await db.execute(
        select(Subscription)
        .where(Subscription.property_id == pid)
        .order_by(Subscription.expiry_date.desc())
    )
    sub = sub_res.scalars().first()
    if not sub or sub.status not in ("Active", "active", "Trial"):
        raise HTTPException(
            status_code=402,
            detail="An active subscription or trial is required to go live.",
        )

    prop.onboarding_status = "live"
    await AuditLogger.log(
        db,
        module_name="onboarding",
        action_type="property_went_live",
        target_entity="property",
        target_record_id=pid,
        user_id=current_user.id,
    )
    await db.commit()
    return {"message": "Property is now live!", "onboarding_status": "live"}
