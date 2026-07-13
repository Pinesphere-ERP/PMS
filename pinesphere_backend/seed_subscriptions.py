import asyncio
import uuid
import sys
import os
import random
from datetime import datetime, date, timedelta

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.infra.database import AsyncSessionLocal
from app.infra.models import (
    Owner, Business, Property, Subscription, SubscriptionTransaction, Invoice
)

async def seed_data():
    print("Starting subscription mock data seeding...")
    async with AsyncSessionLocal() as db:
        try:
            today = date.today()
            plans = ["Basic", "Professional", "Enterprise"]
            plan_prices = {"Basic": 199.0, "Professional": 499.0, "Enterprise": 999.0}

            scenarios = [
                {"name": "Active Sub 1", "status": "Active", "expiry_offset": 30, "plan": "Basic"},
                {"name": "Expiring Soon", "status": "Active", "expiry_offset": 2, "plan": "Professional"},
                {"name": "Grace Period Sub", "status": "Grace Period", "expiry_offset": -2, "plan": "Enterprise"},
                {"name": "Disabled Sub", "status": "Disabled", "expiry_offset": -15, "plan": "Basic"},
                {"name": "Expired Sub", "status": "Expired", "expiry_offset": -40, "plan": "Professional"},
                {"name": "Renewed Today", "status": "Active", "expiry_offset": 365, "plan": "Enterprise", "start_offset": 0},
            ]

            for idx, scenario in enumerate(scenarios):
                # Create Owner
                owner_id = uuid.uuid4()
                owner = Owner(
                    owner_id=owner_id,
                    full_name=f"Sub Owner {idx}",
                    mobile_number=f"555000111{idx}",
                    email=f"sub{idx}@example.com",
                )
                db.add(owner)
                
                # Create Business
                business_id = uuid.uuid4()
                business = Business(
                    business_id=business_id,
                    owner_id=owner_id,
                    business_name=f"Business {scenario['name']}"
                )
                db.add(business)

                # Create Property
                property_id = uuid.uuid4()
                prop = Property(
                    property_id=property_id,
                    business_id=business_id,
                    owner_id=owner_id,
                    property_name=f"Property {scenario['name']}",
                    property_type="Hotel",
                    onboarding_status="completed"
                )
                db.add(prop)

                # Create Subscription
                sub_id = uuid.uuid4()
                start_date = today + timedelta(days=scenario.get("start_offset", -335))
                expiry_date = today + timedelta(days=scenario["expiry_offset"])
                
                sub = Subscription(
                    id=sub_id,
                    property_id=property_id,
                    plan=scenario["plan"],
                    billing_cycle="yearly",
                    start_date=start_date,
                    expiry_date=expiry_date,
                    status=scenario["status"],
                    license_id=f"PSL-MOCK-{idx}"
                )
                db.add(sub)

                # Add some invoices and transactions to simulate revenue
                amount = plan_prices[scenario["plan"]]
                inv_id = uuid.uuid4()
                inv = Invoice(
                    invoice_id=inv_id,
                    property_id=property_id,
                    invoice_number=f"INV-SUB-{idx}",
                    date=start_date,
                    due_date=start_date + timedelta(days=7),
                    amount=amount,
                    status="Paid"
                )
                db.add(inv)
                
                tx = SubscriptionTransaction(
                    id=uuid.uuid4(),
                    payment_id=f"PAY-{idx}",
                    invoice_id=inv_id,
                    property_id=property_id,
                    amount=amount,
                    method="Credit Card",
                    status="Success"
                )
                tx.created_at = datetime.now() - timedelta(days=abs(scenario.get("start_offset", -30)))
                db.add(tx)

                # Generate a past invoice for historical data (for the bar chart)
                for month_offset in range(1, 6):
                    past_inv_id = uuid.uuid4()
                    past_inv = Invoice(
                        invoice_id=past_inv_id,
                        property_id=property_id,
                        invoice_number=f"INV-SUB-PAST-{idx}-{month_offset}",
                        date=today - timedelta(days=30 * month_offset),
                        due_date=today - timedelta(days=30 * month_offset - 7),
                        amount=amount / 12, # fake monthly revenue
                        status="Paid"
                    )
                    db.add(past_inv)

            await db.commit()
            print("Successfully seeded subscriptions mock data.")
            
        except Exception as e:
            await db.rollback()
            import traceback
            print("Error seeding data:")
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(seed_data())
