import asyncio
import re
import unicodedata
from sqlalchemy import text
from app.infra.database import engine

async def backfill():
    async with engine.begin() as conn:
        # Fetch properties without slug
        res = await conn.execute(text("SELECT property_id, property_name FROM properties WHERE slug IS NULL"))
        properties = res.fetchall()

        for prop_id, name in properties:
            # 1. Normalize
            normalized = unicodedata.normalize('NFKD', name or "prop").encode('ascii', 'ignore').decode('ascii')
            base_slug = re.sub(r'[^a-z0-9]+', '-', normalized.lower()).strip('-')
            
            # 2. Max length
            base_slug = base_slug[:90]
            
            if not base_slug:
                base_slug = "property"
                
            slug = base_slug
            counter = 2
            
            # 3. Collision check
            while True:
                check = await conn.execute(
                    text("SELECT property_id FROM properties WHERE slug = :slug"),
                    {"slug": slug}
                )
                if not check.first():
                    break
                slug = f"{base_slug}-{counter}"
                counter += 1
            
            # 4. Update
            await conn.execute(
                text("UPDATE properties SET slug = :slug WHERE property_id = :pid"),
                {"slug": slug, "pid": prop_id}
            )
            print(f"Updated {prop_id} with slug {slug}")

if __name__ == "__main__":
    asyncio.run(backfill())
