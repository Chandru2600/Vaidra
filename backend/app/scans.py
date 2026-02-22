from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status, Form
from sqlalchemy.orm import Session
from app.db import get_db
from app import models, schemas
from app.ai_client import analyze_image
from app.storage import upload_to_storage
from app.config import settings
import shutil, os, datetime, uuid

router = APIRouter(prefix="/scans", tags=["scans"])

UPLOAD_DIR = settings.UPLOAD_DIR
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.get("/recent", response_model=list[schemas.ScanResponse])
def get_recent_scans(db: Session = Depends(get_db), limit: int = 5):
    scans = db.query(models.Scan).order_by(models.Scan.id.desc()).limit(limit).all()
    # map to schema
    return [
        schemas.ScanResponse(
            id=scan.id,
            result=schemas.ScanResult(
                condition=scan.condition,
                confidence=scan.confidence or 0.0,
                severity=scan.severity if scan.severity else "MINOR",
                steps=scan.steps.split("|") if scan.steps else [],
                warnings=scan.warnings.split("|") if scan.warnings else []
            ),
            created_at=scan.created_at
        ) for scan in scans
    ]

@router.post("/analyze", response_model=schemas.ScanResponse)
def analyze(scan_image: UploadFile = File(...), user_id: int = Form(None), db: Session = Depends(get_db)):
    # save file locally
    timestamp = int(datetime.datetime.utcnow().timestamp() * 1000)
    filename = f"{timestamp}_{scan_image.filename}"
    local_path = os.path.join(UPLOAD_DIR, filename)
    with open(local_path, "wb") as buffer:
        shutil.copyfileobj(scan_image.file, buffer)

    # Optionally upload to S3 storage
    object_name = f"cases/{uuid.uuid4().hex}_{scan_image.filename}"
    storage = upload_to_storage(local_path, object_name)
    s3_key = storage.get("key")

    try:
        ai_res = analyze_image(local_path)
    except Exception as e:
        if "429" in str(e):
             raise HTTPException(status_code=429, detail="Gemini Rate Limit Exceeded. Please try again later.")
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")

    # normalize ai_res
    condition = ai_res.get("condition") or ai_res.get("diagnosis") or "Unclear image"
    confidence = float(ai_res.get("confidence") or ai_res.get("score") or 0.0)
    severity_raw = (ai_res.get("severity") or "MINOR").upper()
    VALID_SEVERITIES = {"MINOR", "MODERATE", "URGENT"}
    severity_str = severity_raw if severity_raw in VALID_SEVERITIES else "MINOR"

    steps = ai_res.get("steps") or ai_res.get("advice") or []
    warnings = ai_res.get("warnings") or []

    scan = models.Scan(
        user_id=user_id,
        filename=filename,
        s3_key=s3_key,
        condition=condition,
        confidence=confidence,
        severity=severity_str,
        steps="|".join(steps) if isinstance(steps, list) else str(steps),
        warnings="|".join(warnings) if isinstance(warnings, list) else str(warnings)
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)

    return schemas.ScanResponse(
        id=scan.id,
        result=schemas.ScanResult(
            condition=scan.condition,
            confidence=scan.confidence or 0.0,
            severity=scan.severity if scan.severity else "MINOR",
            steps=scan.steps.split("|") if scan.steps else [],
            warnings=scan.warnings.split("|") if scan.warnings else []
        )
    )

@router.get("/debug_models")
def get_debug_models():
    import google.generativeai as genai
    from app.config import settings
    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        models = [m.name for m in genai.list_models()]
        return {"models": models}
    except Exception as e:
        return {"error": str(e)}
