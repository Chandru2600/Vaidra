from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db import get_db
from app import models, schemas, utils

router = APIRouter(prefix="/doctor", tags=["doctor"])

@router.get("/cases")
def list_cases(
    status_filter: str = None, 
    db: Session = Depends(get_db),
    doctor: models.User = Depends(utils.get_current_doctor_or_admin)
):
    q = db.query(models.Scan).order_by(models.Scan.created_at.desc())
    if status_filter:
        q = q.filter(models.Scan.severity == status_filter.upper())
    cases = q.all()
    result = []
    for c in cases:
        result.append({
            "id": c.id,
            "condition": c.condition,
            "confidence": c.confidence,
            "severity": c.severity if c.severity else None,  # c.severity is plain str, not Enum
            "assigned_to": c.assigned_to,
            "created_at": c.created_at.isoformat() if c.created_at else None
        })
    return result

@router.post("/assign")
def assign(
    req: schemas.AssignRequest, 
    db: Session = Depends(get_db),
    doctor: models.User = Depends(utils.get_current_doctor_or_admin)
):
    scan = db.query(models.Scan).filter(models.Scan.id == req.scan_id).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")
    
    # Verify assigned target doctor exists and has DOCTOR or ADMIN role
    target_doctor = db.query(models.User).filter(models.User.id == req.doctor_id).first()
    if not target_doctor or (target_doctor.role or "").upper() not in ["DOCTOR", "ADMIN"]:
        raise HTTPException(status_code=400, detail="Target user is not a valid doctor")

    scan.assigned_to = req.doctor_id
    db.commit()
    return {"ok": True, "scan_id": scan.id, "assigned_to": scan.assigned_to}

@router.post("/note")
def add_note(
    note: schemas.NoteCreate, 
    db: Session = Depends(get_db),
    doctor: models.User = Depends(utils.get_current_doctor_or_admin)
):
    scan = db.query(models.Scan).filter(models.Scan.id == note.scan_id).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")
    
    doctor_stamp = f"[{doctor.name or doctor.email}]: "
    existing = scan.notes or ""
    scan.notes = (existing + "\n" + doctor_stamp + note.note).strip()
    db.commit()
    return {"ok": True}
