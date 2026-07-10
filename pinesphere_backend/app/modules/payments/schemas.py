from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
import uuid
from decimal import Decimal

class SplitPaymentCreate(BaseModel):
    mode: str
    amount: Decimal = Field(gt=0)

class PaymentCreate(BaseModel):
    invoice_id: Optional[uuid.UUID] = None
    booking_id: Optional[uuid.UUID] = None
    payment_mode: str
    amount: Decimal = Field(gt=0)
    upi_id: Optional[str] = None
    bank_name: Optional[str] = None
    card_last4: Optional[str] = None
    remarks: Optional[str] = None
    split_payments: Optional[List[SplitPaymentCreate]] = None

    @field_validator('split_payments', mode='after')
    @classmethod
    def validate_split_amounts(cls, v, info):
        if info.data.get('payment_mode') == 'split':
            if not v or len(v) == 0:
                raise ValueError("split_payments is required when payment_mode is split")
            total_amount = info.data.get('amount')
            split_total = sum((split.amount for split in v))
            if split_total != total_amount:
                raise ValueError("Sum of split amounts must equal the total payment amount")
        return v

    @field_validator('card_last4', mode='after')
    @classmethod
    def validate_card_last4(cls, v, info):
        mode = info.data.get('payment_mode')
        if mode in ['credit_card', 'debit_card'] and not v:
            raise ValueError("card_last4 is required for card payments")
        if v and (len(v) != 4 or not v.isdigit()):
            raise ValueError("card_last4 must be a 4-digit number")
        return v

    @field_validator('upi_id', mode='after')
    @classmethod
    def validate_upi_id(cls, v, info):
        if info.data.get('payment_mode') == 'upi' and not v:
            raise ValueError("upi_id is required for upi payments")
        return v

class PaymentRead(BaseModel):
    payment_id: uuid.UUID
    invoice_id: Optional[uuid.UUID]
    booking_id: Optional[uuid.UUID]
    transaction_id: str
    reference_number: Optional[str]
    payment_mode: str
    amount: Decimal
    upi_id: Optional[str]
    bank_name: Optional[str]
    card_last4: Optional[str]
    collected_by: Optional[uuid.UUID]
    remarks: Optional[str]
    status: str
    synced: bool
    created_at: datetime
    updated_at: Optional[datetime]

    model_config = {"from_attributes": True}

class PaymentListResponse(BaseModel):
    items: List[PaymentRead]
    total: int
    page: int
    size: int

class RazorpayOrderRequest(BaseModel):
    amount: Decimal = Field(gt=0)
    invoice_id: Optional[uuid.UUID] = None
    booking_id: Optional[uuid.UUID] = None

class RazorpayOrderResponse(BaseModel):
    razorpay_order_id: str
    amount: int  # Amount in paise

class RazorpayVerifyRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str
    invoice_id: Optional[uuid.UUID] = None
    booking_id: Optional[uuid.UUID] = None
    amount: Decimal = Field(gt=0)
    remarks: Optional[str] = None
