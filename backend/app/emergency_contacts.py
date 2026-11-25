"""Emergency contacts CRUD — authenticated, owner-only.

A user can only see, change or delete their own contacts. A contact that
belongs to someone else is reported as 404 (never 403, so ids cannot be
probed).
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import get_db
from app import models, schemas, utils

router = APIRouter(prefix="/emergency-contacts", tags=["emergency-contacts"])


def _get_owned(db: Session, contact_id: int, user_id: int) -> models.EmergencyContact:
    contact = db.query(models.EmergencyContact).filter(
        models.EmergencyContact.id == contact_id,
        models.EmergencyContact.user_id == user_id,
    ).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Emergency contact not found")
    return contact


def _to_response(contact: models.EmergencyContact) -> schemas.EmergencyContactResponse:
    return schemas.EmergencyContactResponse(
        id=contact.id,
        name=contact.name,
        relationship=contact.relationship,
        phone=contact.phone,
        is_primary=contact.is_primary,
        created_at=contact.created_at,
    )


@router.get("", response_model=list[schemas.EmergencyContactResponse])
def list_contacts(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id),
):
    contacts = (
        db.query(models.EmergencyContact)
        .filter(models.EmergencyContact.user_id == current_user_id)
        .order_by(models.EmergencyContact.is_primary.desc(), models.EmergencyContact.id)
        .all()
    )
    return [_to_response(c) for c in contacts]


@router.post("", response_model=schemas.EmergencyContactResponse, status_code=201)
def create_contact(
    payload: schemas.EmergencyContactCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id),
):
    if payload.is_primary:
        # Only one primary contact per user.
        db.query(models.EmergencyContact).filter(
            models.EmergencyContact.user_id == current_user_id
        ).update({"is_primary": False})
    contact = models.EmergencyContact(
        user_id=current_user_id,
        name=payload.name,
        relationship=payload.relationship,
        phone=payload.phone,
        is_primary=payload.is_primary,
    )
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return _to_response(contact)


@router.put("/{contact_id}", response_model=schemas.EmergencyContactResponse)
def update_contact(
    contact_id: int,
    payload: schemas.EmergencyContactUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id),
):
    contact = _get_owned(db, contact_id, current_user_id)
    if payload.name is not None:
        contact.name = payload.name
    if payload.relationship is not None:
        contact.relationship = payload.relationship
    if payload.phone is not None:
        contact.phone = payload.phone
    if payload.is_primary is not None:
        if payload.is_primary:
            db.query(models.EmergencyContact).filter(
                models.EmergencyContact.user_id == current_user_id,
                models.EmergencyContact.id != contact_id,
            ).update({"is_primary": False})
        contact.is_primary = payload.is_primary
    db.commit()
    db.refresh(contact)
    return _to_response(contact)


@router.delete("/{contact_id}", status_code=204)
def delete_contact(
    contact_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id),
):
    contact = _get_owned(db, contact_id, current_user_id)
    db.delete(contact)
    db.commit()
    return None
