import uuid
from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, Field, EmailStr, ConfigDict

# Staff (User)
class StaffBase(BaseModel):
    property_id: Optional[uuid.UUID] = None
    role_id: uuid.UUID
    name: str
    mobile_number: Optional[str] = None
    email: Optional[EmailStr] = None
    biometric_enabled: bool = False
    is_primary_owner: bool = False
    status: str = "ACTIVE"
    profile_photo_url: Optional[str] = None

class StaffCreate(StaffBase):
    password: Optional[str] = None
    pin: Optional[str] = None

class StaffResponse(StaffBase):
    id: uuid.UUID
    failed_login_attempts: int
    is_pending_sync: bool

    model_config = ConfigDict(from_attributes=True)

# Attendance
class StaffAttendanceBase(BaseModel):
    property_id: uuid.UUID
    attendance_date: date
    status: str
    check_in_time: Optional[datetime] = None
    check_out_time: Optional[datetime] = None
    check_in_method: Optional[str] = None
    check_in_lat: Optional[float] = None
    check_in_lng: Optional[float] = None
    remarks: Optional[str] = None

class StaffAttendanceCreate(StaffAttendanceBase):
    pass

class StaffAttendanceResponse(StaffAttendanceBase):
    attendance_id: uuid.UUID
    staff_id: uuid.UUID
    marked_by: Optional[uuid.UUID] = None
    sync_status: str

    model_config = ConfigDict(from_attributes=True)

# Leave
class StaffLeaveBase(BaseModel):
    leave_type_id: uuid.UUID
    from_date: date
    to_date: date
    reason: Optional[str] = None

class StaffLeaveCreate(StaffLeaveBase):
    pass

class StaffLeaveResponse(StaffLeaveBase):
    leave_id: uuid.UUID
    staff_id: uuid.UUID
    total_days: int
    status: str
    applied_on: datetime
    approved_by: Optional[uuid.UUID] = None
    approved_on: Optional[datetime] = None
    rejection_reason: Optional[str] = None
    sync_status: str

    model_config = ConfigDict(from_attributes=True)

# Salary
class StaffSalaryBase(BaseModel):
    salary_month: int
    salary_year: int
    basic_salary: float
    allowances: float = 0.0
    overtime_amount: float = 0.0
    deductions: float = 0.0
    advance_deducted: float = 0.0
    payment_mode: Optional[str] = None
    remarks: Optional[str] = None

class StaffSalaryCreate(StaffSalaryBase):
    pass

class StaffSalaryResponse(StaffSalaryBase):
    salary_id: uuid.UUID
    staff_id: uuid.UUID
    net_salary: float
    payment_status: str
    payment_date: Optional[datetime] = None
    generated_by: Optional[uuid.UUID] = None

    model_config = ConfigDict(from_attributes=True)

# Performance
class StaffPerformanceBase(BaseModel):
    review_period_start: date
    review_period_end: date
    rating: float
    remarks: Optional[str] = None

class StaffPerformanceCreate(StaffPerformanceBase):
    pass

class StaffPerformanceResponse(StaffPerformanceBase):
    performance_id: uuid.UUID
    staff_id: uuid.UUID
    attendance_score: Optional[float] = None
    task_completion_score: Optional[float] = None
    reviewed_by: uuid.UUID
    review_date: datetime

    model_config = ConfigDict(from_attributes=True)

# Tasks
class StaffTaskBase(BaseModel):
    property_id: uuid.UUID
    task_title: str
    task_description: Optional[str] = None
    related_module: Optional[str] = None
    related_record_id: Optional[uuid.UUID] = None
    priority: str = 'Medium'
    due_date: Optional[datetime] = None

class StaffTaskCreate(StaffTaskBase):
    pass

class StaffTaskResponse(StaffTaskBase):
    task_id: uuid.UUID
    staff_id: uuid.UUID
    assigned_by: uuid.UUID
    status: str
    completed_at: Optional[datetime] = None
    completion_notes: Optional[str] = None
    completion_photo_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
