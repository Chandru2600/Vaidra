from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status, Form
from sqlalchemy.orm import Session
from app.db import get_db
from app import models, schemas, utils
from app.ai_client import analyze_image
from app.storage import upload_to_storage
from app.config import settings
import shutil, os, datetime, uuid
from typing import Optional

router = APIRouter(prefix="/scans", tags=["scans"])

UPLOAD_DIR = settings.UPLOAD_DIR
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB

@router.get("/recent", response_model=list[schemas.ScanResponse])
def get_recent_scans(
    db: Session = Depends(get_db), 
    limit: int = 20,
    current_user_id: Optional[int] = Depends(utils.get_current_user_id_optional)
):
    """
    Get recent scans. If authenticated, returns the user's scans only.
    Prevents unauthorized access to other patients' sensitive medical scans.
    """
    query = db.query(models.Scan)
    if current_user_id:
        query = query.filter(models.Scan.user_id == current_user_id)
    else:
        # For privacy, do not expose patient records to unauthenticated visitors
        return []

    scans = query.order_by(models.Scan.id.desc()).limit(min(limit, 50)).all()
    return [
        schemas.ScanResponse(
            id=scan.id,
            result=schemas.ScanResult(
                condition=scan.condition or "Unknown",
                confidence=scan.confidence or 0.0,
                severity=scan.severity if scan.severity else "MINOR",
                steps=scan.steps.split("|") if scan.steps else [],
                warnings=scan.warnings.split("|") if scan.warnings else []
            ),
            created_at=scan.created_at
        ) for scan in scans
    ]

@router.post("/analyze", response_model=schemas.ScanResponse)
def analyze(
    scan_image: UploadFile = File(...), 
    user_id: Optional[int] = Form(None), 
    db: Session = Depends(get_db),
    current_user_id: Optional[int] = Depends(utils.get_current_user_id_optional)
):
    # --- Security Validation 1: Filename and Extension Sanitization ---
    original_filename = scan_image.filename or "image.jpg"
    _, ext = os.path.splitext(original_filename)
    ext = ext.lower()

    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type '{ext}'. Allowed extensions are: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
        )

    # --- Security Validation 2: MIME Type Validation ---
    if scan_image.content_type and scan_image.content_type.lower() not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid content type '{scan_image.content_type}'. Must be an image (JPEG, PNG, WEBP)."
        )

    # --- Security Validation 3: File Size Limit & Path Traversal Prevention ---
    timestamp = int(datetime.datetime.utcnow().timestamp() * 1000)
    safe_filename = f"{timestamp}_{uuid.uuid4().hex}{ext}"
    local_path = os.path.join(UPLOAD_DIR, safe_filename)

    # Stream file to disk and enforce max size to prevent DoS via disk exhaustion
    total_bytes = 0
    try:
        with open(local_path, "wb") as buffer:
            while chunk := scan_image.file.read(1024 * 1024):  # 1MB chunks
                total_bytes += len(chunk)
                if total_bytes > MAX_FILE_SIZE_BYTES:
                    buffer.close()
                    if os.path.exists(local_path):
                        os.remove(local_path)
                    raise HTTPException(
                        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                        detail="File too large. Maximum allowed size is 10 MB."
                    )
                buffer.write(chunk)
    finally:
        scan_image.file.close()

    # --- Storage & S3 ---
    object_name = f"cases/{uuid.uuid4().hex}{ext}"
    storage = upload_to_storage(local_path, object_name)
    s3_key = storage.get("key")

    # --- AI Analysis ---
    try:
        ai_res = analyze_image(local_path)
    except Exception as e:
        if "429" in str(e):
            raise HTTPException(status_code=429, detail="Gemini Rate Limit Exceeded. Please try again later.")
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")

    # Normalize AI response
    condition = ai_res.get("condition") or ai_res.get("diagnosis") or "Unclear image"
    confidence = float(ai_res.get("confidence") or ai_res.get("score") or 0.0)
    severity_raw = (ai_res.get("severity") or "MINOR").upper()
    VALID_SEVERITIES = {"MINOR", "MODERATE", "URGENT"}
    severity_str = severity_raw if severity_raw in VALID_SEVERITIES else "MINOR"

    steps = ai_res.get("steps") or ai_res.get("advice") or []
    warnings = ai_res.get("warnings") or []

    # --- Security: Prevent IDOR (Insecure Direct Object Reference) ---
    # Only associate scan with a user ID if the user is authenticated with that ID
    effective_user_id = current_user_id if current_user_id else None

    scan = models.Scan(
        user_id=effective_user_id,
        filename=safe_filename,
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
        ),
        created_at=scan.created_at
    )

@router.get("/debug_models")
def get_debug_models(admin: models.User = Depends(utils.get_current_doctor_or_admin)):
    """Protected admin endpoint to query available Gemini models."""
    import urllib.request, json
    try:
        api_key = settings.GEMINI_API_KEY
        req = urllib.request.Request(f'https://generativelanguage.googleapis.com/v1beta/models?key={api_key}')
        res = urllib.request.urlopen(req, timeout=10)
        data = json.loads(res.read())
        models_list = [m['name'] for m in data.get('models', [])]
        return {"models": models_list}
    except Exception as e:
        return {"error": "Failed to retrieve models"}
