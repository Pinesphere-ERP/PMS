"""
Broker Commission Engine — Commission rules, wallet, accrual, reversal, and payouts.
"""
import uuid
from datetime import date
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update

from app.infra.database import get_db
from app.infra.models import (
    BrokerCommissionRule, BrokerWallet, CommissionTransaction, CommissionPayout, User
)
from app.core.dependencies import get_current_user, assert_property_access, require_super_admin

router = APIRouter()


# ──────────────────────────────────────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────────────────────────────────────

class CommissionRuleCreate(BaseModel):
    broker_user_id: uuid.UUID
    rate_percent: float
    effective_from: date
    effective_until: Optional[date] = None

class PayoutCreate(BaseModel):
    broker_user_id: uuid.UUID
    property_id: uuid.UUID
    amount: float
    mode: str  # bank_transfer, upi, cash
    reference: Optional[str] = None


# ──────────────────────────────────────────────────────────────────────────────
# Commission Rules
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/rules", status_code=status.HTTP_201_CREATED)
async def create_commission_rule(
    property_id: uuid.UUID = Query(...),
    req: CommissionRuleCreate = ...,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a commission rate for a broker at this property."""
    await assert_property_access(property_id, current_user, db)

    rule = BrokerCommissionRule(
        id=uuid.uuid4(),
        property_id=property_id,
        broker_user_id=req.broker_user_id,
        rate_percent=req.rate_percent,
        effective_from=req.effective_from,
        effective_until=req.effective_until,
        created_by=current_user.id,
    )
    db.add(rule)
    return {"id": str(rule.id), "message": "Commission rule created."}


@router.get("/rules")
async def list_commission_rules(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = select(BrokerCommissionRule).where(BrokerCommissionRule.property_id == property_id)
    result = await db.execute(stmt)
    rules = result.scalars().all()
    return [
        {
            "id": str(r.id),
            "broker_user_id": str(r.broker_user_id),
            "rate_percent": float(r.rate_percent),
            "effective_from": str(r.effective_from),
            "effective_until": str(r.effective_until) if r.effective_until else None,
            "is_active": r.is_active,
        }
        for r in rules
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Wallet
# ──────────────────────────────────────────────────────────────────────────────

async def _get_or_create_wallet(
    db: AsyncSession,
    broker_user_id: uuid.UUID,
    property_id: uuid.UUID,
) -> BrokerWallet:
    stmt = select(BrokerWallet).where(
        BrokerWallet.broker_user_id == broker_user_id,
        BrokerWallet.property_id == property_id,
    )
    result = await db.execute(stmt)
    wallet = result.scalars().first()
    if not wallet:
        wallet = BrokerWallet(
            id=uuid.uuid4(),
            broker_user_id=broker_user_id,
            property_id=property_id,
            balance=0.0,
        )
        db.add(wallet)
        await db.flush()
    return wallet


@router.get("/wallet")
async def get_my_wallet(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get the broker's wallet balance for this property."""
    wallet = await _get_or_create_wallet(db, current_user.id, property_id)
    return {
        "broker_user_id": str(wallet.broker_user_id),
        "property_id": str(wallet.property_id),
        "balance": float(wallet.balance),
        "currency": wallet.currency,
    }


@router.get("/transactions")
async def list_transactions(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List commission transactions for the authenticated broker."""
    wallet = await _get_or_create_wallet(db, current_user.id, property_id)
    stmt = (
        select(CommissionTransaction)
        .where(CommissionTransaction.broker_wallet_id == wallet.id)
        .order_by(CommissionTransaction.created_at.desc())
    )
    result = await db.execute(stmt)
    txns = result.scalars().all()
    return [
        {
            "id": str(t.id),
            "type": t.txn_type,
            "amount": float(t.amount),
            "rate_applied": float(t.rate_applied),
            "booking_id": str(t.booking_id) if t.booking_id else None,
            "note": t.note,
        }
        for t in txns
    ]


# ──────────────────────────────────────────────────────────────────────────────
# Internal: Accrue commission on payment (called from payments service)
# ──────────────────────────────────────────────────────────────────────────────

async def accrue_commission(
    db: AsyncSession,
    property_id: uuid.UUID,
    booking_id: uuid.UUID,
    payment_id: uuid.UUID,
    payment_amount: float,
) -> None:
    """
    Called after a guest payment is confirmed.
    Only accrues commission when the booking was sourced through a broker
    (booking.booking_source == 'broker').  A direct / walk-in booking must
    NEVER generate a commission transaction regardless of whether a
    commission rule exists for the property (§29.7 rule 2).
    """
    from app.infra.models import Booking
    booking_stmt = select(Booking).where(Booking.booking_id == booking_id)
    booking_res = await db.execute(booking_stmt)
    booking = booking_res.scalars().first()
    if not booking:
        return

    # ── Guard: only broker-sourced bookings generate commission ───────────────
    if booking.booking_source != "broker":
        return  # Direct / walk-in / OTA booking — no commission (§29.7 rule 2)

    # ── Identify the broker who sourced this specific booking ─────────────────
    # The broker's user_id must be stored on the booking itself.  We look it up
    # via the BrokerCommissionRule table filtered to both this property AND the
    # broker linked to this booking (stored in booking.broker_user_id).
    broker_user_id = getattr(booking, "broker_user_id", None)
    if not broker_user_id:
        # No broker linked — safety net; should not happen for booking_source='broker'
        return

    # ── Select the active rule for THIS broker at THIS property ───────────────
    rule_stmt = (
        select(BrokerCommissionRule)
        .where(
            BrokerCommissionRule.property_id == property_id,
            BrokerCommissionRule.broker_user_id == broker_user_id,  # F-03 fix
            BrokerCommissionRule.is_active == True,
            BrokerCommissionRule.effective_from <= date.today(),
        )
        .order_by(BrokerCommissionRule.effective_from.desc())
    )
    rule_res = await db.execute(rule_stmt)
    rule = rule_res.scalars().first()
    if not rule:
        return  # No commission rule for this broker — skip

    commission_amount = round(payment_amount * float(rule.rate_percent) / 100, 2)
    if commission_amount <= 0:
        return

    wallet = await _get_or_create_wallet(db, rule.broker_user_id, property_id)
    wallet.balance = float(wallet.balance) + commission_amount

    txn = CommissionTransaction(
        id=uuid.uuid4(),
        broker_wallet_id=wallet.id,
        booking_id=booking_id,
        payment_id=payment_id,
        txn_type="accrual",
        amount=commission_amount,
        rate_applied=float(rule.rate_percent),
        note=f"Auto-accrual on payment {str(payment_id)[:8]}",
    )
    db.add(txn)
    await db.flush()


async def reverse_commission(
    db: AsyncSession,
    property_id: uuid.UUID,
    booking_id: uuid.UUID,
) -> None:
    """Reverse any accrued commission when a booking is cancelled."""
    stmt = (
        select(CommissionTransaction)
        .where(
            CommissionTransaction.booking_id == booking_id,
            CommissionTransaction.txn_type == "accrual",
        )
    )
    result = await db.execute(stmt)
    accruals = result.scalars().all()

    for accrual in accruals:
        wallet_stmt = select(BrokerWallet).where(BrokerWallet.id == accrual.broker_wallet_id)
        wallet_res = await db.execute(wallet_stmt)
        wallet = wallet_res.scalars().first()
        if wallet:
            wallet.balance = max(0.0, float(wallet.balance) - float(accrual.amount))

        reversal = CommissionTransaction(
            id=uuid.uuid4(),
            broker_wallet_id=accrual.broker_wallet_id,
            booking_id=booking_id,
            txn_type="reversal",
            amount=float(accrual.amount),
            rate_applied=float(accrual.rate_applied),
            note=f"Reversal — booking {str(booking_id)[:8]} cancelled",
        )
        db.add(reversal)
    await db.flush()


# ──────────────────────────────────────────────────────────────────────────────
# Payouts
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/payouts", status_code=status.HTTP_201_CREATED)
async def initiate_payout(
    req: PayoutCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Owner or Super Admin initiates a broker commission payout."""
    await assert_property_access(req.property_id, current_user, db)

    wallet = await _get_or_create_wallet(db, req.broker_user_id, req.property_id)
    if float(wallet.balance) < req.amount:
        raise HTTPException(status_code=400, detail=f"Insufficient wallet balance. Available: {wallet.balance}")

    wallet.balance = float(wallet.balance) - req.amount

    payout = CommissionPayout(
        id=uuid.uuid4(),
        broker_user_id=req.broker_user_id,
        property_id=req.property_id,
        amount=req.amount,
        mode=req.mode,
        reference=req.reference,
        status="processing",
        initiated_by=current_user.id,
    )
    db.add(payout)
    return {"id": str(payout.id), "message": "Payout initiated.", "amount": req.amount}


@router.get("/payouts")
async def list_payouts(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = (
        select(CommissionPayout)
        .where(CommissionPayout.property_id == property_id)
        .order_by(CommissionPayout.created_at.desc())
    )
    result = await db.execute(stmt)
    payouts = result.scalars().all()
    return [
        {
            "id": str(p.id),
            "broker_user_id": str(p.broker_user_id),
            "amount": float(p.amount),
            "mode": p.mode,
            "status": p.status,
            "initiated_by": str(p.initiated_by) if p.initiated_by else None,
        }
        for p in payouts
    ]
