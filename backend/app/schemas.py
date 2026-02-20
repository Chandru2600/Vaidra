from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class UserCreate(BaseModel):
    email: str
    password: str
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    conditions: Optional[str] = None
    allergies: Optional[str] = None
    address: Optional[str] = None

class UserUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    conditions: Optional[str] = None
    allergies: Optional[str] = None
    address: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class ScanResult(BaseModel):
    condition: str
    confidence: float
    severity: str
    steps: List[str]
    warnings: List[str]

class ScanResponse(BaseModel):
    id: int
    result: ScanResult
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True  # Pydantic v2 (use orm_mode = True for Pydantic v1)


class AssignRequest(BaseModel):
    scan_id: int
    doctor_id: int

class NoteCreate(BaseModel):
    scan_id: int
    note: str
