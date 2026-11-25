"""LifeCard — one emergency medical card per user.

The QR code on a LifeCard must encode the PUBLIC TOKEN URL
(/lifecard/public/{token}), NEVER the medical data itself.

Public endpoint returns ONLY non-sensitive fields (blood group, allergies,
conditions, and — only when the user enabled sharing — emergency contact
names + phones). Medications, insurance and notes are NEVER public.
"""
import secrets
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import get_db
from app import models, schemas, utils

router = APIRouter(prefix="/lifecard", tags=["lifecard"])


def _new_token() -> str:
    return secrets.token_urlsafe(24)


def _to_response(card: models.LifeCard) -> schemas.LifeCardResponse:
    return schemas.LifeCardResponse(
        blood_group=card.blood_group,
        allergies=card.allergies,
        conditions=card.conditions,
        medications=card.medications,
        notes=card.notes,
        preferred_hospital=card.preferred_hospital,
        insurance=card.insurance,
        share_with_contacts=card.share_with_contacts,
        share_token=card.share_token,
    )


@router.get("", response_model=schemas.LifeCardResponse)
def get_lifecard(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id),
):
    card = db.query(models.LifeCard).filter(
        models.LifeCard.user_id == current_user_id
    ).first()
    if not card:
        raise HTTPException(status_code=404, detail="No LifeCard yet — create one with PUT /lifecard")
    return _to_response(card)


@router.put("", response_model=schemas.LifeCardResponse)
def upsert_lifecard(
    payload: schemas.LifeCardUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id),
):
    """Create or update the caller's LifeCard (one per user)."""
    card = db.query(models.LifeCard).filter(
        models.LifeCard.user_id == current_user_id
    ).first()
    if not card:
        card = models.LifeCard(user_id=current_user_id, share_token=_new_token())
        db.add(card)
    for field in (
        "blood_group", "allergies", "conditions", "medications", "notes",
        "preferred_hospital", "insurance", "share_with_contacts",
    ):
        value = getattr(payload, field)
        if value is not None:
            setattr(card, field, value)
    db.commit()
    db.refresh(card)
    return _to_response(card)


@router.post("/regenerate-token", response_model=schemas.LifeCardResponse)
def regenerate_token(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id),
):
    """Issue a fresh share token; the old token URL stops working at once."""
    card = db.query(models.LifeCard).filter(
        models.LifeCard.user_id == current_user_id
    ).first()
    if not card:
        raise HTTPException(status_code=404, detail="No LifeCard yet — create one with PUT /lifecard")
    card.share_token = _new_token()
    db.commit()
    db.refresh(card)
    return _to_response(card)


@router.get("/public/{token}", response_model=schemas.LifeCardPublicResponse)
def get_public_lifecard(token: str, db: Session = Depends(get_db)):
    """Public emergency view, reached via the QR-code token URL.

    Returns ONLY blood group, allergies, conditions and (when the user
    enabled sharing) emergency contact names + phones. Never medications,
    insurance or notes.
    """
    card = db.query(models.LifeCard).filter(
        models.LifeCard.share_token == token
    ).first()
    if not card:
        raise HTTPException(status_code=404, detail="LifeCard not found")

    contacts = []
    if card.share_with_contacts:
        contacts = [
            {"name": c.name, "relationship": c.relationship, "phone": c.phone}
            for c in db.query(models.EmergencyContact).filter(
                models.EmergencyContact.user_id == card.user_id
            ).all()
        ]
    return schemas.LifeCardPublicResponse(
        blood_group=card.blood_group,
        allergies=card.allergies,
        conditions=card.conditions,
        emergency_contacts=contacts,
    )
