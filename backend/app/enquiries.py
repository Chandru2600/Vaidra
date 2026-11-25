"""Enquiries to verified partners (checklist §7).

Users can enquire with a verified hospital/pharmacy partner: general
questions, appointment requests, stock enquiries, reservation requests.

APPOINTMENTS ARE REQUEST-ONLY: an appointment_request is stored as an
enquiry and the response says so plainly. It is NOT a confirmed booking
— appointments are a later phase per the checklist.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, roles, schemas
from app.db import get_db

router = APIRouter(prefix="/enquiries", tags=["enquiries"])

ENQUIRY_KINDS = {"general", "appointment_request", "stock_enquiry", "reservation_request"}

APPOINTMENT_NOTE = (
    "Appointment requests are requests only — this is not a confirmed "
    "booking. The partner will confirm availability separately."
)


def _to_response(e: models.Enquiry) -> schemas.EnquiryResponse:
    note = APPOINTMENT_NOTE if e.kind == "appointment_request" else None
    return schemas.EnquiryResponse(
        id=e.id,
        partner_id=e.partner_id,
        kind=e.kind,
        message=e.message,
        status=e.status,
        note=note,
        created_at=e.created_at,
    )


@router.post("", response_model=schemas.EnquiryResponse, status_code=201)
def create_enquiry(
    payload: schemas.EnquiryCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Send an enquiry to a VERIFIED partner only."""
    kind = (payload.kind or "").strip().lower()
    if kind not in ENQUIRY_KINDS:
        raise HTTPException(
            status_code=400,
            detail=f"kind must be one of: {', '.join(sorted(ENQUIRY_KINDS))}",
        )
    if not (payload.message or "").strip():
        raise HTTPException(status_code=400, detail="message is required")
    partner = (
        db.query(models.Partner).filter(models.Partner.id == payload.partner_id).first()
    )
    if not partner:
        raise HTTPException(status_code=404, detail="Partner not found")
    if partner.verification_status != "verified":
        raise HTTPException(
            status_code=400,
            detail="Enquiries can only be sent to verified partners",
        )
    enquiry = models.Enquiry(
        user_id=user.id,
        partner_id=partner.id,
        kind=kind,
        message=payload.message.strip(),
        status="open",
    )
    db.add(enquiry)
    db.commit()
    db.refresh(enquiry)
    return _to_response(enquiry)


@router.get("/mine", response_model=list[schemas.EnquiryResponse])
def my_enquiries(
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """The caller's own enquiries, newest first."""
    rows = (
        db.query(models.Enquiry)
        .filter(models.Enquiry.user_id == user.id)
        .order_by(models.Enquiry.id.desc())
        .all()
    )
    return [_to_response(e) for e in rows]
