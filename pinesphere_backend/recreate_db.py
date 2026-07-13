import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings
from app.infra.database import Base
# Import all models to ensure they are registered with Base metadata
import app.infra.models
from app.seed import seed_data

async def recreate():
    # Remove existing sqlite database file
    db_file = "./pinesphere.db"
    if os.path.exists(db_file):
        os.remove(db_file)
        print(f"Removed existing {db_file}")

    # Create engine
    engine = create_async_engine(settings.DATABASE_URL, echo=True)

    # Recreate all tables
    print("Recreating database tables from SQLAlchemy metadata...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("Database tables created successfully!")

    # Run seeding
    print("Seeding database...")
    await seed_data()
    print("Database seeding completed!")

if __name__ == "__main__":
    asyncio.run(recreate())
