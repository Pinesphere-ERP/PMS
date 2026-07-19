import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from sqlalchemy.exc import IntegrityError

from app.infra.database import get_db, provision_tenant_schema
from app.infra.models import Owner, Business, Property, User, Role
from app.core.security import get_password_hash
from app.modules.onboarding.schemas import OwnerRegistrationRequest, OwnerRegistrationResponse
from app.modules.audit.logger import AuditLogger

router = APIRouter()

@router.post("/register", response_model=OwnerRegistrationResponse, status_code=status.HTTP_201_CREATED)
async def register_owner(payload: OwnerRegistrationRequest, db: AsyncSession = Depends(get_db)):
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
            status="Active" # Make active so they can log in immediately
        )
        db.add(new_property)
        await db.flush()

        # Provision Tenant Schema
        await provision_tenant_schema(db, str(property_id))

        # Get or Create OWNER Role
        role_stmt = select(Role).where(Role.role_code == "OWNER")
        owner_role = (await db.execute(role_stmt)).scalar_one_or_none()
        if not owner_role:
            owner_role = Role(
                id=uuid.uuid4(),
                role_code="OWNER",
                role_name="Property Owner",
                is_system_role=True,
                is_hotel_role=True,
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

        # Commit everything
        await db.commit()

        return OwnerRegistrationResponse(
            success=True,
            message="Registration successful. You can now log in.",
            owner_id=str(owner_id),
            property_id=str(property_id),
            user_id=str(user_id)
        )

    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")
