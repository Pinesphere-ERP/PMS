from typing import List, Optional
import uuid
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func

from app.infra.models import Payment, PaymentTransaction, SplitPayment, Invoice
from app.modules.audit.logger import AuditLogger
from .schemas import PaymentCreate, SplitPaymentCreate

class PaymentService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_payment(self, payment_data: PaymentCreate, user_id: uuid.UUID) -> Payment:
        # Validate invoice if provided
        if payment_data.invoice_id:
            invoice_result = await self.db.execute(select(Invoice).filter(Invoice.invoice_id == payment_data.invoice_id))
            invoice = invoice_result.scalar_one_or_none()
            if not invoice:
                raise ValueError("Invoice not found")
            
            # Simple check for overpayment on invoice
            # (In a real app, calculate sum of existing successful payments)
            if invoice.grand_total and payment_data.amount > invoice.grand_total:
                raise ValueError("Payment amount cannot exceed invoice total")

        # Create the Payment record
        transaction_id = f"TXN-{uuid.uuid4().hex[:8].upper()}"
        
        new_payment = Payment(
            invoice_id=payment_data.invoice_id,
            booking_id=payment_data.booking_id,
            transaction_id=transaction_id,
            payment_mode=payment_data.payment_mode,
            amount=payment_data.amount,
            upi_id=payment_data.upi_id,
            bank_name=payment_data.bank_name,
            card_last4=payment_data.card_last4,
            collected_by=user_id,
            remarks=payment_data.remarks,
            status='fully_paid', # For Phase 1, assume direct success
            synced=True # Online only for Phase 1
        )
        self.db.add(new_payment)
        await self.db.flush() # To get payment_id

        # Create PaymentTransaction (Ledger)
        txn = PaymentTransaction(
            payment_id=new_payment.payment_id,
            event='created',
            amount=payment_data.amount,
            meta_data={"source": "online_api"}
        )
        self.db.add(txn)

        # Handle split payments
        if payment_data.payment_mode == 'split' and payment_data.split_payments:
            for split in payment_data.split_payments:
                sp = SplitPayment(
                    payment_id=new_payment.payment_id,
                    mode=split.mode,
                    amount=split.amount
                )
                self.db.add(sp)

        await self.db.flush()
        await self.db.refresh(new_payment)

        await AuditLogger.log(
            self.db,
            module_name="payments",
            action_type="create_payment",
            target_entity="payment",
            target_record_id=new_payment.payment_id,
            user_id=user_id,
            property_id=getattr(new_payment, 'property_id', None),
            new_value={
                "payment_id": str(new_payment.payment_id),
                "amount": float(payment_data.amount),
                "payment_mode": payment_data.payment_mode,
                "invoice_id": str(payment_data.invoice_id) if payment_data.invoice_id else None,
            },
        )
        return new_payment

    async def list_payments(self, skip: int = 0, limit: int = 20) -> tuple[List[Payment], int]:
        result = await self.db.execute(
            select(Payment).order_by(Payment.created_at.desc()).offset(skip).limit(limit)
        )
        payments = result.scalars().all()
        
        count_result = await self.db.execute(select(func.count(Payment.payment_id)))
        total = count_result.scalar() or 0
        
        return list(payments), total

    async def get_payment(self, payment_id: uuid.UUID) -> Optional[Payment]:
        result = await self.db.execute(select(Payment).filter(Payment.payment_id == payment_id))
        return result.scalar_one_or_none()

    def get_razorpay_client(self):
        from app.core.config import settings
        import razorpay
        if not settings.RAZORPAY_KEY_ID or not settings.RAZORPAY_KEY_SECRET:
            raise ValueError("Razorpay credentials not configured")
        return razorpay.Client(auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET))

    async def create_razorpay_order(self, amount: Decimal) -> dict:
        client = self.get_razorpay_client()
        amount_in_paise = int(amount * 100)
        data = {
            "amount": amount_in_paise,
            "currency": "INR",
            "receipt": f"rcpt_{uuid.uuid4().hex[:8]}"
        }
        order = client.order.create(data=data)
        return order

    async def verify_and_record_payment(
        self, 
        razorpay_order_id: str, 
        razorpay_payment_id: str, 
        razorpay_signature: str,
        amount: Decimal,
        invoice_id: Optional[uuid.UUID],
        booking_id: Optional[uuid.UUID],
        remarks: Optional[str],
        user_id: uuid.UUID,
        payment_mode: str = 'online',
        split_payments: Optional[List[SplitPaymentCreate]] = None
    ) -> Payment:
        client = self.get_razorpay_client()
        
        # Verify signature
        try:
            client.utility.verify_payment_signature({
                'razorpay_order_id': razorpay_order_id,
                'razorpay_payment_id': razorpay_payment_id,
                'razorpay_signature': razorpay_signature
            })
        except Exception as e:
            raise ValueError(f"Razorpay signature verification failed: {str(e)}")

        # Create payment request payload for our internal method
        payment_data = PaymentCreate(
            invoice_id=invoice_id,
            booking_id=booking_id,
            payment_mode=payment_mode,
            amount=amount,
            remarks=remarks,
            split_payments=split_payments
        )

        # Call existing logic but override transaction ID
        payment = await self.create_payment(payment_data, user_id)
        payment.transaction_id = razorpay_payment_id
        
        # We can also fetch the payment from Razorpay to get card/bank details, 
        # but for Phase 1 we will just mark it as online.
        await self.db.flush()
        await self.db.refresh(payment)
        
        return payment
