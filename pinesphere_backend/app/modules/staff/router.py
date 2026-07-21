import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infra.database import get_db
from app.modules.staff import schemas
from app.modules.staff.services import StaffService

router = APIRouter(
    prefix="/staff",
    tags=["Staff Management"]
)

from sqlalchemy.future import select
from app.core.dependencies import assert_property_access, get_current_user
from app.infra.models import User, Role

async def check_tenant(property_id: uuid.UUID, current_user: User, db: AsyncSession):
    await assert_property_access(property_id, current_user, db)

async def check_staff_tenant(staff_id: uuid.UUID, current_user: User, db: AsyncSession):
    role_res = await db.execute(select(Role).filter(Role.id == current_user.role_id))
    role = role_res.scalars().first()
    if role and role.role_code == "SUPER_ADMIN":
        return
    staff_res = await db.execute(select(User).filter(User.id == staff_id))
    staff = staff_res.scalars().first()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")
    await assert_property_access(staff.property_id, current_user, db)

@router.post("/onboard", response_model=schemas.StaffResponse, status_code=status.HTTP_201_CREATED)
async def onboard_staff(staff_in: schemas.StaffCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await check_tenant(staff_in.property_id, current_user, db)
    service = StaffService(db)
    return await service.create_staff(staff_in, current_user.id)

@router.get("/property/{property_id}", response_model=List[schemas.StaffResponse])
async def get_staff_by_property(property_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await check_tenant(property_id, current_user, db)
    service = StaffService(db)
    return await service.get_staff_by_property(property_id)

@router.post("/invite", response_model=schemas.StaffResponse, status_code=status.HTTP_201_CREATED)
async def invite_staff(invite_in: schemas.StaffInvite, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await check_tenant(invite_in.property_id, current_user, db)
    service = StaffService(db)
    return await service.invite_staff(invite_in, current_user.id)

@router.patch("/{staff_id}/status", response_model=schemas.StaffResponse)
async def update_staff_status(staff_id: uuid.UUID, status_update: schemas.StaffStatusUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await check_staff_tenant(staff_id, current_user, db)
    service = StaffService(db)
    return await service.update_status(staff_id, status_update.status, current_user.id)

@router.post("/attendance/punch", response_model=schemas.StaffAttendanceResponse)
async def punch_attendance(attendance_in: schemas.StaffAttendanceCreate, staff_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await check_tenant(attendance_in.property_id, current_user, db)
    service = StaffService(db)
    return await service.mark_attendance(attendance_in, staff_id, marker_id=current_user.id)

@router.post("/leave/apply", response_model=schemas.StaffLeaveResponse, status_code=status.HTTP_201_CREATED)
async def apply_leave(leave_in: schemas.StaffLeaveCreate, staff_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await check_staff_tenant(staff_id, current_user, db)
    service = StaffService(db)
    return await service.apply_leave(leave_in, staff_id)

@router.put("/leave/{leave_id}/approve", response_model=schemas.StaffLeaveResponse)
async def approve_leave(leave_id: uuid.UUID, status: str, rejection_reason: str = None, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    service = StaffService(db)
    return await service.approve_leave(leave_id, current_user.id, status, rejection_reason)

@router.post("/salary/generate", response_model=schemas.StaffSalaryResponse, status_code=status.HTTP_201_CREATED)
async def generate_salary(salary_in: schemas.StaffSalaryCreate, staff_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await check_staff_tenant(staff_id, current_user, db)
    service = StaffService(db)
    return await service.generate_salary(salary_in, staff_id, generator_id=current_user.id)

@router.post("/task/assign", response_model=schemas.StaffTaskResponse, status_code=status.HTTP_201_CREATED)
async def assign_task(task_in: schemas.StaffTaskCreate, staff_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await check_tenant(task_in.property_id, current_user, db)
    service = StaffService(db)
    return await service.assign_task(task_in, staff_id, assigner_id=current_user.id)
