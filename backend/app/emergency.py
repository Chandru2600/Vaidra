"""Emergency triage — no login required.

Conservative, keyword-based danger-sign detection. NEVER delays escalation
to collect more information: any danger sign means CALL_112_NOW at once.
Every call is written to the AiInteractionLog audit table.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db import get_db
from app import models, schemas

router = APIRouter(prefix="/emergency", tags=["emergency"])

TRIAGE_MODEL = "triage-keywords-v1"
TRIAGE_VERSION = "triage-v1"
ALWAYS_ADVICE = "If unsure, call 112 immediately."

# --- Danger signs: any match -> CALL_112_NOW -------------------------------
DANGER_PATTERNS = [
    # Chest pain / pressure
    "chest pain", "chest pressure", "chest tightness", "pressure in chest",
    "pain in chest",
    # Breathing difficulty
    "can't breathe", "cannot breathe", "difficulty breathing",
    "trouble breathing", "shortness of breath", "short of breath",
    "breathless", "struggling to breathe", "choking",
    # Unconscious / unresponsive
    "unconscious", "unresponsive", "not responding", "passed out",
    "collapsed", "not waking up", "won't wake up",
    # Heavy / uncontrolled bleeding
    "heavy bleeding", "bleeding won't stop", "bleeding will not stop",
    "blood spurting", "losing a lot of blood", "bleeding heavily",
    # Stroke signs
    "face droop", "face drooping", "arm weakness", "slurred speech",
    "speech slurred", "one side of face", "sudden numbness",
    # Severe allergic reaction
    "throat closing", "throat swelling", "lips swelling", "tongue swelling",
    "swelling of face", "anaphylaxis",
    # Severe burns
    "severe burn", "charred", "electrical burn", "chemical burn",
    # Suicide / self-harm intent
    "suicide", "kill myself", "want to die", "self-harm", "hurt myself",
    "end my life",
]

# Seizure: danger only when long / repeated / not stopping
SEIZURE_DANGER_PATTERNS = [
    "5 min", "more than 5", "won't stop", "not stopping",
    "repeated", "again and again", "second seizure",
]

# Head injury: danger when combined with vomiting / confusion / drowsiness
HEAD_INJURY_DANGER_PATTERNS = ["vomit", "confus", "drowsy", "unconscious", "seizure"]

# --- Concerning (not immediately life-threatening) -> URGENT_SEEK_CARE -----
URGENT_PATTERNS = [
    "high fever", "fever", "vomiting", "vomit", "severe pain",
    "fracture", "broken bone", "broken arm", "broken leg", "deep cut",
    "animal bite", "dog bite", "dehydrat", "fainted", "head injury",
    "burn", "allergic", "rash spreading", "blood in vomit",
    "blood in urine", "blood in stool", "difficulty swallowing",
    "seizure", "fit", "convulsion",
]

# --- Guide matching for self-care guidance ----------------------------------
GUIDE_PATTERNS = [
    ("nosebleed", ["nosebleed", "nose bleed", "bleeding nose"]),
    ("burns", ["burn", "scald"]),
    ("severe-bleeding", ["bleed", "cut", "wound"]),
    ("choking-adult", ["chok"]),
    ("sprain", ["sprain", "twisted ankle", "twisted wrist"]),
    ("fracture", ["fracture", "broken"]),
    ("snake-bite", ["snake"]),
    ("fainting", ["faint"]),
    ("heatstroke", ["heatstroke", "heat stroke", "sunstroke", "overheated"]),
    ("allergic-reaction", ["allerg"]),
    ("seizure", ["seizure", "convulsion"]),
    ("cpr-basics", ["cpr"]),
]


def _normalise(text: str) -> str:
    return " ".join((text or "").lower().split())


def _contains_any(text: str, patterns: list) -> bool:
    return any(p in text for p in patterns)


def classify_triage(description: str, symptoms: list) -> dict:
    """Pure function — returns escalation decision. Easy to unit test."""
    combined = _normalise(description + " " + " ".join(symptoms or []))

    if _contains_any(combined, DANGER_PATTERNS):
        return {
            "escalation": "CALL_112_NOW",
            "guide_id": None,
            "call_112": True,
            "message": "Danger signs detected. Call 112 NOW — do not wait, do not drive yourself.",
            "advice": [ALWAYS_ADVICE],
        }

    if "seizure" in combined or "convulsion" in combined:
        if _contains_any(combined, SEIZURE_DANGER_PATTERNS):
            return {
                "escalation": "CALL_112_NOW",
                "guide_id": "seizure",
                "call_112": True,
                "message": "A seizure lasting over 5 minutes or repeating is an emergency. Call 112 NOW.",
                "advice": [ALWAYS_ADVICE],
            }

    if "head injury" in combined and _contains_any(combined, HEAD_INJURY_DANGER_PATTERNS):
        return {
            "escalation": "CALL_112_NOW",
            "guide_id": None,
            "call_112": True,
            "message": "Head injury with vomiting, confusion or drowsiness is an emergency. Call 112 NOW.",
            "advice": [ALWAYS_ADVICE],
        }

    if _contains_any(combined, URGENT_PATTERNS):
        guide_id = None
        for gid, patterns in GUIDE_PATTERNS:
            if _contains_any(combined, patterns):
                guide_id = gid
                break
        return {
            "escalation": "URGENT_SEEK_CARE",
            "guide_id": guide_id,
            "call_112": False,
            "message": "This needs urgent medical care — go to a hospital or call 112 if it gets worse.",
            "advice": [ALWAYS_ADVICE],
        }

    guide_id = None
    for gid, patterns in GUIDE_PATTERNS:
        if _contains_any(combined, patterns):
            guide_id = gid
            break
    return {
        "escalation": "SELF_CARE_GUIDANCE",
        "guide_id": guide_id,
        "call_112": False,
        "message": "General first-aid information only — not medical advice. See a doctor if it does not improve.",
        "advice": [ALWAYS_ADVICE],
    }


@router.post("/triage", response_model=schemas.TriageResponse)
def triage(payload: schemas.TriageRequest, db: Session = Depends(get_db)):
    """Describe what happened — get an escalation decision.

    No login required. Never delays escalation to collect more information.
    """
    result = classify_triage(payload.description, payload.symptoms or [])

    # Audit log: every triage call is recorded for safety review.
    db.add(models.AiInteractionLog(
        user_id=None,
        scan_id=None,
        model=TRIAGE_MODEL,
        prompt_version=TRIAGE_VERSION,
        result_summary=f"{result['escalation']} | {payload.description[:200]}",
        escalation=result["escalation"],
    ))
    db.commit()

    return schemas.TriageResponse(**result)
