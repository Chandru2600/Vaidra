from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean, UniqueConstraint
from sqlalchemy.sql import func
from app.db import Base
from sqlalchemy.orm import relationship

# Severity values: MINOR, MODERATE, URGENT (stored as plain String to avoid PostgreSQL ENUM issues)

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="CITIZEN")
    name = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Profile fields
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    conditions = Column(Text, nullable=True) # comma-separated
    allergies = Column(Text, nullable=True)
    
    # Location fields
    address = Column(String, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)

    scans = relationship("Scan", back_populates="user")
    emergency_contacts = relationship("EmergencyContact", back_populates="user", cascade="all, delete-orphan")
    lifecard = relationship("LifeCard", back_populates="user", uselist=False, cascade="all, delete-orphan")
    partner = relationship("Partner", back_populates="user", uselist=False, cascade="all, delete-orphan", foreign_keys="Partner.user_id")
    enquiries = relationship("Enquiry", back_populates="user", cascade="all, delete-orphan")
    subscription = relationship("Subscription", back_populates="user", uselist=False, cascade="all, delete-orphan")
    owned_family_groups = relationship("FamilyGroup", back_populates="owner", foreign_keys="FamilyGroup.owner_id")
    family_memberships = relationship("FamilyMember", back_populates="user", cascade="all, delete-orphan")

