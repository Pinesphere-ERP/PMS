import uuid
from datetime import date, datetime, timedelta
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status

from app.infra.models import User, Role, Property
from app.modules.audit.logger import AuditLogger
from app.modules.staff import models, schemas

class StaffService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # Identity & Role Management
    async def create_staff(self, staff_in: schemas.StaffCreate, current_user_id: uuid.UUID) -> User:
        # Check if mobile_number already exists for the property
        if staff_in.mobile_number:
            result = await self.db.execute(select(User).filter(
                User.property_id == staff_in.property_id,
                User.mobile_number == staff_in.mobile_number
            ))
            existing = result.scalars().first()
            if existing:
                raise HTTPException(status_code=400, detail="Mobile number already registered for this property")
        
        # Check primary owner constraint
        if staff_in.is_primary_owner:
            result = await self.db.execute(select(User).filter(
                User.property_id == staff_in.property_id,
                User.is_primary_owner == True
            ))
            existing_owner = result.scalars().first()
            if existing_owner:
                raise HTTPException(status_code=400, detail="Property already has a primary owner")

        new_staff = User(
            property_id=staff_in.property_id,
            role_id=staff_in.role_id,
            name=staff_in.name,
            mobile_number=staff_in.mobile_number,
            email=staff_in.email,
            biometric_enabled=staff_in.biometric_enabled,
            is_primary_owner=staff_in.is_primary_owner,
            status=staff_in.status,
            profile_photo_url=staff_in.profile_photo_url,
            created_by=current_user_id
        )
        # Assuming password/pin hashing is done before passing to this service
        if staff_in.password:
            new_staff.password_hash = staff_in.password
        if staff_in.pin:
            new_staff.pin_hash = staff_in.pin

        self.db.add(new_staff)
        await self.db.flush()
        await self.db.refresh(new_staff)
        
        # Audit log
        await AuditLogger.log(
            self.db,
            module_name="StaffManagement",
            action_type="Created",
            target_entity="User",
            target_record_id=new_staff.id,
            user_id=current_user_id,
            property_id=staff_in.property_id
        )
        
        return new_staff

    async def invite_staff(self, invite_in: schemas.StaffInvite, current_user_id: uuid.UUID) -> User:
        # Check if mobile_number already exists
        result = await self.db.execute(select(User).filter(
            User.property_id == invite_in.property_id,
            User.mobile_number == invite_in.mobile_number
        ))
        if result.scalars().first():
            raise HTTPException(status_code=400, detail="Mobile number already registered for this property")
            
        new_staff = User(
            property_id=invite_in.property_id,
            role_id=invite_in.role_id,
            name=invite_in.name,
            mobile_number=invite_in.mobile_number,
            status="PENDING_ONBOARDING",
            created_by=current_user_id
        )
        self.db.add(new_staff)
        await self.db.commit()
        await self.db.refresh(new_staff)
        
        await AuditLogger.log(
            self.db,
            module_name="StaffManagement",
            action_type="Invited",
            target_entity="User",
            target_record_id=new_staff.id,
            user_id=current_user_id,
            property_id=invite_in.property_id
        )
        # Here we would typically trigger SMS integration
        return new_staff

    async def update_status(self, staff_id: uuid.UUID, status: str, current_user_id: uuid.UUID) -> User:
        result = await self.db.execute(select(User).filter(User.id == staff_id))
        staff = result.scalars().first()
        if not staff:
            raise HTTPException(status_code=404, detail="Staff member not found")
            
        staff.status = status
        staff.updated_at = datetime.utcnow()
        staff.updated_by = current_user_id
        
        await self.db.commit()
        await self.db.refresh(staff)
        
        await AuditLogger.log(
            self.db,
            module_name="StaffManagement",
            action_type="StatusUpdated",
            target_entity="User",
            target_record_id=staff.id,
            user_id=current_user_id,
            property_id=staff.property_id,
            changes={"new_status": status}
        )
        return staff


    async def get_staff_by_property(self, property_id: uuid.UUID) -> List[User]:
        result = await self.db.execute(select(User).filter(User.property_id == property_id))
        return result.scalars().all()

    # Day-to-day Operations
    async def mark_attendance(self, attendance_in: schemas.StaffAttendanceCreate, staff_id: uuid.UUID, marker_id: Optional[uuid.UUID] = None) -> models.StaffAttendance:
        # Check if already marked for the day
        result = await self.db.execute(select(models.StaffAttendance).filter(
            models.StaffAttendance.staff_id == staff_id,
            models.StaffAttendance.attendance_date == attendance_in.attendance_date
        ))
        existing = result.scalars().first()

        if existing:
            # Update checkout time or status
            existing.check_out_time = attendance_in.check_out_time
            existing.status = attendance_in.status
            existing.remarks = attendance_in.remarks
            await self.db.commit()
            await self.db.refresh(existing)
            return existing

        new_attendance = models.StaffAttendance(
            staff_id=staff_id,
            property_id=attendance_in.property_id,
            attendance_date=attendance_in.attendance_date,
            check_in_time=attendance_in.check_in_time,
            check_out_time=attendance_in.check_out_time,
            status=attendance_in.status,
            check_in_method=attendance_in.check_in_method,
            check_in_lat=attendance_in.check_in_lat,
            check_in_lng=attendance_in.check_in_lng,
            marked_by=marker_id,
            remarks=attendance_in.remarks
        )
        self.db.add(new_attendance)
        await self.db.commit()
        await self.db.refresh(new_attendance)
        
        await AuditLogger.log(
            self.db,
            module_name="StaffManagement",
            action_type="Created",
            target_entity="StaffAttendance",
            target_record_id=new_attendance.attendance_id,
            user_id=marker_id or staff_id,
            property_id=attendance_in.property_id
        )
        return new_attendance

    async def apply_leave(self, leave_in: schemas.StaffLeaveCreate, staff_id: uuid.UUID) -> models.StaffLeave:
        # Compute total days
        delta = leave_in.to_date - leave_in.from_date
        total_days = delta.days + 1
        if total_days <= 0:
            raise HTTPException(status_code=400, detail="Invalid date range")

        new_leave = models.StaffLeave(
            staff_id=staff_id,
            leave_type_id=leave_in.leave_type_id,
            from_date=leave_in.from_date,
            to_date=leave_in.to_date,
            total_days=total_days,
            reason=leave_in.reason,
            status="Pending"
        )
        self.db.add(new_leave)
        await self.db.commit()
        await self.db.refresh(new_leave)
        return new_leave

    async def approve_leave(self, leave_id: uuid.UUID, approver_id: uuid.UUID, status: str, rejection_reason: Optional[str] = None) -> models.StaffLeave:
        result = await self.db.execute(select(models.StaffLeave).filter(models.StaffLeave.leave_id == leave_id))
        leave = result.scalars().first()
        if not leave:
            raise HTTPException(status_code=404, detail="Leave request not found")

        leave.status = status
        leave.approved_by = approver_id
        leave.approved_on = datetime.utcnow()
        if status == 'Rejected':
            leave.rejection_reason = rejection_reason
        
        await self.db.commit()
        await self.db.refresh(leave)

        # Audit
        user_result = await self.db.execute(select(User).filter(User.id == leave.staff_id))
        staff_record = user_result.scalars().first()
        if staff_record:
            await AuditLogger.log(
                self.db,
                module_name="StaffManagement",
                action_type=status,
                target_entity="StaffLeave",
                target_record_id=leave.leave_id,
                user_id=approver_id,
                property_id=staff_record.property_id
            )
        
        return leave

    # Payroll Support
    async def generate_salary(self, salary_in: schemas.StaffSalaryCreate, staff_id: uuid.UUID, generator_id: uuid.UUID) -> models.StaffSalary:
        result = await self.db.execute(select(models.StaffSalary).filter(
            models.StaffSalary.staff_id == staff_id,
            models.StaffSalary.salary_month == salary_in.salary_month,
            models.StaffSalary.salary_year == salary_in.salary_year
        ))
        existing = result.scalars().first()

        if existing:
            raise HTTPException(status_code=400, detail="Salary already generated for this month")

        net_salary = salary_in.basic_salary + salary_in.allowances + salary_in.overtime_amount - salary_in.deductions - salary_in.advance_deducted
        
        new_salary = models.StaffSalary(
            staff_id=staff_id,
            salary_month=salary_in.salary_month,
            salary_year=salary_in.salary_year,
            basic_salary=salary_in.basic_salary,
            allowances=salary_in.allowances,
            overtime_amount=salary_in.overtime_amount,
            deductions=salary_in.deductions,
            advance_deducted=salary_in.advance_deducted,
            net_salary=net_salary,
            generated_by=generator_id,
            remarks=salary_in.remarks
        )
        self.db.add(new_salary)
        await self.db.commit()
        await self.db.refresh(new_salary)
        return new_salary

    # Tasks
    async def assign_task(self, task_in: schemas.StaffTaskCreate, staff_id: uuid.UUID, assigner_id: uuid.UUID) -> models.StaffTask:
        new_task = models.StaffTask(
            staff_id=staff_id,
            assigned_by=assigner_id,
            property_id=task_in.property_id,
            task_title=task_in.task_title,
            task_description=task_in.task_description,
            related_module=task_in.related_module,
            related_record_id=task_in.related_record_id,
            priority=task_in.priority,
            due_date=task_in.due_date
        )
        self.db.add(new_task)
        await self.db.commit()
        await self.db.refresh(new_task)
        return new_task


