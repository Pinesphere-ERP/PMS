"""
Subscription paywall gate (§14).

Adds a FastAPI dependency `require_active_subscription` that blocks all
property-level API calls when a property's subscription has lapsed or
does not exist.  Super Admin is always exempt (they manage subscriptions).

Usage in a router file:
    from app.core.subscription_gate import require_active_subscription
    router = APIRouter(dependencies=[Depends(require_active_subscription)])
"""
from fastapi import Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import date
import uuid

from app.infra.database import get_db
from app.infra.models import Subscription, User
from app.core.dependencies import get_current_user, get_current_role


async def require_active_subscription(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """
    Block requests to property-level endpoints when the property's
    subscription is expired, suspended, or absent.

    F-11 fix: the gate is subscription-scoped (per property_id), not
    Owner-scoped.  A lapsed A1 subscription must NOT block A2 or B1.
    Super Admin is always exempt.
    """
    role = await get_current_role(current_user, db)
    # Super Admin is exempt — they manage subscriptions
    if role.role_code == "SUPER_ADMIN":
        return

    # Resolve the active property for this request
    property_id: uuid.UUID | None = getattr(current_user, "active_property_id", None) or current_user.property_id
    if property_id is None:
        # No property context (e.g. OWNER checking aggregate) — skip paywall
        return

    sub_res = await db.execute(
        select(Subscription).where(
            Subscription.property_id == property_id,
        ).order_by(Subscription.expiry_date.desc())
    )
    subscription = sub_res.scalars().first()

    if subscription is None:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=(
                "No active subscription found for this property. "
                "Please subscribe to access the platform features (§14)."
            ),
        )

    if subscription.status not in ("Active", "active"):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=(
                f"Subscription for this property is '{subscription.status}'. "
                "Please renew your subscription to continue (§14)."
            ),
        )

    if subscription.expiry_date < date.today():
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=(
                f"Subscription expired on {subscription.expiry_date}. "
                "Please renew your subscription to continue (§14)."
            ),
        )
