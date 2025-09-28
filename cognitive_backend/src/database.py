"""
Database connection and models for LovedOnes app
PostgreSQL database integration with SQLAlchemy
"""

import os
import uuid
from datetime import datetime, date
from typing import List, Optional, Dict, Any
from sqlalchemy import create_engine, Column, String, Integer, Float, Boolean, DateTime, Date, Text, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship, Session
from sqlalchemy.dialects.postgresql import UUID
import psycopg2
from psycopg2.extras import RealDictCursor

# Database configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://localhost/lovedones')
# Convert postgres:// to postgresql:// for SQLAlchemy compatibility
if DATABASE_URL.startswith('postgres://'):
    DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)

# Create engine
engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Database Models
class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True)
    phone = Column(String(20))
    date_of_birth = Column(Date)
    emergency_contact_name = Column(String(255))
    emergency_contact_phone = Column(String(20))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    family_members = relationship("FamilyMember", back_populates="user")
    registered_faces = relationship("RegisteredFace", back_populates="user")
    cognitive_sessions = relationship("CognitiveSession", back_populates="user")
    tasks = relationship("Task", back_populates="user")
    ai_conversations = relationship("AIConversation", back_populates="user")
    speech_analysis = relationship("SpeechAnalysis", back_populates="user")
    user_progress = relationship("UserProgress", back_populates="user")
    user_settings = relationship("UserSetting", back_populates="user")
    emergency_alerts = relationship("EmergencyAlert", back_populates="user")

class FamilyMember(Base):
    __tablename__ = "family_members"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False)
    relationship = Column(String(100), nullable=False)
    phone = Column(String(20))
    email = Column(String(255))
    is_primary_contact = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="family_members")
    registered_faces = relationship("RegisteredFace", back_populates="family_member")

class RegisteredFace(Base):
    __tablename__ = "registered_faces"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    family_member_id = Column(UUID(as_uuid=True), ForeignKey("family_members.id"))
    person_name = Column(String(255), nullable=False)
    relationship = Column(String(100), nullable=False)
    face_encoding = Column(Text)  # Base64 encoded
    face_landmarks = Column(JSON)
    additional_info = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="registered_faces")
    family_member = relationship("FamilyMember", back_populates="registered_faces")

class CognitiveSession(Base):
    __tablename__ = "cognitive_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    session_type = Column(String(50), nullable=False)
    difficulty_level = Column(String(20), default="medium")
    total_questions = Column(Integer, default=0)
    correct_answers = Column(Integer, default=0)
    score = Column(Float)
    duration_seconds = Column(Integer)
    session_data = Column(JSON)
    ai_insights = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="cognitive_sessions")
    quiz_responses = relationship("QuizResponse", back_populates="session")
    speech_analysis = relationship("SpeechAnalysis", back_populates="session")

class MemoryQuizQuestion(Base):
    __tablename__ = "memory_quiz_questions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question_text = Column(Text, nullable=False)
    question_type = Column(String(50), nullable=False)
    difficulty_level = Column(String(20), nullable=False)
    image_url = Column(Text)
    correct_answer = Column(Text, nullable=False)
    options = Column(JSON)
    category = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    quiz_responses = relationship("QuizResponse", back_populates="question")

class QuizResponse(Base):
    __tablename__ = "quiz_responses"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("cognitive_sessions.id"), nullable=False)
    question_id = Column(UUID(as_uuid=True), ForeignKey("memory_quiz_questions.id"))
    user_answer = Column(Text)
    is_correct = Column(Boolean)
    response_time_seconds = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    session = relationship("CognitiveSession", back_populates="quiz_responses")
    question = relationship("MemoryQuizQuestion", back_populates="quiz_responses")

class SpeechAnalysis(Base):
    __tablename__ = "speech_analysis"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    session_id = Column(UUID(as_uuid=True), ForeignKey("cognitive_sessions.id"))
    audio_file_url = Column(Text)
    speech_features = Column(JSON)
    cognitive_load_score = Column(Float)
    confidence_score = Column(Float)
    analysis_timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="speech_analysis")
    session = relationship("CognitiveSession", back_populates="speech_analysis")

class Task(Base):
    __tablename__ = "tasks"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    task_type = Column(String(50), nullable=False)
    priority = Column(String(20), default="medium")
    due_date = Column(DateTime)
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime)
    reminder_time = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="tasks")

