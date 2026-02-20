from sqlalchemy import Column, Integer, String, Float, DateTime, Enum as SQLAEnum, ForeignKey, Text
from sqlalchemy.sql import func
from app.db import Base
import enum
from sqlalchemy.orm import relationship

class Severity(enum.Enum):
    MINOR = "MINOR"
    MODERATE = "MODERATE"
    URGENT = "URGENT"

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
    severity = Column(SQLAEnum(Severity), nullable=True)
    steps = Column(Text, nullable=True)    # pipe-separated
    warnings = Column(Text, nullable=True) # pipe-separated
    notes = Column(Text, nullable=True)
    assigned_to = Column(Integer, nullable=True) # doctor user id
    created_at = Column(DateTime(timezone=True), server_default=func.now())
