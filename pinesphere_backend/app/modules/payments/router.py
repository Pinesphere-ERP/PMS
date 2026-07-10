from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
import uuid
import math

from app.infra.database import get_db
from .schemas import PaymentCreate, PaymentRead, PaymentListResponse
from .service import PaymentService

router = APIRouter()

# Dependency for service
def get_payment_service(db: AsyncSession = Depends(get_db)) -> PaymentService:
    return PaymentService(db)

# Dummy dependency for user_id (since we don't have full auth wired in this snippet)
# Replace with actual auth dependency later
def get_current_user_id() -> Optional[uuid.UUID]:
    return None # Mock user ID

@router.post("/", response_model=PaymentRead, status_code=201)
async def create_payment(
    payment_data: PaymentCreate,
    service: PaymentService = Depends(get_payment_service),
    user_id: uuid.UUID = Depends(get_current_user_id)
):
    try:
        payment = await service.create_payment(payment_data, user_id)
        return payment
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=PaymentListResponse)
async def list_payments(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    service: PaymentService = Depends(get_payment_service)
):
    skip = (page - 1) * size
    payments, total = await service.list_payments(skip=skip, limit=size)
    return {
        "items": payments,
        "total": total,
        "page": page,
        "size": size
    }

@router.get("/{payment_id}", response_model=PaymentRead)
async def get_payment(
    payment_id: uuid.UUID,
    service: PaymentService = Depends(get_payment_service)
):
    payment = await service.get_payment(payment_id)
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    return payment

@router.get("/razorpay/config")
async def get_razorpay_config():
    from app.core.config import settings
    return {"key_id": settings.RAZORPAY_KEY_ID}

from .schemas import RazorpayOrderRequest, RazorpayOrderResponse, RazorpayVerifyRequest

@router.post("/razorpay/order", response_model=RazorpayOrderResponse)
async def create_razorpay_order(
    request: RazorpayOrderRequest,
    service: PaymentService = Depends(get_payment_service)
):
    try:
        order = await service.create_razorpay_order(request.amount)
        return RazorpayOrderResponse(
            razorpay_order_id=order["id"],
            amount=order["amount"]
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/razorpay/verify", response_model=PaymentRead)
async def verify_razorpay_payment(
    request: RazorpayVerifyRequest,
    service: PaymentService = Depends(get_payment_service),
    user_id: uuid.UUID = Depends(get_current_user_id)
):
    try:
        payment = await service.verify_and_record_payment(
            razorpay_order_id=request.razorpay_order_id,
            razorpay_payment_id=request.razorpay_payment_id,
            razorpay_signature=request.razorpay_signature,
            amount=request.amount,
            invoice_id=request.invoice_id,
            booking_id=request.booking_id,
            remarks=request.remarks,
            user_id=user_id,
            payment_mode=request.payment_mode,
            split_payments=request.split_payments
        )
        return payment
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        import traceback
        error_detail = "".join(traceback.format_exception(type(e), e, e.__traceback__))
        raise HTTPException(status_code=500, detail=error_detail)
