from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from sqlalchemy.future import select
from sqlalchemy import func, and_, or_
from datetime import date, timedelta
from typing import List, Optional

from app.infra.database import get_db, provision_tenant_schema
from app.core.dependencies import assert_property_access, get_current_user, require_room_access, require_super_admin, get_current_role
from app.infra.models import Property, Owner, Business, Subscription, AuditLog, Room, RoomCategory, User, Role
import uuid
from app.modules.properties.schemas import PropertyCreateInput
from app.modules.audit.logger import AuditLogger

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
async def create_property(payload: PropertyCreateInput, background_tasks: BackgroundTasks, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    role = await get_current_role(current_user, db)
    if role.role_code not in ["SUPER_ADMIN", "OWNER"]:
        raise HTTPException(status_code=403, detail="Not allowed to create properties")

    if role.role_code == "OWNER":
        payload.owner_user_id = str(current_user.id)

    owner_name = payload.owner_name
    owner_mobile = payload.owner_mobile
    owner_email = payload.owner_email
    target_user = None
    owner = None

    # ── Priority 1: Existing Owner linked by owner_id ──────────────────────────
    if payload.owner_id:
        try:
            oid = uuid.UUID(payload.owner_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid owner_id format")
        owner = (await db.execute(select(Owner).where(Owner.owner_id == oid))).scalar_one_or_none()
        if not owner:
            raise HTTPException(status_code=404, detail="Owner not found with provided owner_id")
        owner_name = owner.full_name
        owner_mobile = owner.mobile_number
        owner_email = owner.email

    # ── Priority 2: Existing User with OWNER role linked by owner_user_id ──────
    elif payload.owner_user_id:
        user_stmt = select(User, Role).join(Role, User.role_id == Role.id).where(User.id == uuid.UUID(payload.owner_user_id))
        user_res = await db.execute(user_stmt)
        row = user_res.first()
        if not row:
            raise HTTPException(status_code=404, detail="User not found")
        target_user, role = row
        if role.role_code != "OWNER":
            raise HTTPException(status_code=400, detail="Target user must have the OWNER role")
        owner_name = target_user.name
        owner_mobile = target_user.mobile_number or payload.owner_mobile
        owner_email = target_user.email or payload.owner_email

    # ── Priority 3: Create new Owner from inline details (backwards compat) ────
    if owner is None:
        if not owner_name or not owner_mobile or not owner_email:
            raise HTTPException(status_code=400, detail="Owner name, mobile, and email are required.")

        owner_result = await db.execute(
            select(Owner).where(
                or_(Owner.email == owner_email, Owner.mobile_number == owner_mobile)
            )
        )
        matching_owners = owner_result.scalars().all()
        if len(matching_owners) > 1:
            raise HTTPException(status_code=400, detail="Owner email and mobile number belong to different owners.")

        owner = matching_owners[0] if matching_owners else None
        if owner is None:
            owner = Owner(
                full_name=owner_name,
                mobile_number=owner_mobile,
                email=owner_email,
                pan_number=payload.owner_pan,
            )
            db.add(owner)
            await db.flush()

    # Create Business
    new_business = Business(
        owner_id=owner.owner_id,
        business_name=payload.business_name,
        business_reg_number=payload.business_reg_number,
        gst_number=payload.business_gst,
        pan_number=payload.business_pan,
    )
    db.add(new_business)
    await db.flush()

    new_property = Property(
        business_id=new_business.business_id,
        owner_id=owner.owner_id,
        property_name=payload.property_name,
        property_type=payload.property_type,
        star_category=payload.star_category,
        year_established=payload.year_established,
        total_floors=payload.total_floors,
        total_rooms=payload.total_rooms,
        description=payload.description,
        city=payload.city,
        cover_image=payload.cover_image,
        onboarding_status="draft",
    )
    db.add(new_property)
    await db.flush()

    # 1. Insert Property Address
    from app.infra.models import PropertyAddress, RoomType, RoomInventory, RoomPricing, Room, Amenity, RoomAmenity, select
    
    address = PropertyAddress(
        property_id=new_property.property_id,
        address=payload.address,
        city=payload.city,
        state=payload.state,
        country=payload.country,
        pincode=payload.pincode
    )
    db.add(address)
    await db.flush()

    if payload.rooms:
        for r in payload.rooms:
            # Create Room Type
            room_type = RoomType(
                property_id=new_property.property_id,
                name=r.get('name') or r.get('category') or 'Standard',
                category=r.get('category') or 'Standard',
                occupancy=int(r.get('occupancy') or 2),
                bed_type=r.get('bedType'),
                room_size=r.get('size'),
                smoking=bool(r.get('smoking')),
                balcony=bool(r.get('balcony')),
                view=r.get('view'),
                ac=bool(r.get('ac')),
                description=r.get('description', '')
            )
            db.add(room_type)
            await db.flush()
            
            # Create Room Inventory
            total_rooms = int(r.get('totalRooms') or 1)
            inventory = RoomInventory(
                room_type_id=room_type.id,
                total_rooms=total_rooms,
                available_rooms=total_rooms
            )
            db.add(inventory)
            
            # Create Room Pricing
            pricing = RoomPricing(
                room_type_id=room_type.id,
                base_price=float(r.get('basePrice') or r.get('price') or 1000.0),
                weekend_price=float(r.get('weekendPrice')) if r.get('weekendPrice') else None,
                extra_adult=float(r.get('extraAdult')) if r.get('extraAdult') else None,
                extra_child=float(r.get('extraChild')) if r.get('extraChild') else None,
                tax=str(r.get('taxPercent')) if r.get('taxPercent') else None,
                meal_plan=r.get('mealPlan')
            )
            db.add(pricing)
            
            # Create Amenities
            amenities_list = r.get('amenities') or []
            for am_name in amenities_list:
                stmt = select(Amenity).where(Amenity.name == am_name)
                res = await db.execute(stmt)
                am_obj = res.scalar_one_or_none()
                if not am_obj:
                    am_obj = Amenity(name=am_name, category='room')
                    db.add(am_obj)
                    await db.flush()
                ra = RoomAmenity(room_type_id=room_type.id, amenity_id=am_obj.id)
                db.add(ra)
            
            # Create individual rooms
            for i in range(total_rooms):
                room_number = f"{(room_type.name[:3] if room_type.name else 'STD').upper()}-{i+101}"
                new_room = Room(
                    property_id=new_property.property_id,
                    room_type_id=room_type.id,
                    room_number=room_number,
                    housekeeping_status="clean",
                    occupancy_status="vacant",
                )
                db.add(new_room)
        await db.flush()

    if target_user:
        target_user.property_id = new_property.property_id
        target_user.is_primary_owner = True
        await db.flush()
    else:
        # Check if a User with this mobile or email already exists
        user_check_stmt = select(User).where(
            or_(User.mobile_number == owner_mobile, User.email == owner_email)
        )
        existing_user_res = await db.execute(user_check_stmt)
        existing_user = existing_user_res.scalars().first()
        
        if existing_user:
            target_user = existing_user
            if target_user.property_id is None:
                target_user.property_id = new_property.property_id
            target_user.is_primary_owner = True
            await db.flush()
        else:
            # Create a new user with the OWNER role
            owner_role_stmt = select(Role).where(Role.role_code == "OWNER")
            owner_role_res = await db.execute(owner_role_stmt)
            owner_role = owner_role_res.scalar_one_or_none()
            if not owner_role:
                raise HTTPException(status_code=500, detail="OWNER role not found in system")
            
            # Generate a temporary password for the new owner user
            import secrets
            import string
            from app.core.security import get_password_hash
            temp_password = ''.join(secrets.choice(string.ascii_letters + string.digits) for i in range(10))
            
            new_user = User(
                id=uuid.uuid4(),
                property_id=new_property.property_id,
                role_id=owner_role.id,
                name=owner_name,
                email=owner_email,
                mobile_number=owner_mobile,
                password_hash=get_password_hash(temp_password),
                status="ACTIVE",
                is_primary_owner=True
            )
            db.add(new_user)
            await db.flush()
            target_user = new_user

    # Give the user access to this specific property in UserPropertyAccess
    from app.infra.models import UserPropertyAccess
    # Check if access already exists just in case
    access_check = await db.execute(
        select(UserPropertyAccess).where(
            UserPropertyAccess.user_id == target_user.id,
            UserPropertyAccess.property_id == new_property.property_id
        )
    )
    if not access_check.scalars().first():
        target_role_id = getattr(target_user, "role_id", None)
        if not target_role_id:
            role_res = await db.execute(select(Role).where(Role.role_code == "OWNER"))
            role_obj = role_res.scalar_one_or_none()
            target_role_id = role_obj.id if role_obj else None
            
        new_access = UserPropertyAccess(
            user_id=target_user.id,
            property_id=new_property.property_id,
            role_id=target_role_id
        )
        db.add(new_access)
        await db.flush()
    # Provision the tenant database schema
    background_tasks.add_task(provision_tenant_schema, str(new_property.property_id))
    
    current_user_id = target_user.id
    
    await AuditLogger.log(
        db,
        property_id=new_property.property_id,
        user_id=current_user_id,
        module_name="Properties",
        action_type="Created",
        target_entity="Property",
        target_record_id=new_property.property_id,
        new_value={"property_name": new_property.property_name}
    )

    # Explicitly commit the transaction to ensure changes are saved
    await db.commit()
    
    return {"message": "Property created successfully", "property_id": str(new_property.property_id)}


@router.patch("/{property_id}/approve", status_code=200, dependencies=[Depends(require_super_admin)])
async def approve_property(property_id: str, db: AsyncSession = Depends(get_db)):
    import uuid as _uuid
    try:
        pid = _uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property ID format")
        
    stmt = select(Property).where(Property.property_id == pid)
    result = await db.execute(stmt)
    prop = result.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
        
    prop.onboarding_status = "completed"
    db.add(prop)
    
    await AuditLogger.log(
        db,
        property_id=prop.property_id,
        user_id=None,
        module_name="Properties",
        action_type="Approved",
        target_entity="Property",
        target_record_id=prop.property_id,
        new_value={"onboarding_status": "completed"}
    )
    
    await db.commit()
    return {"message": "Property approved successfully"}


@router.put("/{property_id}", status_code=200)
async def update_property(property_id: str, payload: PropertyCreateInput, db: AsyncSession = Depends(get_db)):
    import uuid as _uuid
    try:
        pid = _uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property ID format")
        
    stmt = select(Property).where(Property.property_id == pid)
    result = await db.execute(stmt)
    prop = result.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
        
    prop.property_name = payload.property_name
    prop.property_type = payload.property_type or prop.property_type
    prop.description = payload.description
    prop.city = payload.city
    prop.cover_image = payload.cover_image
    
    db.add(prop)
    
    await AuditLogger.log(
        db,
        property_id=prop.property_id,
        user_id=None, # user context can be added later if current_user is available
        module_name="Properties",
        action_type="Updated",
        target_entity="Property",
        target_record_id=prop.property_id
    )
    
    return {"message": "Property updated successfully"}


@router.delete("/{property_id}", status_code=204)
async def delete_property(property_id: str, db: AsyncSession = Depends(get_db)):
    import uuid as _uuid
    from sqlalchemy import delete, update
    from app.infra.models import AuditLog, User, UserPropertyAccess, Room, Role
    
    try:
        pid = _uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property ID format")
        
    stmt = select(Property).where(Property.property_id == pid)
    result = await db.execute(stmt)
    prop = result.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
        
    # Manually cleanup child records to prevent ForeignKeyViolationError
    # since the DB schema lacks ondelete="CASCADE" for these relations.
    
    # 1. Audit Logs
    await db.execute(delete(AuditLog).where(AuditLog.property_id == pid))
    
    # 2. User Property Access
    await db.execute(delete(UserPropertyAccess).where(UserPropertyAccess.property_id == pid))
    
    # 3. Rooms
    await db.execute(delete(Room).where(Room.property_id == pid))
    
    # 4. Custom Roles
    await db.execute(delete(Role).where(Role.property_id == pid))
    
    # 5. Unlink Users (Don't delete to avoid cascading user FK errors)
    await db.execute(update(User).where(User.property_id == pid).values(property_id=None, is_primary_owner=False))
    
    from sqlalchemy.exc import IntegrityError
    try:
        await db.delete(prop)
        await db.flush() # Force flush to catch any other IntegrityError immediately
    except IntegrityError as e:
        await db.rollback()
        # Log the actual DB error to console for debugging
        print(f"Failed to delete property {pid}: {str(e)}")
        raise HTTPException(
            status_code=400, 
            detail="Cannot delete property because it has active linked records. Check server logs for details."
        )
    
    # We do NOT log the deletion using the deleted property's ID as the 'property_id' 
    # field for the log itself, because the property no longer exists and would fail FK checks.
    # Instead, we pass property_id=None, but keep target_record_id=pid.
    await AuditLogger.log(
        db,
        property_id=None,
        user_id=None,
        module_name="Properties",
        action_type="Deleted",
        target_entity="Property",
        target_record_id=pid
    )
    
    return None



from pydantic import BaseModel

class RoomCreateInput(BaseModel):
    room_number: str
    type: str
    price: float
    resort_id: str
    description: Optional[str] = ""
    image_url: Optional[str] = ""


@router.get("/rooms")
async def get_rooms(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    role = await get_current_role(current_user, db)
    
    # Select all rooms joined with their category
    q = select(Room, RoomCategory).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id)
    
    if role.role_code != "SUPER_ADMIN":
        from app.infra.models import UserPropertyAccess, Property, Owner
        from sqlalchemy import or_
        q = q.outerjoin(UserPropertyAccess, UserPropertyAccess.property_id == RoomCategory.property_id)
        q = q.outerjoin(Property, Property.property_id == RoomCategory.property_id)
        q = q.outerjoin(Owner, Owner.owner_id == Property.owner_id)
        
        conditions = [UserPropertyAccess.user_id == current_user.id]
        if current_user.property_id:
            conditions.append(RoomCategory.property_id == current_user.property_id)
        if current_user.email:
            from sqlalchemy import func
            conditions.append(func.lower(Owner.email) == current_user.email.lower())
            
        q = q.where(or_(*conditions))
        
    result = await db.execute(q)
    rows = result.unique().all()
    data = []
    for room, cat in rows:
        data.append({
            "id": str(room.room_id),
            "room_number": room.room_number,
            "type": cat.room_name or "Standard",
            "price": float(cat.base_price or 1000.0),
            "status": room.occupancy_status or "vacant",
            "resort_id": str(cat.property_id),
            "description": cat.description or "",
             "images": [url.strip() for url in (room.image_url or "").split(",") if url.strip()] if room.image_url else [
                "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80"
            ]
        })
    return data


@router.get("/rooms/{room_id}")
async def get_room_detail(room_id: str, db: AsyncSession = Depends(get_db)):
    import uuid
    try:
        r_uuid = uuid.UUID(room_id)
    except ValueError:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="Invalid room ID format")
        
    q = select(Room, RoomCategory).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id).where(Room.room_id == r_uuid)
    result = await db.execute(q)
    row = result.first()
    if not row:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Room not found")
        
    room, cat = row
    images = [url.strip() for url in (room.image_url or "").split(",") if url.strip()] if room.image_url else [
        "https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80"
    ]
    return {
        "id": str(room.room_id),
        "room_number": room.room_number,
        "type": cat.room_name or "Standard",
        "price": float(cat.base_price or 1000.0),
        "status": room.occupancy_status or "vacant",
        "resort_id": str(cat.property_id),
        "description": cat.description or "",
        "images": images
    }


