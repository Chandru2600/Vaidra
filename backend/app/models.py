from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
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
