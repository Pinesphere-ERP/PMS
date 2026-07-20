from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from sqlalchemy.future import select
from sqlalchemy import func, and_, or_
from datetime import date, timedelta
from typing import List, Optional

from app.infra.database import get_db, provision_tenant_schema
from app.core.dependencies import assert_property_access, get_current_user, require_room_access, require_super_admin
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


@router.post("", dependencies=[Depends(require_super_admin)])
async def create_property(payload: PropertyCreateInput, background_tasks: BackgroundTasks, db: AsyncSession = Depends(get_db)):
    owner_name = payload.owner_name
    owner_mobile = payload.owner_mobile
    owner_email = payload.owner_email
    target_user = None

    if payload.owner_user_id:
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

    if target_user:
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
    try:
        pid = _uuid.UUID(property_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid property ID format")
        
    stmt = select(Property).where(Property.property_id == pid)
    result = await db.execute(stmt)
    prop = result.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
        
    await db.delete(prop)
    
    await AuditLogger.log(
        db,
        property_id=prop.property_id,
        user_id=None,
        module_name="Properties",
        action_type="Deleted",
        target_entity="Property",
        target_record_id=prop.property_id
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


@router.get("/rooms", dependencies=[Depends(require_super_admin)])
async def get_rooms(db: AsyncSession = Depends(get_db)):
    # Select all rooms joined with their category
    q = select(Room, RoomCategory).join(RoomCategory, Room.room_category_id == RoomCategory.room_category_id)
    result = await db.execute(q)
    rows = result.all()
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


@router.get("", dependencies=[Depends(require_super_admin)])
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