class Scan(Base):
    __tablename__ = "scans"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    user = relationship("User", back_populates="scans")
    filename = Column(String, nullable=False)
    s3_key = Column(String, nullable=True)
    condition = Column(String, nullable=True)
    confidence = Column(Float, nullable=True)
    severity = Column(String, nullable=True)  # MINOR / MODERATE / URGENT
    steps = Column(Text, nullable=True)    # pipe-separated
    warnings = Column(Text, nullable=True) # pipe-separated
    notes = Column(Text, nullable=True)
    assigned_to = Column(Integer, nullable=True) # doctor user id
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class EmergencyContact(Base):
    """A user's emergency contacts — owner-only, see emergency_contacts.py."""
    __tablename__ = "emergency_contacts"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    user = relationship("User", back_populates="emergency_contacts")
    name = Column(String, nullable=False)
    relationship = Column(String, nullable=True)  # e.g. Mother, Spouse, Friend
    phone = Column(String, nullable=False)
    is_primary = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class LifeCard(Base):
    """One emergency medical card per user.

    share_token is a random URL token. The QR code must encode the public
    token URL (/lifecard/public/{token}), NEVER the medical data itself.
    The public endpoint only ever exposes non-sensitive fields.
    """
    __tablename__ = "lifecards"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    user = relationship("User", back_populates="lifecard", uselist=False)
    blood_group = Column(String, nullable=True)
    allergies = Column(Text, nullable=True)
    conditions = Column(Text, nullable=True)
    medications = Column(Text, nullable=True)   # NEVER exposed publicly
    notes = Column(Text, nullable=True)         # NEVER exposed publicly
    preferred_hospital = Column(String, nullable=True)
    insurance = Column(String, nullable=True)   # NEVER exposed publicly
    share_with_contacts = Column(Boolean, default=False, nullable=False)
    share_token = Column(String, nullable=False, unique=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class AiInteractionLog(Base):
    """Audit log for every AI interaction (scan analysis + triage calls).

    Required by checklist §6: AI decisions logged for audit and safety review.
    """
    __tablename__ = "ai_interaction_logs"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    scan_id = Column(Integer, ForeignKey("scans.id"), nullable=True, index=True)
    model = Column(String, nullable=False)          # e.g. gemini-2.5-flash, triage-keywords-v1
    prompt_version = Column(String, nullable=True)  # e.g. v2-safety-2026-11-25
    result_summary = Column(Text, nullable=True)
    escalation = Column(String, nullable=True)      # e.g. MINOR / CALL_112_NOW
    created_at = Column(DateTime(timezone=True), server_default=func.now())


# --- Round 2: partner portals, enquiries, Family Relay, subscriptions ------

class Partner(Base):
    """A hospital or pharmacy partner account (checklist §7/§9).

    verification_status: pending | verified | rejected. Only VERIFIED
    partners ever appear in public listings.
    Profile fields (specialities, hours_text, emergency_facilities,
    services) are free text AS REPORTED BY THE PARTNER — never verified
    or invented by Vaidra.
    Availability fields are ONLY what the partner reports via
    PUT /partners/me/availability. If a partner never reports, the
    fields stay NULL (absent) — availability is NEVER inferred.
    """
    __tablename__ = "partners"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    user = relationship("User", back_populates="partner", foreign_keys=[user_id])
    org_type = Column(String, nullable=False)  # hospital | pharmacy
    org_name = Column(String, nullable=False)
    address = Column(Text, nullable=True)
    phone = Column(String, nullable=True)
    specialities = Column(Text, nullable=True)
    hours_text = Column(Text, nullable=True)
    emergency_facilities = Column(Text, nullable=True)
    services = Column(Text, nullable=True)
    verification_status = Column(String, default="pending", nullable=False)
    verified_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    # Availability — partner-reported only, see class docstring.
    er_status = Column(String, nullable=True)
    icu_beds_available = Column(Integer, nullable=True)
    general_beds_available = Column(Integer, nullable=True)
    diagnostics_available = Column(Text, nullable=True)
    specialists_available = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    enquiries = relationship("Enquiry", back_populates="partner", cascade="all, delete-orphan")


class Enquiry(Base):
    """A user's enquiry to a verified partner (checklist §7).

    kind: general | appointment_request | stock_enquiry | reservation_request.
    Appointment requests are stored as enquiries ONLY — they are NOT
    confirmed bookings (appointments are a later phase per the checklist).
    """
    __tablename__ = "enquiries"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    user = relationship("User", back_populates="enquiries")
    partner_id = Column(Integer, ForeignKey("partners.id"), nullable=False, index=True)
    partner = relationship("Partner", back_populates="enquiries")
    kind = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    status = Column(String, default="open", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class FamilyGroup(Base):
    """A Family Relay group (checklist §7/§8). One owner, members join
    with an invite code. NO location is ever tracked: only the boolean
    consent flag on FamilyMember is stored."""
    __tablename__ = "family_groups"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    owner = relationship("User", back_populates="owned_family_groups", foreign_keys=[owner_id])
    invite_code = Column(String, nullable=False, unique=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    members = relationship("FamilyMember", back_populates="group", cascade="all, delete-orphan")
    incidents = relationship("FamilyIncident", back_populates="group", cascade="all, delete-orphan")


class FamilyMember(Base):
    """Membership of a user in a Family Relay group.

    can_share_location is a CONSENT FLAG ONLY — no coordinates are ever
    collected or stored anywhere in this feature.
    """
    __tablename__ = "family_members"
    __table_args__ = (UniqueConstraint("group_id", "user_id", name="uq_family_member_group_user"),)
    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("family_groups.id"), nullable=False, index=True)
    group = relationship("FamilyGroup", back_populates="members")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    user = relationship("User", back_populates="family_memberships")
    can_share_location = Column(Boolean, default=False, nullable=False)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())


class FamilyIncident(Base):
    """An emergency incident shared with a Family Relay group."""
    __tablename__ = "family_incidents"
    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("family_groups.id"), nullable=False, index=True)
    group = relationship("FamilyGroup", back_populates="incidents")
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    reporter = relationship("User", foreign_keys=[reporter_id])
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    status = Column(String, default="active", nullable=False)  # active | resolved
    hospital_destination = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    updates = relationship("IncidentUpdate", back_populates="incident", cascade="all, delete-orphan")


class IncidentUpdate(Base):
    """A status update on a family incident (timeline entry)."""
    __tablename__ = "incident_updates"
    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("family_incidents.id"), nullable=False, index=True)
    incident = relationship("FamilyIncident", back_populates="updates")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    user = relationship("User", foreign_keys=[user_id])
    message = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Subscription(Base):
    """A user's subscription (checklist §14). DATA MODEL + API ONLY —
    no real payments: no payment gateway, no card details, nothing is
    ever charged. Paid plans stay in status 'pending_payment' until a
    real payment flow exists; PERSONAL_BASIC is free and active."""
    __tablename__ = "subscriptions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    user = relationship("User", back_populates="subscription")
    plan = Column(String, nullable=False)
    status = Column(String, default="pending_payment", nullable=False)
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    valid_until = Column(DateTime(timezone=True), nullable=True)
