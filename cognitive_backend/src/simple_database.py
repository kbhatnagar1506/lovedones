"""
Simplified database connection for LovedOnes app
PostgreSQL database integration with SQLAlchemy
"""

import os
from datetime import datetime, date
from typing import List, Optional, Dict, Any
from sqlalchemy import create_engine, Column, String, Integer, Float, Boolean, DateTime, Date, Text, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.dialects.postgresql import UUID
import uuid

# Database configuration
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://localhost/lovedones')
# Convert postgres:// to postgresql:// for SQLAlchemy compatibility
if DATABASE_URL.startswith('postgres://'):
    DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)

# Create engine
engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Simplified Database Models
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

class UserProgress(Base):
    __tablename__ = "user_progress"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    metric_name = Column(String(100), nullable=False)
    metric_value = Column(Float, nullable=False)
    measurement_date = Column(Date, nullable=False)
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

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

def create_user(db: Session, name: str, email: str, phone: str = None) -> User:
    """Create new user"""
    user = User(name=name, email=email, phone=phone)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Get user by email"""
    return db.query(User).filter(User.email == email).first()

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