from fastapi import UploadFile, File
import os
import shutil

@router.post("/upload", status_code=201)
async def upload_image(file: UploadFile = File(...)):
    import uuid
    # Create uploads directory if not exists
    os.makedirs("uploads", exist_ok=True)
    
    # Generate unique filename
    ext = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join("uploads", filename)
    
    # Save file
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Return public URL path
    # In a real app we'd use request.base_url, but for local testing:
    return {"url": f"{settings.BASE_URL}/api/v1/uploads/{filename}"}


@router.post("/rooms", status_code=201)
async def create_room(payload: RoomCreateInput, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    import uuid as _uuid
    resort_uuid = _uuid.UUID(payload.resort_id)
    await assert_property_access(resort_uuid, current_user, db)
    
    # 0. Check if property/resort exists. If not, auto-create a mock property
    prop_q = select(Property).where(Property.property_id == resort_uuid)
    prop_result = await db.execute(prop_q)
    prop = prop_result.scalar_one_or_none()
    
    if not prop:
        return {
            "success": False,
            "status": "property_not_found",
            "message": "Property does not exist"
        }

    # 1. Check if category with this name and resort exists
    cat_q = select(RoomCategory).where(
        and_(
            RoomCategory.property_id == resort_uuid,
            RoomCategory.room_name == payload.type
        )
    )
    cat_result = await db.execute(cat_q)
    category = cat_result.scalar_one_or_none()
    
    if not category:
        # Create a new category
        category = RoomCategory(
            property_id=resort_uuid,
            room_name=payload.type,
            base_price=payload.price,
            number_of_rooms=1,
            description=payload.description
        )
        db.add(category)
        await db.flush()
    else:
        # Increment room count, but do NOT overwrite existing price and amenities
        if category.number_of_rooms:
            category.number_of_rooms += 1
        else:
            category.number_of_rooms = 1
        db.add(category)
        await db.flush()
        
    new_room = Room(
        property_id=resort_uuid,
        room_category_id=category.room_category_id,
        room_number=payload.room_number,
        housekeeping_status="clean",
        occupancy_status="vacant",
        image_url=payload.image_url
    )
    db.add(new_room)
    
    await AuditLogger.log(
        db,
        property_id=new_room.property_id,
        user_id=current_user.id,
        module_name="Properties",
        action_type="Created",
        target_entity="Room",
        target_record_id=new_room.room_id
    )
    
    return {"message": "Room created successfully", "room_id": str(new_room.room_id)}


@router.post("/rooms/{room_id}/clean", dependencies=[Depends(require_room_access())])
async def clean_room(room_id: str, db: AsyncSession = Depends(get_db)):
    import uuid as _uuid
    try:
        rid = _uuid.UUID(room_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room ID format")
        
    q = select(Room).where(Room.room_id == rid)
    result = await db.execute(q)
    room = result.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
        
    room.housekeeping_status = "clean"
    room.occupancy_status = "vacant"
    db.add(room)
    
    await AuditLogger.log(
        db,
        property_id=room.property_id,
        user_id=None,
        module_name="Properties",
        action_type="Updated",
        target_entity="Room",
        target_record_id=room.room_id,
        new_value={"status": "clean"}
    )
    
    return {"message": "Room status marked clean & vacant"}


class RoomUpdateInput(BaseModel):
    room_number: str
    type: str
    price: float
    status: str
    description: Optional[str] = ""


@router.put("/rooms/{room_id}", dependencies=[Depends(require_room_access())])
async def update_room(room_id: str, payload: RoomUpdateInput, db: AsyncSession = Depends(get_db)):
    import uuid as _uuid
    try:
        rid = _uuid.UUID(room_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room ID format")
        
    q = select(Room).where(Room.room_id == rid)
    result = await db.execute(q)
    room = result.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
        
    cat_q = select(RoomCategory).where(RoomCategory.room_category_id == room.room_category_id)
    cat_result = await db.execute(cat_q)
    category = cat_result.scalar_one_or_none()
    
    if not category:
        raise HTTPException(status_code=404, detail="Category not found for room")
        
    room.room_number = payload.room_number
    room.occupancy_status = payload.status
    
    category.room_name = payload.type
    category.base_price = payload.price
    category.description = payload.description
    
    db.add(room)
    db.add(category)
    
    await AuditLogger.log(
        db,
        property_id=room.property_id,
        user_id=None,
        module_name="Properties",
        action_type="Updated",
        target_entity="Room",
        target_record_id=room.room_id
    )
    
    return {"message": "Room updated successfully"}


@router.delete("/rooms/{room_id}", dependencies=[Depends(require_room_access())])
async def delete_room(room_id: str, db: AsyncSession = Depends(get_db)):
    import uuid as _uuid
    try:
        rid = _uuid.UUID(room_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid room ID format")
        
    q = select(Room).where(Room.room_id == rid)
    result = await db.execute(q)
    room = result.scalar_one_or_none()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
        
    await db.delete(room)
    
    await AuditLogger.log(
        db,
        property_id=room.property_id,
        user_id=None,
        module_name="Properties",
        action_type="Deleted",
        target_entity="Room",
        target_record_id=room.room_id
    )
    
    return {"message": "Room deleted successfully"}


@router.get("")
async def get_properties(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    """List properties. Super admins see all, owners see their own."""
    role = await get_current_role(current_user, db)
    
    q = (
        select(Property, Owner, Business, Subscription)
        .select_from(Property)
        .join(Owner, Property.owner_id == Owner.owner_id)
        .outerjoin(Business, Property.business_id == Business.business_id)
        .outerjoin(Subscription, Subscription.property_id == Property.property_id)
    )
    
    if role.role_code != "SUPER_ADMIN":
        # Non-super admins only see properties they have access to
        from app.infra.models import UserPropertyAccess
        from sqlalchemy import or_
        
        # Outerjoin to allow matching EITHER condition
        q = q.outerjoin(UserPropertyAccess, UserPropertyAccess.property_id == Property.property_id)
        
        conditions = [UserPropertyAccess.user_id == current_user.id]
        if current_user.property_id:
            conditions.append(Property.property_id == current_user.property_id)
        if current_user.email:
            from sqlalchemy import func
            conditions.append(func.lower(Owner.email) == current_user.email.lower())
            
        q = q.where(or_(*conditions))

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
            "image": prop.cover_image or "https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&w=800&q=80",
            "star_category": prop.star_category or "N/A",
            "year_established": prop.year_established or "N/A",
            "floors": prop.total_floors or 0,
            "rooms": prop.total_rooms or 0,
            "description": prop.description or "",
            "owner": owner.full_name,
            "owner_email": owner.email or "N/A",
            "mobile": owner.mobile_number,
            "owner_pan": owner.pan_number or "N/A",
            "owner_designation": owner.designation or "N/A",
            "business": biz.business_name,
            "business_name": biz.business_name,
            "business_type": biz.business_type or "N/A",
            "business_reg": biz.business_reg_number or "N/A",
            "business_gst": biz.gst_number or "N/A",
            "business_pan": biz.pan_number or "N/A",
            "city": prop.city or "Unknown",
            "status": status,
            "verificationStatus": _verification_status(prop.onboarding_status),
            "subscriptionStatus": sub.status if sub else "No Subscription",
            "plan": sub.plan if sub else "N/A",
            "lastUpdated": str(prop.updated_at)[:10] if prop.updated_at else "N/A",
            "onboarding": "100%" if prop.onboarding_status == "completed" else "50%",
            "lastSync": "N/A",
        })
    return data


@router.get("/kpis", dependencies=[Depends(require_super_admin)])
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


@router.get("/dashboard", dependencies=[Depends(require_super_admin)])
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
async def get_property_detail(property_id: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Return a single property with owner, subscription, device info."""
    try:
        import uuid as _uuid
        pid = _uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property ID format")
    await assert_property_access(pid, current_user, db)

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

@router.delete("/{property_id}", dependencies=[Depends(require_super_admin)])
async def delete_property(property_id: str, db: AsyncSession = Depends(get_db)):
    """Soft delete a property by setting is_deleted=True."""
    prop_uuid = uuid.UUID(property_id)
    result = await db.execute(select(Property).where(Property.property_id == prop_uuid))
    prop = result.scalar_one_or_none()
    
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
        
    prop.is_deleted = True
    await db.commit()
    return {"message": "Property deleted successfully"}


@router.get("/{property_id}/staff", dependencies=[Depends(require_super_admin)])
async def get_property_staff(property_id: str, db: AsyncSession = Depends(get_db)):
    """Return all users (staff) assigned to this property. Super Admin only."""
    try:
        pid = uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property ID format")

    prop = (await db.execute(select(Property).where(Property.property_id == pid))).scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")

    stmt = (
        select(User, Role)
        .join(Role, User.role_id == Role.id)
        .where(User.property_id == pid)
        .order_by(Role.role_code, User.name)
    )
    result = await db.execute(stmt)
    rows = result.all()

    staff = []
    for user, role in rows:
        staff.append({
            "id": str(user.id),
            "name": user.name,
            "email": user.email,
            "mobile_number": user.mobile_number,
            "username": user.username,
            "role_code": role.role_code,
            "role_name": role.role_name,
            "status": user.status,
            "is_primary_owner": user.is_primary_owner,
        })

    return staff


@router.get("/{property_id}/audit-logs", dependencies=[Depends(require_super_admin)])
async def get_property_audit_logs(
    property_id: str,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
):
    """Return recent audit log entries scoped to this property."""
    try:
        pid = uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property ID format")

    prop = (await db.execute(select(Property).where(Property.property_id == pid))).scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")

    stmt = (
        select(AuditLog, User)
        .outerjoin(User, AuditLog.user_id == User.id)
        .where(AuditLog.property_id == pid)
        .order_by(AuditLog.timestamp.desc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    rows = result.all()

    logs = []
    for log, user in rows:
        logs.append({
            "log_id": str(log.log_id),
            "action_type": log.action_type,
            "module_name": log.module_name,
            "target_entity": log.target_entity,
            "target_record_id": str(log.target_record_id) if log.target_record_id else None,
            "user_name": user.name if user else "System",
            "timestamp": log.timestamp.isoformat() if log.timestamp else None,
            "ip_address": log.ip_address,
        })

    return logs

