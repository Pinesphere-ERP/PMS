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

# Dummy dependency for current user, assuming auth is handled elsewhere
def get_current_user_id() -> uuid.UUID:
    return uuid.uuid4() # Mock user ID for now

@router.post("/onboard", response_model=schemas.StaffResponse, status_code=status.HTTP_201_CREATED)
async def onboard_staff(staff_in: schemas.StaffCreate, db: AsyncSession = Depends(get_db), current_user_id: uuid.UUID = Depends(get_current_user_id)):
    service = StaffService(db)
    return await service.create_staff(staff_in, current_user_id)

@router.get("/property/{property_id}", response_model=List[schemas.StaffResponse])
async def get_staff_by_property(property_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    service = StaffService(db)
    return await service.get_staff_by_property(property_id)

@router.post("/attendance/punch", response_model=schemas.StaffAttendanceResponse)
async def punch_attendance(attendance_in: schemas.StaffAttendanceCreate, staff_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user_id: uuid.UUID = Depends(get_current_user_id)):
    service = StaffService(db)
    return await service.mark_attendance(attendance_in, staff_id, marker_id=current_user_id)

@router.post("/leave/apply", response_model=schemas.StaffLeaveResponse, status_code=status.HTTP_201_CREATED)
async def apply_leave(leave_in: schemas.StaffLeaveCreate, staff_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    service = StaffService(db)
    return await service.apply_leave(leave_in, staff_id)

@router.put("/leave/{leave_id}/approve", response_model=schemas.StaffLeaveResponse)
async def approve_leave(leave_id: uuid.UUID, status: str, rejection_reason: str = None, db: AsyncSession = Depends(get_db), current_user_id: uuid.UUID = Depends(get_current_user_id)):
    service = StaffService(db)
    return await service.approve_leave(leave_id, current_user_id, status, rejection_reason)

@router.post("/salary/generate", response_model=schemas.StaffSalaryResponse, status_code=status.HTTP_201_CREATED)
async def generate_salary(salary_in: schemas.StaffSalaryCreate, staff_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user_id: uuid.UUID = Depends(get_current_user_id)):
    service = StaffService(db)
    return await service.generate_salary(salary_in, staff_id, generator_id=current_user_id)

@router.post("/task/assign", response_model=schemas.StaffTaskResponse, status_code=status.HTTP_201_CREATED)
async def assign_task(task_in: schemas.StaffTaskCreate, staff_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user_id: uuid.UUID = Depends(get_current_user_id)):
    service = StaffService(db)
    return await service.assign_task(task_in, staff_id, assigner_id=current_user_id)
