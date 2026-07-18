"""
Pricing Rule Engine — evaluates active pricing rules for a property
and computes the final room rate for a given booking window.
"""
from __future__ import annotations

import uuid
from datetime import date
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.infra.models import PricingRule


async def evaluate_price(
    db: AsyncSession,
    property_id: uuid.UUID,
    check_in: date,
    check_out: date,
    base_price: float,
) -> dict:
    """
    Run all active pricing rules for this property against the booking window.

    Returns:
        {
            "final_price": float,       # per-night rate after rules
            "total": float,             # final_price * nights
            "nights": int,
            "applied_rules": list[str], # names of rules that fired
            "base_price": float,
        }
    """
    nights = max(1, (check_out - check_in).days)

    # Fetch active rules ordered by priority (lowest number = highest priority)
    stmt = (
        select(PricingRule)
        .where(
            PricingRule.property_id == property_id,
            PricingRule.is_active == True,
        )
        .order_by(PricingRule.priority.asc())
    )
    result = await db.execute(stmt)
    rules: List[PricingRule] = result.scalars().all()

    applied_rules: list[str] = []
    final_price = base_price

    for rule in rules:
        if not _is_rule_applicable(rule, check_in, check_out):
            continue

        # Apply multiplier (e.g. 1.2 = +20%, 0.9 = -10%)
        if rule.multiplier and rule.multiplier != 1.0:
            final_price = final_price * float(rule.multiplier)
            applied_rules.append(f"{rule.name} (×{rule.multiplier})")

        # Apply flat adjustment (additive, e.g. +500 peak surcharge)
        if rule.flat_adjustment:
            final_price = final_price + float(rule.flat_adjustment)
            applied_rules.append(f"{rule.name} (+{rule.flat_adjustment})")

    final_price = round(max(0.0, final_price), 2)
    total = round(final_price * nights, 2)

    return {
        "base_price": base_price,
        "final_price": final_price,
        "nights": nights,
        "total": total,
        "applied_rules": applied_rules,
    }


def _is_rule_applicable(rule: PricingRule, check_in: date, check_out: date) -> bool:
    """Return True if this rule applies to the given booking window."""
    today = check_in  # evaluate from check-in perspective

    # Date range check
    if rule.effective_from and today < rule.effective_from:
        return False
    if rule.effective_until and today > rule.effective_until:
        return False

    # Days-of-week check (stored as "0,1,2,3,4,5,6" where 0=Mon)
    if rule.days_of_week:
        allowed_days = {int(d.strip()) for d in rule.days_of_week.split(",") if d.strip().isdigit()}
        # Rule fires if ANY night of the booking falls on an allowed day
        current = check_in
        matched = False
        while current < check_out:
            if current.weekday() in allowed_days:
                matched = True
                break
            from datetime import timedelta
            current = current + timedelta(days=1)
        if not matched:
            return False

    # Additional condition_json checks (extensible)
    if rule.condition_json:
        # Supported keys: min_nights, max_nights, advance_days
        nights = (check_out - check_in).days
        cond = rule.condition_json

        min_nights = cond.get("min_nights")
        if min_nights is not None and nights < int(min_nights):
            return False

        max_nights = cond.get("max_nights")
        if max_nights is not None and nights > int(max_nights):
            return False

        advance_days = cond.get("advance_days")
        if advance_days is not None:
            from datetime import date as date_cls
            days_ahead = (check_in - date_cls.today()).days
            if days_ahead < int(advance_days):
                return False

    return True
