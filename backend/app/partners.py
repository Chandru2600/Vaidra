"""Partner accounts — hospital / pharmacy partner portals (checklist §7/§9).

- Any logged-in user can register as a partner; the account starts
  verification_status="pending" and NEVER appears in public listings.
- An ADMIN verifies or rejects partners (see /admin/partners below).
- Public listings show VERIFIED partners only, with the profile and
  availability exactly as the partner reported them. Availability that
  was never reported is absent — never inferred or invented.
- No payments, no booking: enquiries and appointment requests live in
  app/enquiries.py and are request-only.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, roles, schemas
from app.db import get_db

router = APIRouter(prefix="/partners", tags=["partners"])
admin_router = APIRouter(prefix="/admin/partners", tags=["admin-partners"])

ORG_TYPES = {"hospital", "pharmacy"}
PARTNER_ROLES = {
    "hospital": roles.ROLE_HOSPITAL_PARTNER,
    "pharmacy": roles.ROLE_PHARMACY_PARTNER,
}


def _to_response(p: models.Partner) -> schemas.PartnerResponse:
    return schemas.PartnerResponse(
        id=p.id,
        org_type=p.org_type,
        org_name=p.org_name,
        address=p.address,
        phone=p.phone,
        specialities=p.specialities,
        hours_text=p.hours_text,
        emergency_facilities=p.emergency_facilities,
        services=p.services,
        verification_status=p.verification_status,
        er_status=p.er_status,
        icu_beds_available=p.icu_beds_available,
        general_beds_available=p.general_beds_available,
        diagnostics_available=p.diagnostics_available,
        specialists_available=p.specialists_available,
        created_at=p.created_at,
        updated_at=p.updated_at,
    )


def _own_partner(db: Session, user_id: int) -> models.Partner:
    partner = (
        db.query(models.Partner)
        .filter(models.Partner.user_id == user_id)
        .first()
    )
    if not partner:
        raise HTTPException(status_code=404, detail="No partner account for this user")
    return partner


@router.post("/register", response_model=schemas.PartnerResponse, status_code=201)
def register_partner(
    payload: schemas.PartnerRegister,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Register the caller's organisation as a partner.

    Starts as verification_status="pending" and is invisible publicly
    until an admin verifies it. The caller's role becomes
    HOSPITAL_PARTNER or PHARMACY_PARTNER.
    """
    org_type = (payload.org_type or "").strip().lower()
    if org_type not in ORG_TYPES:
        raise HTTPException(
            status_code=400, detail="org_type must be 'hospital' or 'pharmacy'"
        )
    if not (payload.org_name or "").strip():
        raise HTTPException(status_code=400, detail="org_name is required")
    existing = (
        db.query(models.Partner).filter(models.Partner.user_id == user.id).first()
    )
    if existing:
        raise HTTPException(
            status_code=400, detail="This user already has a partner account"
        )
    partner = models.Partner(
        user_id=user.id,
        org_type=org_type,
        org_name=payload.org_name.strip(),
        address=payload.address,
        phone=payload.phone,
        specialities=payload.specialities,
        hours_text=payload.hours_text,
        emergency_facilities=payload.emergency_facilities,
        services=payload.services,
        verification_status="pending",
    )
    db.add(partner)
    user.role = PARTNER_ROLES[org_type]
    db.commit()
    db.refresh(partner)
    return _to_response(partner)


