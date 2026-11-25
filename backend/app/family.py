"""Family Relay (checklist §7/§8): family groups, incident sharing and
status updates.

PRIVACY: location is NEVER tracked. The only location-related data is the
boolean consent flag `can_share_location` on a membership — no
coordinates are collected or stored anywhere in this feature.
"""
import secrets
import string

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, roles, schemas
from app.db import get_db

router = APIRouter(prefix="/family", tags=["family"])

_ALPHABET = string.ascii_uppercase + string.digits


def _new_invite_code(db: Session) -> str:
    """Short, readable invite code, unique across groups."""
    for _ in range(20):
        code = "".join(secrets.choice(_ALPHABET) for _ in range(8))
        if not db.query(models.FamilyGroup).filter(
            models.FamilyGroup.invite_code == code
        ).first():
            return code
    raise HTTPException(status_code=500, detail="Could not generate an invite code")


def _get_group_or_404(db: Session, group_id: int) -> models.FamilyGroup:
    group = db.query(models.FamilyGroup).filter(models.FamilyGroup.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Family group not found")
    return group


def _require_member(db: Session, group: models.FamilyGroup, user_id: int) -> models.FamilyMember:
    member = (
        db.query(models.FamilyMember)
        .filter(
            models.FamilyMember.group_id == group.id,
            models.FamilyMember.user_id == user_id,
        )
        .first()
    )
    if not member:
        raise HTTPException(
            status_code=403, detail="Only group members can do this"
        )
    return member


def _member_view(db: Session, group: models.FamilyGroup) -> list:
    members = (
        db.query(models.FamilyMember)
        .filter(models.FamilyMember.group_id == group.id)
        .all()
    )
    out = []
    for m in members:
        u = db.query(models.User).filter(models.User.id == m.user_id).first()
        out.append(schemas.FamilyMemberResponse(
            user_id=m.user_id,
            name=u.name if u else None,
            email=u.email if u else None,
            can_share_location=m.can_share_location,
            joined_at=m.joined_at,
        ))
    return out


def _group_response(db: Session, group: models.FamilyGroup) -> schemas.FamilyGroupResponse:
    return schemas.FamilyGroupResponse(
        id=group.id,
        name=group.name,
        owner_id=group.owner_id,
        invite_code=group.invite_code,
        members=_member_view(db, group),
        created_at=group.created_at,
    )


def _get_incident_or_404(db: Session, incident_id: int) -> models.FamilyIncident:
    incident = (
        db.query(models.FamilyIncident)
        .filter(models.FamilyIncident.id == incident_id)
        .first()
    )
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    return incident


def _incident_response(incident: models.FamilyIncident) -> schemas.FamilyIncidentResponse:
    return schemas.FamilyIncidentResponse(
        id=incident.id,
        group_id=incident.group_id,
        reporter_id=incident.reporter_id,
        title=incident.title,
        description=incident.description,
        status=incident.status,
        hospital_destination=incident.hospital_destination,
        updates=[
            schemas.IncidentUpdateResponse(
                id=u.id, user_id=u.user_id, message=u.message, created_at=u.created_at
            )
            for u in incident.updates
        ],
        created_at=incident.created_at,
        updated_at=incident.updated_at,
    )


@router.post("/groups", response_model=schemas.FamilyGroupResponse, status_code=201)
def create_group(
    payload: schemas.FamilyGroupCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Create a family group. The creator is the owner and auto-member."""
    if not (payload.name or "").strip():
        raise HTTPException(status_code=400, detail="Group name is required")
    group = models.FamilyGroup(
        name=payload.name.strip(),
        owner_id=user.id,
        invite_code=_new_invite_code(db),
    )
    db.add(group)
    db.flush()
    db.add(models.FamilyMember(group_id=group.id, user_id=user.id))
    db.commit()
    db.refresh(group)
    return _group_response(db, group)


@router.post("/groups/join", response_model=schemas.FamilyGroupResponse)
def join_group(
    payload: schemas.FamilyJoinRequest,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Join a group with its invite code (registered users only)."""
    code = (payload.invite_code or "").strip().upper()
    group = (
        db.query(models.FamilyGroup)
        .filter(models.FamilyGroup.invite_code == code)
        .first()
    )
    if not group:
        raise HTTPException(status_code=404, detail="No group with that invite code")
    existing = (
        db.query(models.FamilyMember)
        .filter(
            models.FamilyMember.group_id == group.id,
            models.FamilyMember.user_id == user.id,
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Already a member of this group")
    db.add(models.FamilyMember(group_id=group.id, user_id=user.id))
    db.commit()
    db.refresh(group)
    return _group_response(db, group)


@router.get("/groups", response_model=list[schemas.FamilyGroupResponse])
def my_groups(
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Groups the caller belongs to, with their members."""
    memberships = (
        db.query(models.FamilyMember)
        .filter(models.FamilyMember.user_id == user.id)
        .all()
    )
    groups = []
    for m in memberships:
        group = db.query(models.FamilyGroup).filter(models.FamilyGroup.id == m.group_id).first()
        if group:
            groups.append(_group_response(db, group))
    return groups


@router.post("/groups/{group_id}/leave", status_code=204)
def leave_group(
    group_id: int,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Leave a group. The owner cannot leave their own group."""
    group = _get_group_or_404(db, group_id)
    if group.owner_id == user.id:
        raise HTTPException(
            status_code=400,
            detail="The group owner cannot leave the group",
        )
    member = _require_member(db, group, user.id)
    db.delete(member)
    db.commit()
    return None


@router.put("/groups/{group_id}/location-sharing", response_model=schemas.FamilyMemberResponse)
def set_location_sharing(
    group_id: int,
    payload: schemas.LocationSharingUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Set the caller's OWN location-sharing consent flag for this group.

    Consent flag only — no coordinates are collected or stored.
    """
    group = _get_group_or_404(db, group_id)
    member = _require_member(db, group, user.id)
    member.can_share_location = payload.can_share_location
    db.commit()
    db.refresh(member)
    return schemas.FamilyMemberResponse(
        user_id=member.user_id,
        name=user.name,
        email=user.email,
        can_share_location=member.can_share_location,
        joined_at=member.joined_at,
    )


@router.post("/groups/{group_id}/incidents", response_model=schemas.FamilyIncidentResponse, status_code=201)
def create_incident(
    group_id: int,
    payload: schemas.FamilyIncidentCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Report an incident to the group (members only)."""
    group = _get_group_or_404(db, group_id)
    _require_member(db, group, user.id)
    if not (payload.title or "").strip():
        raise HTTPException(status_code=400, detail="Incident title is required")
    incident = models.FamilyIncident(
        group_id=group.id,
        reporter_id=user.id,
        title=payload.title.strip(),
        description=payload.description,
        hospital_destination=payload.hospital_destination,
        status="active",
    )
    db.add(incident)
    db.commit()
    db.refresh(incident)
    return _incident_response(incident)


@router.get("/groups/{group_id}/incidents", response_model=list[schemas.FamilyIncidentResponse])
def list_incidents(
    group_id: int,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Incidents of a group (members only), newest first, with updates."""
    group = _get_group_or_404(db, group_id)
    _require_member(db, group, user.id)
    incidents = (
        db.query(models.FamilyIncident)
        .filter(models.FamilyIncident.group_id == group.id)
        .order_by(models.FamilyIncident.id.desc())
        .all()
    )
    return [_incident_response(i) for i in incidents]


@router.post("/incidents/{incident_id}/updates", response_model=schemas.FamilyIncidentResponse)
def add_incident_update(
    incident_id: int,
    payload: schemas.IncidentUpdateCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Add a timeline update to an incident (group members only)."""
    incident = _get_incident_or_404(db, incident_id)
    group = _get_group_or_404(db, incident.group_id)
    _require_member(db, group, user.id)
    if not (payload.message or "").strip():
        raise HTTPException(status_code=400, detail="Update message is required")
    db.add(models.IncidentUpdate(
        incident_id=incident.id,
        user_id=user.id,
        message=payload.message.strip(),
    ))
    db.commit()
    db.refresh(incident)
    return _incident_response(incident)


@router.post("/incidents/{incident_id}/resolve", response_model=schemas.FamilyIncidentResponse)
def resolve_incident(
    incident_id: int,
    db: Session = Depends(get_db),
    user: models.User = Depends(roles.get_current_user),
):
    """Mark an incident resolved — only the reporter or the group owner."""
    incident = _get_incident_or_404(db, incident_id)
    group = _get_group_or_404(db, incident.group_id)
    if user.id != incident.reporter_id and user.id != group.owner_id:
        raise HTTPException(
            status_code=403,
            detail="Only the reporter or the group owner can resolve an incident",
        )
    incident.status = "resolved"
    db.commit()
    db.refresh(incident)
    return _incident_response(incident)
