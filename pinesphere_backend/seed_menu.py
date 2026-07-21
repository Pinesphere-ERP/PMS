import asyncio
import uuid
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from app.infra.models import Property, MenuCategory, MenuItem
from app.core.config import settings

async def seed_menu():
    engine = create_async_engine(settings.DATABASE_URL, echo=True)
    async_session = sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    
    async with async_session() as session:
        # Get properties
        result = await session.execute(select(Property))
        properties = result.scalars().all()
        
        if not properties:
            print("No properties found. Please run seed_admin.py first.")
            return

        for prop in properties:
            print(f"Seeding menu for property: {prop.property_name} ({prop.property_id})")
            
            # Check if menu already exists
            existing = await session.execute(select(MenuCategory).where(MenuCategory.property_id == prop.property_id))
            if existing.scalars().first():
                print(f"Menu already exists for {prop.property_name}. Skipping.")
                continue
                
            # Create categories
            starters_cat = MenuCategory(
                id=uuid.uuid4(), property_id=prop.property_id, name="Starters & Snacks", sort_order=1
            )
            mains_cat = MenuCategory(
                id=uuid.uuid4(), property_id=prop.property_id, name="Main Course", sort_order=2
            )
            bevs_cat = MenuCategory(
                id=uuid.uuid4(), property_id=prop.property_id, name="Beverages", sort_order=3
            )
            session.add_all([starters_cat, mains_cat, bevs_cat])
            await session.flush()
            
            # Create items
            items = [
                MenuItem(
                    id=uuid.uuid4(), category_id=starters_cat.id, property_id=prop.property_id,
                    name="Paneer Tikka", description="Grilled cottage cheese cubes marinated in spices",
                    price=250.00, veg_type="veg"
                ),
                MenuItem(
                    id=uuid.uuid4(), category_id=starters_cat.id, property_id=prop.property_id,
                    name="Chicken 65", description="Spicy, deep-fried chicken chunks",
                    price=320.00, veg_type="non-veg"
                ),
                MenuItem(
                    id=uuid.uuid4(), category_id=mains_cat.id, property_id=prop.property_id,
                    name="Butter Chicken", description="Classic Indian butter chicken with rich tomato gravy",
                    price=450.00, veg_type="non-veg"
                ),
                MenuItem(
                    id=uuid.uuid4(), category_id=mains_cat.id, property_id=prop.property_id,
                    name="Dal Makhani", description="Slow cooked black lentils with butter and cream",
                    price=280.00, veg_type="veg"
                ),
                MenuItem(
                    id=uuid.uuid4(), category_id=bevs_cat.id, property_id=prop.property_id,
                    name="Fresh Lime Soda", description="Refreshing sweet or salted lime soda",
                    price=90.00, veg_type="veg"
                ),
                MenuItem(
                    id=uuid.uuid4(), category_id=bevs_cat.id, property_id=prop.property_id,
                    name="Cold Coffee", description="Chilled blended coffee with milk and sugar",
                    price=150.00, veg_type="veg"
                ),
            ]
            session.add_all(items)
            
        await session.commit()
        print("Menu seeding completed successfully.")

if __name__ == "__main__":
    asyncio.run(seed_menu())
