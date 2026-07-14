import asyncio
import logging

from app.seeds.runner import run_seeds


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    asyncio.run(run_seeds())
