"""Public first-aid guides — no login required (emergency content must never
be locked behind registration, per the Vaidra checklist §4)."""
from fastapi import APIRouter, HTTPException
from app import first_aid_kb

router = APIRouter(prefix="/first-aid", tags=["first-aid"])


@router.get("/guides")
def list_guides():
    """All first-aid guides with the disclaimer on each one."""
    return first_aid_kb.list_guides()


@router.get("/guides/{guide_id}")
def get_guide(guide_id: str):
    """One guide by id."""
    guide = first_aid_kb.get_guide(guide_id)
    if not guide:
        raise HTTPException(status_code=404, detail=f"Guide '{guide_id}' not found")
    return guide
