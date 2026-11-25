"""Subscriptions (checklist §14) — DATA MODEL + API ONLY.

NO real payments: there is no payment gateway integration, no card
details are ever requested or stored, and NOTHING is ever charged.

Plans (from the checklist's pricing hypotheses):
- PERSONAL_BASIC — free. Emergency guidance is NEVER paywalled.
- PERSONAL_PREMIUM — ₹99–199/month (hypothesis).
- FAMILY_PREMIUM — ₹199–299/month (hypothesis).

All prices are explicitly marked "hypothesis — market testing pending,
no payment charged". Subscribing to a paid plan creates a subscription
with status "pending_payment" and valid_until 30 days out; it does NOT
activate paid access, because no payment has (or can) be taken.
PERSONAL_BASIC activates immediately because it is free.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, roles, schemas
from app.db import get_db

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])

HYPOTHESIS_NOTE = "Hypothesis — market testing pending, no payment charged."

PLANS = {
    "PERSONAL_BASIC": {
        "price_text": "Free",
        "description": (
            "Free forever. Emergency guidance is never paywalled: 112 "
            "emergency mode, first-aid guides and danger-sign triage are "
            "available to everyone."
        ),
    },
    "PERSONAL_PREMIUM": {
        "price_text": "₹99–199/month (" + HYPOTHESIS_NOTE + ")",
        "description": (
            "Premium personal plan (pricing hypothesis only). No payment "
            "is charged and no card details are collected."
        ),
    },
    "FAMILY_PREMIUM": {
        "price_text": "₹199–299/month (" + HYPOTHESIS_NOTE + ")",
        "description": (
            "Family plan with Family Relay (pricing hypothesis only). No "
            "payment is charged and no card details are collected."
        ),
    },
}

FREE_PLAN = "PERSONAL_BASIC"


@router.get("/plans", response_model=list[schemas.SubscriptionPlanInfo])
def list_plans():
    """Public: the available plans and their (hypothetical) prices."""
    return [
        schemas.SubscriptionPlanInfo(
            plan=plan, price_text=info["price_text"], description=info["description"]
        )
        for plan, info in PLANS.items()
    ]


@router.get("/me", response_model=schemas.SubscriptionResponse)
def my_subscription(
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    sub = (
        db.query(models.Subscription)
        .filter(models.Subscription.user_id == user.id)
        .first()
    )
    if not sub:
        raise HTTPException(status_code=404, detail="No subscription yet")
    return schemas.SubscriptionResponse(
        plan=sub.plan,
        status=sub.status,
        started_at=sub.started_at,
        valid_until=sub.valid_until,
    )


@router.post("/subscribe", response_model=schemas.SubscriptionResponse)
def subscribe(
    payload: schemas.SubscriptionSubscribe,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Subscribe (or switch plan). NEVER charges anything.

    Paid plans get status "pending_payment" with valid_until 30 days out
    — they do NOT become active, because no payment exists. The free
    PERSONAL_BASIC plan activates immediately.
    """
    plan = (payload.plan or "").strip().upper()
    if plan not in PLANS:
        raise HTTPException(
            status_code=400,
            detail=f"plan must be one of: {', '.join(sorted(PLANS))}",
        )
    sub = (
        db.query(models.Subscription)
        .filter(models.Subscription.user_id == user.id)
        .first()
    )
    now = datetime.now(timezone.utc)
    if plan == FREE_PLAN:
        status, valid_until = "active", None
    else:
        status, valid_until = "pending_payment", now + timedelta(days=30)
    if not sub:
        sub = models.Subscription(
            user_id=user.id, plan=plan, status=status,
            started_at=now, valid_until=valid_until,
        )
        db.add(sub)
    else:
        sub.plan = plan
        sub.status = status
        sub.started_at = now
        sub.valid_until = valid_until
    db.commit()
    db.refresh(sub)
    return schemas.SubscriptionResponse(
        plan=sub.plan,
        status=sub.status,
        started_at=sub.started_at,
        valid_until=sub.valid_until,
    )


@router.post("/cancel", response_model=schemas.SubscriptionResponse)
def cancel(
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Cancel the caller's subscription. Emergency guidance is never
    paywalled, so cancelling never removes emergency features."""
    sub = (
        db.query(models.Subscription)
        .filter(models.Subscription.user_id == user.id)
        .first()
    )
    if not sub:
        raise HTTPException(status_code=404, detail="No subscription yet")
    sub.status = "cancelled"
    db.commit()
    db.refresh(sub)
    return schemas.SubscriptionResponse(
        plan=sub.plan,
        status=sub.status,
        started_at=sub.started_at,
        valid_until=sub.valid_until,
    )