class AIConversation(Base):
    __tablename__ = "ai_conversations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    conversation_title = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="ai_conversations")
    messages = relationship("AIMessage", back_populates="conversation")

class AIMessage(Base):
    __tablename__ = "ai_messages"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(UUID(as_uuid=True), ForeignKey("ai_conversations.id"), nullable=False)
    message_type = Column(String(20), nullable=False)  # 'user' or 'assistant'
    content = Column(Text, nullable=False)
    metadata = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    conversation = relationship("AIConversation", back_populates="messages")

class UserProgress(Base):
    __tablename__ = "user_progress"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    metric_name = Column(String(100), nullable=False)
    metric_value = Column(Float, nullable=False)
    measurement_date = Column(Date, nullable=False)
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="user_progress")

class UserSetting(Base):
    __tablename__ = "user_settings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    setting_key = Column(String(100), nullable=False)
    setting_value = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="user_settings")

class EmergencyAlert(Base):
    __tablename__ = "emergency_alerts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    alert_type = Column(String(50), nullable=False)
    severity = Column(String(20), nullable=False)
    message = Column(Text, nullable=False)
    is_resolved = Column(Boolean, default=False)
    resolved_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="emergency_alerts")

# Database utility functions
def get_db() -> Session:
    """Get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialize database tables"""
    Base.metadata.create_all(bind=engine)

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Get user by email"""
    return db.query(User).filter(User.email == email).first()

def create_user(db: Session, name: str, email: str, phone: str = None) -> User:
    """Create new user"""
    user = User(name=name, email=email, phone=phone)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def get_user_tasks(db: Session, user_id: str, completed: bool = None) -> List[Task]:
    """Get user tasks with optional completion filter"""
    query = db.query(Task).filter(Task.user_id == user_id)
    if completed is not None:
        query = query.filter(Task.is_completed == completed)
    return query.order_by(Task.due_date).all()

def create_task(db: Session, user_id: str, title: str, task_type: str, 
                description: str = None, priority: str = "medium", 
                due_date: datetime = None) -> Task:
    """Create new task"""
    task = Task(
        user_id=user_id,
        title=title,
        description=description,
        task_type=task_type,
        priority=priority,
        due_date=due_date
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task

def get_cognitive_sessions(db: Session, user_id: str, limit: int = 10) -> List[CognitiveSession]:
    """Get user's cognitive sessions"""
    return db.query(CognitiveSession).filter(
        CognitiveSession.user_id == user_id
    ).order_by(CognitiveSession.created_at.desc()).limit(limit).all()

def create_cognitive_session(db: Session, user_id: str, session_type: str, 
                           difficulty_level: str = "medium") -> CognitiveSession:
    """Create new cognitive session"""
    session = CognitiveSession(
        user_id=user_id,
        session_type=session_type,
        difficulty_level=difficulty_level
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session

def get_registered_faces(db: Session, user_id: str) -> List[RegisteredFace]:
    """Get user's registered faces"""
    return db.query(RegisteredFace).filter(RegisteredFace.user_id == user_id).all()

def create_registered_face(db: Session, user_id: str, person_name: str, 
                          relationship: str, face_encoding: str = None,
                          face_landmarks: Dict = None) -> RegisteredFace:
    """Create new registered face"""
    face = RegisteredFace(
        user_id=user_id,
        person_name=person_name,
        relationship=relationship,
        face_encoding=face_encoding,
        face_landmarks=face_landmarks
    )
    db.add(face)
    db.commit()
    db.refresh(face)
    return face

def get_user_progress(db: Session, user_id: str, metric_name: str = None, 
                     days: int = 30) -> List[UserProgress]:
    """Get user progress data"""
    query = db.query(UserProgress).filter(
        UserProgress.user_id == user_id,
        UserProgress.measurement_date >= date.today() - datetime.timedelta(days=days)
    )
    if metric_name:
        query = query.filter(UserProgress.metric_name == metric_name)
    return query.order_by(UserProgress.measurement_date.desc()).all()

def create_user_progress(db: Session, user_id: str, metric_name: str, 
                        metric_value: float, notes: str = None) -> UserProgress:
    """Create user progress entry"""
    progress = UserProgress(
        user_id=user_id,
        metric_name=metric_name,
        metric_value=metric_value,
        measurement_date=date.today(),
        notes=notes
    )
    db.add(progress)
    db.commit()
    db.refresh(progress)
    return progress
