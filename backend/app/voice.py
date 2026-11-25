"""Voice-assist API (checklist §4).

The app performs speech-to-text ON THE DEVICE and calls this endpoint
with the recognised text. NO audio is ever uploaded or stored here.

The endpoint reuses the exact triage logic from app.emergency
(classify_triage — imported, not duplicated) and attaches the full
first-aid guide content when a guide matches, so the app can read the
steps aloud. Every call is audit-logged like a triage call.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app import models, schemas
from app.db import get_db
from app.emergency import TRIAGE_MODEL, TRIAGE_VERSION, classify_triage
from app.first_aid_kb import get_guide

router = APIRouter(prefix="/voice", tags=["voice"])


@router.post("/assist", response_model=schemas.VoiceAssistResponse)
def voice_assist(
    payload: schemas.VoiceAssistRequest,
    db: Session = Depends(get_db),
):
    """Text in (from on-device speech-to-text) -> escalation + guide.

    No login required. Never delays escalation to collect more information.
    """
    result = classify_triage(payload.text or "", [])

    guide = None
    if result.get("guide_id"):
        raw = get_guide(result["guide_id"])
        if raw:
            guide = schemas.FirstAidGuide(**raw)

    # Audit log, same as triage.
    db.add(models.AiInteractionLog(
        user_id=None,
        scan_id=None,
        model="voice-assist-triage-v1",
        prompt_version=TRIAGE_VERSION,
        result_summary=f"{result['escalation']} | {(payload.text or '')[:200]}",
        escalation=result["escalation"],
    ))
    db.commit()

    return schemas.VoiceAssistResponse(
        escalation=result["escalation"],
        guide_id=result.get("guide_id"),
        call_112=result["call_112"],
        message=result["message"],
        advice=result["advice"],
        guide=guide,
    )
