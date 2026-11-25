from pydantic import BaseModel, ConfigDict
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
    # Safety guardrails (§6): AI output is preliminary guidance, never a diagnosis.
    disclaimer: Optional[str] = None
    uncertainty: Optional[str] = None  # low / medium / high

class ScanResponse(BaseModel):
    id: int
    result: ScanResult
    created_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)

class AssignRequest(BaseModel):
    scan_id: int
    doctor_id: int

class NoteCreate(BaseModel):
    scan_id: int
    note: str


# --- First aid ---------------------------------------------------------------
class FirstAidGuide(BaseModel):
    id: str
    title: str
    danger_signs: List[str]
    steps: List[str]
    what_not_to_do: List[str]
    call_112_when: List[str]
    disclaimer: str


# --- Emergency triage ---------------------------------------------------------
class TriageRequest(BaseModel):
    description: str
    symptoms: List[str] = []


class TriageResponse(BaseModel):
    escalation: str  # CALL_112_NOW / URGENT_SEEK_CARE / SELF_CARE_GUIDANCE
    guide_id: Optional[str] = None
    call_112: bool
    message: str
    advice: List[str]


# --- Emergency contacts -------------------------------------------------------
class EmergencyContactCreate(BaseModel):
    name: str
    relationship: Optional[str] = None
    phone: str
    is_primary: bool = False


class EmergencyContactUpdate(BaseModel):
    name: Optional[str] = None
    relationship: Optional[str] = None
    phone: Optional[str] = None
    is_primary: Optional[bool] = None


class EmergencyContactResponse(BaseModel):
    id: int
    name: str
    relationship: Optional[str] = None
    phone: str
    is_primary: bool
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# --- LifeCard -----------------------------------------------------------------
class LifeCardUpdate(BaseModel):
    blood_group: Optional[str] = None
    allergies: Optional[str] = None
    conditions: Optional[str] = None
    medications: Optional[str] = None
    notes: Optional[str] = None
    preferred_hospital: Optional[str] = None
    insurance: Optional[str] = None
    share_with_contacts: Optional[bool] = None


class LifeCardResponse(BaseModel):
    blood_group: Optional[str] = None
    allergies: Optional[str] = None
    conditions: Optional[str] = None
    medications: Optional[str] = None
    notes: Optional[str] = None
    preferred_hospital: Optional[str] = None
    insurance: Optional[str] = None
    share_with_contacts: bool = False
    share_token: str


class LifeCardPublicContact(BaseModel):
    name: str
    relationship: Optional[str] = None
    phone: str


class LifeCardPublicResponse(BaseModel):
    """Public emergency view — non-sensitive fields ONLY. Never medications,
    insurance or notes."""
    blood_group: Optional[str] = None
    allergies: Optional[str] = None
    conditions: Optional[str] = None
    emergency_contacts: List[LifeCardPublicContact] = []


# --- Discovery (OpenStreetMap, real data only) --------------------------------
class DiscoveryResult(BaseModel):
    name: str
    lat: float
    lng: float
    distance_m: float
    address: Optional[str] = None
    verification_status: str = "unverified_osm"
    note: str


class DiscoveryResponse(BaseModel):
    amenity: str
    count: int
    results: List[DiscoveryResult]


# --- Roles / partners (round 2, checklist §9) --------------------------------
class PartnerRegister(BaseModel):
    org_type: str  # hospital | pharmacy
    org_name: str
    address: Optional[str] = None
    phone: Optional[str] = None
    specialities: Optional[str] = None
    hours_text: Optional[str] = None
    emergency_facilities: Optional[str] = None
    services: Optional[str] = None


class PartnerUpdate(BaseModel):
    org_name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    specialities: Optional[str] = None
    hours_text: Optional[str] = None
    emergency_facilities: Optional[str] = None
    services: Optional[str] = None


class PartnerAvailabilityUpdate(BaseModel):
    """Partner-reported availability ONLY. Absent fields stay as they are;
    a partner that never reports has no availability at all — never inferred."""
    er_status: Optional[str] = None
    icu_beds_available: Optional[int] = None
    general_beds_available: Optional[int] = None
    diagnostics_available: Optional[str] = None
    specialists_available: Optional[str] = None


class PartnerResponse(BaseModel):
    id: int
    org_type: str
    org_name: str
    address: Optional[str] = None
    phone: Optional[str] = None
    specialities: Optional[str] = None
    hours_text: Optional[str] = None
    emergency_facilities: Optional[str] = None
    services: Optional[str] = None
    verification_status: str
    # Availability as reported by the partner (None = never reported).
    er_status: Optional[str] = None
    icu_beds_available: Optional[int] = None
    general_beds_available: Optional[int] = None
    diagnostics_available: Optional[str] = None
    specialists_available: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# --- Enquiries (round 2, checklist §7) ---------------------------------------
class EnquiryCreate(BaseModel):
    partner_id: int
    kind: str  # general | appointment_request | stock_enquiry | reservation_request
    message: str


class EnquiryResponse(BaseModel):
    id: int
    partner_id: int
    kind: str
    message: str
    status: str
    note: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# --- Family Relay (round 2, checklist §7/§8) ---------------------------------
class FamilyGroupCreate(BaseModel):
    name: str


class FamilyMemberResponse(BaseModel):
    user_id: int
    name: Optional[str] = None
    email: Optional[str] = None
    can_share_location: bool = False
    joined_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class FamilyGroupResponse(BaseModel):
    id: int
    name: str
    owner_id: int
    invite_code: str
    members: List[FamilyMemberResponse] = []
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class FamilyJoinRequest(BaseModel):
    invite_code: str


class LocationSharingUpdate(BaseModel):
    can_share_location: bool


class FamilyIncidentCreate(BaseModel):
    title: str
    description: Optional[str] = None
    hospital_destination: Optional[str] = None


class IncidentUpdateCreate(BaseModel):
    message: str


class IncidentUpdateResponse(BaseModel):
    id: int
    user_id: int
    message: str
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class FamilyIncidentResponse(BaseModel):
    id: int
    group_id: int
    reporter_id: int
    title: str
    description: Optional[str] = None
    status: str
    hospital_destination: Optional[str] = None
    updates: List[IncidentUpdateResponse] = []
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# --- Voice assist (round 2, checklist §4) ------------------------------------
class VoiceAssistRequest(BaseModel):
    text: str


class VoiceAssistResponse(BaseModel):
    escalation: str  # CALL_112_NOW / URGENT_SEEK_CARE / SELF_CARE_GUIDANCE
    guide_id: Optional[str] = None
    call_112: bool
    message: str
    advice: List[str]
    guide: Optional[FirstAidGuide] = None


# --- Subscriptions (round 2, checklist §14) ----------------------------------
class SubscriptionPlanInfo(BaseModel):
    plan: str
    price_text: str
    description: str


class SubscriptionSubscribe(BaseModel):
    plan: str


class SubscriptionResponse(BaseModel):
    plan: str
    status: str
    started_at: Optional[datetime] = None
    valid_until: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
