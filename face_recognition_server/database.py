"""
Database models for Face Recognition Server
"""

from sqlalchemy import create_engine, Column, String, DateTime, Text, Integer
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from datetime import datetime
import os
import uuid
from sqlalchemy.dialects.postgresql import UUID

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/face_recognition_db")
# Convert postgres:// to postgresql:// for SQLAlchemy compatibility
if DATABASE_URL.startswith('postgres://'):
    DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)

Base = declarative_base()

class RegisteredFace(Base):
    __tablename__ = "registered_faces"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    person_name = Column(String, nullable=False)
    relationship = Column(String)
    additional_info = Column(Text)
    bounding_box = Column(Text)  # JSON string of bounding box coordinates
    landmarks = Column(Text)     # JSON string of landmarks
    face_vector = Column(Text)   # JSON string of face encoding/vector (128-dimensional)
    image_data = Column(Text)    # Base64 encoded image data
    created_at = Column(DateTime(timezone=True), default=datetime.now)

engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def init_db():
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# CRUD Operations
def create_face(db: Session, person_name: str, relationship: str, additional_info: str, bounding_box: str, landmarks: str, face_vector: str, image_data: str = None):
    db_face = RegisteredFace(
        person_name=person_name,
        relationship=relationship,
        additional_info=additional_info,
        bounding_box=bounding_box,
        landmarks=landmarks,
        face_vector=face_vector,
        image_data=image_data
    )
    db.add(db_face)
    db.commit()
    db.refresh(db_face)
    return db_face

def get_all_faces(db: Session):
    return db.query(RegisteredFace).all()

def get_face_by_id(db: Session, face_id: str):
    return db.query(RegisteredFace).filter(RegisteredFace.id == face_id).first()

def delete_face(db: Session, face_id: str):
    face = db.query(RegisteredFace).filter(RegisteredFace.id == face_id).first()
    if face:
        db.delete(face)
        db.commit()
        return True
    return False

def delete_all_faces(db: Session):
    """Delete all registered faces"""
    db.query(RegisteredFace).delete()
    db.commit()
    return True
