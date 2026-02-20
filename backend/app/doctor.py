from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import get_db
from app import models, schemas

router = APIRouter(prefix="/doctor", tags=["doctor"])

@router.get("/cases")
def list_cases(status: str = None, db: Session = Depends(get_db)):
    q = db.query(models.Scan).order_by(models.Scan.created_at.desc())
    if status:
        q = q.filter(models.Scan.severity == status)
    cases = q.all()
    result = []
    for c in cases:
        result.append({
            "id": c.id,
            "condition": c.condition,
            "confidence": c.confidence,
            "severity": c.severity.value if c.severity else None,
            "assigned_to": c.assigned_to,
            "created_at": c.created_at.isoformat()
        })
    return result

@router.post("/assign")
def assign(req: schemas.AssignRequest, db: Session = Depends(get_db)):
    scan = db.query(models.Scan).filter(models.Scan.id == req.scan_id).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")
    scan.assigned_to = req.doctor_id
    db.commit()
    return {"ok": True, "scan_id": scan.id, "assigned_to": scan.assigned_to}

@router.post("/note")
def add_note(note: schemas.NoteCreate, db: Session = Depends(get_db)):
    scan = db.query(models.Scan).filter(models.Scan.id == note.scan_id).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")
    existing = scan.notes or ""
    scan.notes = (existing + "\n" + note.note).strip()
    db.commit()
    return {"ok": True}
