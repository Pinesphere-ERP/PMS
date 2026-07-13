import asyncio
import uuid
import json
from datetime import date, datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.infra.models import (
    Property, User, Role, Device, UserDevice, UserSession,
    StaffInvitation, CredentialResetRequest, UserSyncLog, RoomCategory, Room, Guest, Booking, CheckIn, CheckOut,
    Invoice, Payment, Subscription, SubscriptionTransaction, PaymentTransaction, PendingDue, InvoiceItem, SplitPayment,
    DailyKPISnapshot, ReportTemplate, ScheduledReport, SystemConfiguration, PropertySetting, RoomAssignment,
    HousekeepingTask, MaintenanceTicket, LostAndFound
)

async def seed_missing_tables():
    engine = create_async_engine("sqlite+aiosqlite:///./pinesphere.db", echo=True)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        async with session.begin():
            # Get existing data for foreign keys
            stmt_prop = select(Property).limit(1)
            prop = (await session.execute(stmt_prop)).scalar_one_or_none()
            if not prop:
                print("No property found. Please run seed.py first.")
                return
            
            stmt_user = select(User).limit(1)
            user = (await session.execute(stmt_user)).scalar_one_or_none()
            
            stmt_room = select(Room).limit(1)
            room = (await session.execute(stmt_room)).scalar_one_or_none()
            
            stmt_device = select(Device).limit(1)
            device = (await session.execute(stmt_device)).scalar_one_or_none()
            if not device and user:
                device = Device(id=uuid.uuid4(), device_uid="dev-"+str(uuid.uuid4())[:8], property_id=prop.property_id, primary_user_id=user.id, device_name="Test Phone", status="active")
                session.add(device)
                await session.flush()
            
            stmt_role = select(Role).limit(1)
            role = (await session.execute(stmt_role)).scalar_one_or_none()
            
            now = datetime.now(timezone.utc)
            today = date.today()

            # 1. UserDevice
            if user and device:
                stmt = select(UserDevice).limit(1)
                if not (await session.execute(stmt)).scalar_one_or_none():
                    session.add(UserDevice(id=uuid.uuid4(), user_id=user.id, device_id=device.id))
            
            # 2. UserSession
            if user and device:
                stmt = select(UserSession).limit(1)
                if not (await session.execute(stmt)).scalar_one_or_none():
                    session.add(UserSession(
                        id=uuid.uuid4(), user_id=user.id, device_id=device.id,
                        session_token="mock_session_token_" + str(uuid.uuid4()),
                        expires_at=now + timedelta(days=1)
                    ))
            
            # 3. StaffInvitation
            if user and role:
                stmt = select(StaffInvitation).limit(1)
                if not (await session.execute(stmt)).scalar_one_or_none():
                    session.add(StaffInvitation(
                        id=uuid.uuid4(), property_id=prop.property_id, role_id=role.id,
                        invited_by=user.id, mobile_number="9999999998", invitation_token="inv_tok_" + str(uuid.uuid4()),
                        expires_at=now + timedelta(days=7)
                    ))
            
            # 4. CredentialResetRequest
            if user:
                stmt = select(CredentialResetRequest).limit(1)
                if not (await session.execute(stmt)).scalar_one_or_none():
                    session.add(CredentialResetRequest(
                        id=uuid.uuid4(), user_id=user.id, reset_type="password", requested_via="email"
                    ))
            
            # 5. UserSyncLog
            if user:
                stmt = select(UserSyncLog).limit(1)
                if not (await session.execute(stmt)).scalar_one_or_none():
                    session.add(UserSyncLog(
                        id=uuid.uuid4(), entity_type="User", entity_id=user.id,
                        operation="CREATE", payload=json.dumps({"name": "mock"})
                    ))
            
            # 6. Guest
            stmt_guest = select(Guest).limit(1)
            guest = (await session.execute(stmt_guest)).scalar_one_or_none()
            if not guest:
                guest = Guest(guest_id=uuid.uuid4(), full_name="Mock Guest", mobile="8888888888", email="guest@mock.com")
                session.add(guest)
                await session.flush()
                
            # 7. Booking
            stmt_booking = select(Booking).limit(1)
            booking = (await session.execute(stmt_booking)).scalar_one_or_none()
            if not booking and room:
                booking = Booking(
                    booking_id=uuid.uuid4(), property_id=prop.property_id, room_id=room.room_id, guest_id=guest.guest_id,
                    check_in_date=today, check_out_date=today + timedelta(days=2),
                    total_payable=200.0, pending_amount=200.0
                )
                session.add(booking)
                await session.flush()
                
            # 8. CheckIn
            stmt_checkin = select(CheckIn).limit(1)
            checkin = (await session.execute(stmt_checkin)).scalar_one_or_none()
            if not checkin and booking and room:
                checkin = CheckIn(
                    checkin_id=uuid.uuid4(), booking_id=booking.booking_id, room_id=room.room_id,
                    guest_id=guest.guest_id, property_id=prop.property_id, staff_id=user.id if user else None,
                    checked_in_at=now
                )
                session.add(checkin)
                await session.flush()
                
            # 9. CheckOut
            stmt_checkout = select(CheckOut).limit(1)
            checkout = (await session.execute(stmt_checkout)).scalar_one_or_none()
            if not checkout and checkin and booking and room:
                checkout = CheckOut(
                    checkout_id=uuid.uuid4(), checkin_id=checkin.checkin_id, booking_id=booking.booking_id,
                    room_id=room.room_id, property_id=prop.property_id, staff_id=user.id if user else None,
                    checkout_time=now + timedelta(days=2)
                )
                session.add(checkout)
                
            # 10. RoomAssignment
            stmt_ra = select(RoomAssignment).limit(1)
            if not (await session.execute(stmt_ra)).scalar_one_or_none() and booking and room:
                session.add(RoomAssignment(
                    assignment_id=uuid.uuid4(), booking_id=booking.booking_id, room_id=room.room_id,
                    guest_id=guest.guest_id, assigned_at=now
                ))
                
            # 11. HousekeepingTask
            stmt_hk = select(HousekeepingTask).limit(1)
            if not (await session.execute(stmt_hk)).scalar_one_or_none() and room:
                session.add(HousekeepingTask(
                    task_id=uuid.uuid4(), room_id=room.room_id, property_id=prop.property_id,
                    assigned_staff_id=user.id if user else None, checklist_status=json.dumps({"clean_bed": True})
                ))
                
            # 12. MaintenanceTicket
            stmt_mt = select(MaintenanceTicket).limit(1)
            if not (await session.execute(stmt_mt)).scalar_one_or_none() and room:
                session.add(MaintenanceTicket(
                    ticket_id=uuid.uuid4(), room_id=room.room_id, property_id=prop.property_id,
                    category="Plumbing", issue_description="Leaking tap"
                ))
                
            # 13. LostAndFound
            stmt_laf = select(LostAndFound).limit(1)
            if not (await session.execute(stmt_laf)).scalar_one_or_none() and room:
                session.add(LostAndFound(
                    item_id=uuid.uuid4(), room_id=room.room_id, property_id=prop.property_id,
                    description="Wallet left on the bed"
                ))
                
            # 14. Invoice
            stmt_inv = select(Invoice).limit(1)
            invoice = (await session.execute(stmt_inv)).scalar_one_or_none()
            if not invoice and booking:
                invoice = Invoice(
                    invoice_id=uuid.uuid4(), booking_id=booking.booking_id, property_id=prop.property_id,
                    guest_id=guest.guest_id, invoice_number="INV-001", date=today, due_date=today, amount=200.0
                )
                session.add(invoice)
                await session.flush()
                
            # 15. InvoiceItem
            stmt_inv_item = select(InvoiceItem).limit(1)
            if not (await session.execute(stmt_inv_item)).scalar_one_or_none() and invoice:
                session.add(InvoiceItem(
                    item_id=uuid.uuid4(), invoice_id=invoice.invoice_id, description="Room Rent", unit_price=200.0, total_price=200.0
                ))
                
            # 16. Payment
            stmt_payment = select(Payment).limit(1)
            payment = (await session.execute(stmt_payment)).scalar_one_or_none()
            if not payment and invoice and booking:
                payment = Payment(
                    payment_id=uuid.uuid4(), invoice_id=invoice.invoice_id, booking_id=booking.booking_id,
                    transaction_id="TXN-001", payment_mode="card", amount=200.0, collected_by=user.id if user else None
                )
                session.add(payment)
                await session.flush()
                
            # 17. PaymentTransaction
            stmt_ptxn = select(PaymentTransaction).limit(1)
            if not (await session.execute(stmt_ptxn)).scalar_one_or_none() and payment:
                session.add(PaymentTransaction(
                    txn_id=uuid.uuid4(), payment_id=payment.payment_id, event="collected", amount=200.0, meta_data=json.dumps({"method":"card"})
                ))
                
            # 18. SplitPayment
            stmt_split = select(SplitPayment).limit(1)
            if not (await session.execute(stmt_split)).scalar_one_or_none() and payment:
                session.add(SplitPayment(
                    split_id=uuid.uuid4(), payment_id=payment.payment_id, mode="cash", amount=50.0
                ))
                
            # 19. SubscriptionTransaction
            stmt_sub_txn = select(SubscriptionTransaction).limit(1)
            if not (await session.execute(stmt_sub_txn)).scalar_one_or_none() and invoice:
                session.add(SubscriptionTransaction(
                    id=uuid.uuid4(), payment_id="SUB-TXN-001", invoice_id=invoice.invoice_id, property_id=prop.property_id, amount=100.0
                ))
                
            # 20. PendingDue
            stmt_due = select(PendingDue).limit(1)
            if not (await session.execute(stmt_due)).scalar_one_or_none():
                session.add(PendingDue(
                    id=uuid.uuid4(), property_id=prop.property_id, plan="Enterprise", due_date=today, amount_due=100.0
                ))
                
            # 21. DailyKPISnapshot
            stmt_kpi = select(DailyKPISnapshot).limit(1)
            if not (await session.execute(stmt_kpi)).scalar_one_or_none():
                session.add(DailyKPISnapshot(
                    snapshot_id=uuid.uuid4(), property_id=prop.property_id, snapshot_date=today
                ))
                
            # 22. ReportTemplate
            stmt_rep_temp = select(ReportTemplate).limit(1)
            rep_temp = (await session.execute(stmt_rep_temp)).scalar_one_or_none()
            if not rep_temp:
                rep_temp = ReportTemplate(
                    template_id=uuid.uuid4(), property_id=prop.property_id, report_name="Daily Revenue", report_type="revenue"
                )
                session.add(rep_temp)
                await session.flush()
                
            # 23. ScheduledReport
            stmt_sch_rep = select(ScheduledReport).limit(1)
            if not (await session.execute(stmt_sch_rep)).scalar_one_or_none() and rep_temp:
                session.add(ScheduledReport(
                    schedule_id=uuid.uuid4(), template_id=rep_temp.template_id, recipient_role="owner", delivery_channel="email", frequency="daily"
                ))
                
            # 24. SystemConfiguration
            stmt_sys_config = select(SystemConfiguration).limit(1)
            if not (await session.execute(stmt_sys_config)).scalar_one_or_none():
                session.add(SystemConfiguration(
                    id=uuid.uuid4(), config_key="mock_key_" + str(uuid.uuid4())[:4], config_value=json.dumps({"val": 1})
                ))
                
            # 25. PropertySetting
            stmt_prop_setting = select(PropertySetting).limit(1)
            if not (await session.execute(stmt_prop_setting)).scalar_one_or_none():
                session.add(PropertySetting(
                    id=uuid.uuid4(), property_id=prop.property_id, setting_key="mock_prop_key_" + str(uuid.uuid4())[:4], setting_value=json.dumps({"val": 1})
                ))

            await session.commit()
            print("Mock data seeded for all missing tables successfully!")

if __name__ == "__main__":
    asyncio.run(seed_missing_tables())
