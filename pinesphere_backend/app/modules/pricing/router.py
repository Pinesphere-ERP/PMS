import uuid
from datetime import date
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.database import get_db
from app.infra.models import PricingRule, User
from app.core.dependencies import get_current_user, assert_property_access, require_super_admin
from app.modules.pricing.engine import evaluate_price

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class PricingRuleCreate(BaseModel):
    name: str
    rule_type: str  # weekend, seasonal, early_bird, last_minute, promo, custom
    multiplier: float = 1.0
    flat_adjustment: Optional[float] = None
    priority: int = 10
    effective_from: Optional[date] = None
    effective_until: Optional[date] = None
    days_of_week: Optional[str] = None  # e.g. "5,6" for Sat,Sun
    condition_json: Optional[dict] = None
    is_active: bool = True

class PricingRuleUpdate(BaseModel):
    name: Optional[str] = None
    rule_type: Optional[str] = None
    multiplier: Optional[float] = None
    flat_adjustment: Optional[float] = None
    priority: Optional[int] = None
    effective_from: Optional[date] = None
    effective_until: Optional[date] = None
    days_of_week: Optional[str] = None
    condition_json: Optional[dict] = None
    is_active: Optional[bool] = None

class PricingRuleResponse(BaseModel):
    id: uuid.UUID
    property_id: uuid.UUID
    name: str
    rule_type: str
    multiplier: float
    flat_adjustment: Optional[float]
    priority: int
    effective_from: Optional[date]
    effective_until: Optional[date]
    days_of_week: Optional[str]
    condition_json: Optional[dict]
    is_active: bool

    class Config:
        from_attributes = True


# ── CRUD Endpoints ────────────────────────────────────────────────────────────

@router.post("", response_model=PricingRuleResponse, status_code=status.HTTP_201_CREATED)
async def create_pricing_rule(
    property_id: uuid.UUID = Query(...),
    req: PricingRuleCreate = ...,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new pricing rule. Rejects duplicate priority within the same property."""
    await assert_property_access(property_id, current_user, db)

    # Conflict check: same priority + overlapping date range within same property
    conflict_stmt = select(PricingRule).where(
        PricingRule.property_id == property_id,
        PricingRule.priority == req.priority,
        PricingRule.is_active == True,
    )
    conflict_res = await db.execute(conflict_stmt)
    if conflict_res.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"An active pricing rule with priority {req.priority} already exists for this property. Use a different priority.",
        )

    rule = PricingRule(
        id=uuid.uuid4(),
        property_id=property_id,
        name=req.name,
        rule_type=req.rule_type,
        multiplier=req.multiplier,
        flat_adjustment=req.flat_adjustment,
        priority=req.priority,
        effective_from=req.effective_from,
        effective_until=req.effective_until,
        days_of_week=req.days_of_week,
        condition_json=req.condition_json,
        is_active=req.is_active,
        created_by=current_user.id,
    )
    db.add(rule)
    await db.refresh(rule)
    return rule


@router.get("", response_model=List[PricingRuleResponse])
async def list_pricing_rules(
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = select(PricingRule).where(PricingRule.property_id == property_id).order_by(PricingRule.priority)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.patch("/{rule_id}", response_model=PricingRuleResponse)
async def update_pricing_rule(
    rule_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    req: PricingRuleUpdate = ...,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = select(PricingRule).where(PricingRule.id == rule_id, PricingRule.property_id == property_id)
    result = await db.execute(stmt)
    rule = result.scalars().first()
    if not rule:
        raise HTTPException(status_code=404, detail="Pricing rule not found")

    update_data = req.model_dump(exclude_unset=True)

    # Conflict check on priority change
    if "priority" in update_data and update_data["priority"] != rule.priority:
        conflict = await db.execute(
            select(PricingRule).where(
                PricingRule.property_id == property_id,
                PricingRule.priority == update_data["priority"],
                PricingRule.is_active == True,
                PricingRule.id != rule_id,
            )
        )
        if conflict.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Priority {update_data['priority']} already in use.",
            )

    for key, value in update_data.items():
        setattr(rule, key, value)

    await db.refresh(rule)
    return rule


@router.delete("/{rule_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pricing_rule(
    rule_id: uuid.UUID,
    property_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await assert_property_access(property_id, current_user, db)
    stmt = select(PricingRule).where(PricingRule.id == rule_id, PricingRule.property_id == property_id)
    result = await db.execute(stmt)
    rule = result.scalars().first()
    if not rule:
        raise HTTPException(status_code=404, detail="Pricing rule not found")
    await db.delete(rule)


# ── Quote API ─────────────────────────────────────────────────────────────────

@router.get("/quote")
async def get_pricing_quote(
    property_id: uuid.UUID = Query(...),
    check_in: date = Query(...),
    check_out: date = Query(...),
    base_price: float = Query(..., gt=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Run the pricing engine and return a full breakdown of how the final price
    was computed, including which rules applied.
    """
    await assert_property_access(property_id, current_user, db)
    if check_out <= check_in:
        raise HTTPException(status_code=400, detail="check_out must be after check_in")

    result = await evaluate_price(db, property_id, check_in, check_out, base_price)
    return result
