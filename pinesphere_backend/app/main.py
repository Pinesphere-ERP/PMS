from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.api import api_router

<<<<<<< HEAD
=======
from contextlib import asynccontextmanager
from sqlalchemy import select
from app.infra.database import engine, AsyncSessionLocal, Base
from app.infra.models import Role, User
import uuid

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        
    roles_data = [
        {"role_code": "SUPER_ADMIN", "role_name": "Super Admin"},
        {"role_code": "OWNER", "role_name": "Owner"},
        {"role_code": "MANAGER", "role_name": "Manager"},
        {"role_code": "RECEPTION", "role_name": "Reception"},
        {"role_code": "HOUSEKEEPING", "role_name": "Housekeeping"},
        {"role_code": "ACCOUNTANT", "role_name": "Accountant"},
        {"role_code": "GUEST", "role_name": "Guest"},
    ]
    async with AsyncSessionLocal() as db:
        for r_data in roles_data:
            stmt = select(Role).where(Role.role_code == r_data["role_code"])
            res = await db.execute(stmt)
            if not res.scalar_one_or_none():
                db.add(Role(
                    id=uuid.uuid4(),
                    role_code=r_data["role_code"],
                    role_name=r_data["role_name"],
                    is_system_role=True,
                    description=r_data["role_name"] + " role"
                ))
        await db.commit()

        # Seed user arunaw
        from app.core.security import get_password_hash
        
        stmt = select(Role).where(Role.role_code == "SUPER_ADMIN")
        res = await db.execute(stmt)
        super_admin_role = res.scalar_one_or_none()
        
        if super_admin_role:
            stmt = select(User).where(User.username == "arunaw")
            res = await db.execute(stmt)
            user = res.scalar_one_or_none()
            if not user:
                db.add(User(
                    id=uuid.uuid4(),
                    username="arunaw",
                    email="arunawrishe@gmail.com",
                    password_hash=get_password_hash("arunaw2007"),
                    name="Arunaw",
                    mobile_number="0000000000",
                    status="ACTIVE",
                    role_id=super_admin_role.id,
                    property_id=None
                ))
                await db.commit()
            else:
                user.password_hash = get_password_hash("arunaw2007")
                user.role_id = super_admin_role.id
                await db.commit()

        # Seed Mock Data
        from app.seed_mock import seed_mock_data
        await seed_mock_data(db)
        
    yield

>>>>>>> origin/main
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Offline-First Enterprise PMS Backend API",
)

# CORS — allow Vite dev server and any localhost port
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://localhost:5174",
        "http://localhost:3000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    with open("validation_error.log", "a") as f:
        f.write(f"Validation Error: {exc.errors()}\n")
        f.write(f"Body: {exc.body}\n")
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors(), "body": exc.body},
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import traceback
    tb = traceback.format_exc()
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal Server Error", "traceback": tb, "error": str(exc)},
    )

@app.get("/health")
async def health_check():
    return {"status": "ok", "version": settings.VERSION}