@router.get("/me", response_model=schemas.PartnerResponse)
def get_my_partner(
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    return _to_response(_own_partner(db, user.id))


@router.put("/me", response_model=schemas.PartnerResponse)
def update_my_partner(
    payload: schemas.PartnerUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Update the caller's own partner profile (free text, as reported)."""
    partner = _own_partner(db, user.id)
    for field in (
        "org_name", "address", "phone", "specialities",
        "hours_text", "emergency_facilities", "services",
    ):
        value = getattr(payload, field)
        if value is not None:
            setattr(partner, field, value)
    db.commit()
    db.refresh(partner)
    return _to_response(partner)


@router.put("/me/availability", response_model=schemas.PartnerResponse)
def update_my_availability(
    payload: schemas.PartnerAvailabilityUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Report availability. ONLY what the partner reports is stored;
    fields never sent stay as they are, and a partner that never reports
    has no availability at all — it is never inferred."""
    partner = _own_partner(db, user.id)
    for field in (
        "er_status", "icu_beds_available", "general_beds_available",
        "diagnostics_available", "specialists_available",
    ):
        value = getattr(payload, field)
        if value is not None:
            setattr(partner, field, value)
    db.commit()
    db.refresh(partner)
    return _to_response(partner)


def _public_listing(db: Session, org_type: str) -> list:
    partners = (
        db.query(models.Partner)
        .filter(
            models.Partner.org_type == org_type,
            models.Partner.verification_status == "verified",
        )
        .order_by(models.Partner.org_name)
        .all()
    )
    return [_to_response(p) for p in partners]


@router.get("/hospitals", response_model=list[schemas.PartnerResponse])
def list_verified_hospitals(db: Session = Depends(get_db)):
    """Public: verified hospital partners only, with reported availability."""
    return _public_listing(db, "hospital")


@router.get("/pharmacies", response_model=list[schemas.PartnerResponse])
def list_verified_pharmacies(db: Session = Depends(get_db)):
    """Public: verified pharmacy partners only, with reported availability."""
    return _public_listing(db, "pharmacy")


@router.get("/enquiries", response_model=list[schemas.EnquiryResponse])
def partner_enquiries(
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Enquiries sent to the caller's own partner organisation."""
    partner = (
        db.query(models.Partner).filter(models.Partner.user_id == user.id).first()
    )
    if not partner:
        raise HTTPException(status_code=404, detail="No partner account for this user")
    rows = (
        db.query(models.Enquiry)
        .filter(models.Enquiry.partner_id == partner.id)
        .order_by(models.Enquiry.id.desc())
        .all()
    )
    return [
        schemas.EnquiryResponse(
            id=e.id,
            partner_id=e.partner_id,
            kind=e.kind,
            message=e.message,
            status=e.status,
            note=(
                "Appointment requests are requests only — this is not a "
                "confirmed booking. The partner will confirm availability "
                "separately."
                if e.kind == "appointment_request"
                else None
            ),
            created_at=e.created_at,
        )
        for e in rows
    ]


# --- Admin -------------------------------------------------------------------
@admin_router.get("", response_model=list[schemas.PartnerResponse])
def admin_list_partners(
    db: Session = Depends(get_db),
    admin: models.User = Depends(roles.require_role(roles.ROLE_ADMIN)),
):
    """Admin: every partner, including pending and rejected ones."""
    partners = db.query(models.Partner).order_by(models.Partner.id).all()
    return [_to_response(p) for p in partners]


@admin_router.post("/{partner_id}/verify", response_model=schemas.PartnerResponse)
def admin_verify_partner(
    partner_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(roles.require_role(roles.ROLE_ADMIN)),
):
    partner = db.query(models.Partner).filter(models.Partner.id == partner_id).first()
    if not partner:
        raise HTTPException(status_code=404, detail="Partner not found")
    partner.verification_status = "verified"
    partner.verified_by = admin.id
    db.commit()
    db.refresh(partner)
    return _to_response(partner)


@admin_router.post("/{partner_id}/reject", response_model=schemas.PartnerResponse)
def admin_reject_partner(
    partner_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(roles.require_role(roles.ROLE_ADMIN)),
):
    partner = db.query(models.Partner).filter(models.Partner.id == partner_id).first()
    if not partner:
        raise HTTPException(status_code=404, detail="Partner not found")
    partner.verification_status = "rejected"
    partner.verified_by = admin.id
    db.commit()
    db.refresh(partner)
    return _to_response(partner)
