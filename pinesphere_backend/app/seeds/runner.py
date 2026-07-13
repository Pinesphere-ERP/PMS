"""Run configured seed modules outside the FastAPI startup lifecycle."""

import importlib
import logging

from app.core.config import settings
from app.infra.database import AsyncSessionLocal

logger = logging.getLogger(__name__)

# Keep this registry small and domain-oriented. Additional domains can be added
# without changing application startup code.
SEED_MODULES = {
    "development": ("app.seeds.users",),
    "demo": ("app.seeds.users",),
    "production": ("app.seeds.users",),
}


async def run_seeds() -> None:
    """Execute enabled seed modules once, safely and independently of the API."""
    if not settings.ENABLE_SEEDING:
        logger.info("Seeding is disabled; set ENABLE_SEEDING=true to run it.")
        return

    modules = SEED_MODULES[settings.SEED_MODE]
    async with AsyncSessionLocal() as session:
        for module_name in modules:
            try:
                module = importlib.import_module(module_name)
            except ModuleNotFoundError as exc:
                if exc.name == module_name:
                    logger.warning("Seed module %s is unavailable; skipping it.", module_name)
                    continue
                raise

            await module.seed(session)
            await session.commit()
            logger.info("Completed %s", module_name)
