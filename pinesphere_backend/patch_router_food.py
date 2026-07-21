import re
import os

ROUTER_PATH = r"c:\projects\PMS\pinesphere_backend\app\modules\portal\router.py"

with open(ROUTER_PATH, "r", encoding="utf-8") as f:
    content = f.read()

# Add schemas to import
schemas_import_pattern = r"from app\.modules\.portal\.schemas import \("
schemas_replacement = """from app.modules.portal.schemas import (
    PortalMenuCategory, PortalMenuItem, PortalFoodOrderCreate, PortalFoodOrderCreateItem,"""
content = re.sub(schemas_import_pattern, schemas_replacement, content, count=1)


# Replace create_portal_order and add GET food/menu and GET food/orders
old_block_pattern = r"@router\.post\(\"/orders\"\).*?return \{\n\s+\"status\": \"success\",\n\s+\"task_id\": str\(task\.task_id\),\n\s+\"order_total\": round\(total, 2\),\n\s+\"message\": \"Order sent to kitchen\. Estimated delivery: 20–30 minutes\.\",\n\s+\}"

new_block = """@router.get("/food/menu", response_model=List[PortalMenuCategory])
async def get_portal_food_menu(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import MenuCategory, MenuItem
    stmt = select(MenuCategory).where(
        MenuCategory.property_id == booking.property_id,
        MenuCategory.is_active == True,
        MenuCategory.is_deleted == False
    ).order_by(MenuCategory.sort_order)
    res = await db.execute(stmt)
    categories = res.scalars().all()
    
    item_stmt = select(MenuItem).where(
        MenuItem.property_id == booking.property_id,
        MenuItem.is_deleted == False
    )
    item_res = await db.execute(item_stmt)
    items = item_res.scalars().all()
    
    cat_map = {c.id: {"id": c.id, "name": c.name, "description": c.description, "items": []} for c in categories}
    for item in items:
        if item.category_id in cat_map:
            cat_map[item.category_id]["items"].append({
                "id": item.id,
                "name": item.name,
                "description": item.description,
                "price": float(item.price),
                "veg_type": item.veg_type,
                "is_available": item.is_available,
                "image_url": item.image_url
            })
            
    return [c for c in cat_map.values()]


@router.post("/food/orders")
async def create_portal_food_order(
    payload: PortalFoodOrderCreate,
    booking: Booking = Depends(get_current_guest_booking),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import MenuItem, Task, TaskLog
    if not payload.items:
        raise HTTPException(status_code=400, detail="Order must contain at least one item.")

    item_ids = [i.item_id for i in payload.items]
    stmt = select(MenuItem).where(
        MenuItem.id.in_(item_ids),
        MenuItem.property_id == booking.property_id,
        MenuItem.is_available == True,
        MenuItem.is_deleted == False
    )
    res = await db.execute(stmt)
    db_items = {i.id: i for i in res.scalars().all()}
    
    total = 0.0
    desc_parts = []
    for item in payload.items:
        db_item = db_items.get(item.item_id)
        if not db_item:
            raise HTTPException(status_code=400, detail=f"Item {item.item_id} is invalid or unavailable.")
        total += float(db_item.price) * item.quantity
        desc_parts.append(f"{item.quantity}x {db_item.name}")
        
    description = ", ".join(desc_parts)
    if payload.special_instructions:
        description += f" | Notes: {payload.special_instructions}"
        
    task_id = uuid.uuid4()
    task = Task(
        task_id=task_id,
        property_id=booking.property_id,
        task_type="food",
        status="pending",
        priority="normal",
        room_id=booking.room_id,
        booking_id=booking.booking_id,
        description=f"F&B Order: {description}",
    )
    db.add(task)
    
    log = TaskLog(
        log_id=uuid.uuid4(),
        task_id=task_id,
        old_status=None,
        new_status="pending",
        notes="Guest placed food order via portal"
    )
    db.add(log)
    
    folio_item = FolioLineItem(
        id=uuid.uuid4(),
        booking_id=booking.booking_id,
        property_id=booking.property_id,
        category="food",
        description=f"F&B Order: {description}",
        quantity=1,
        unit_price=total,
        amount=total,
        is_void=False,
    )
    db.add(folio_item)
    
    await db.commit()
    
    return {
        "status": "success",
        "task_id": str(task_id),
        "order_total": round(total, 2),
        "message": "Order sent to kitchen.",
    }

@router.get("/food/orders")
async def get_portal_food_orders(
    booking: Booking = Depends(require_can_view_dashboard),
    db: AsyncSession = Depends(get_db),
):
    from app.infra.models import Task
    stmt = select(Task).where(
        Task.booking_id == booking.booking_id,
        Task.task_type == 'food'
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
    ]"""

content = re.sub(old_block_pattern, new_block, content, flags=re.DOTALL)

with open(ROUTER_PATH, "w", encoding="utf-8") as f:
    f.write(content)

print("Router patched successfully.")
