#!/usr/bin/env python3
"""
Database migration script to add face_vector column
"""

from database import engine
from sqlalchemy import text

def add_face_vector_column():
    """Add face_vector column to registered_faces table"""
    try:
        with engine.connect() as conn:
            # Check if column already exists
            result = conn.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name='registered_faces' 
                AND column_name='face_vector'
            """))
            
            if result.fetchone():
                print("✅ face_vector column already exists")
                return True
            
            # Add the face_vector column
            conn.execute(text('ALTER TABLE registered_faces ADD COLUMN face_vector TEXT'))
            conn.commit()
            print("✅ Successfully added face_vector column to registered_faces table")
            return True
            
    except Exception as e:
        print(f"❌ Error adding column: {e}")
        return False

if __name__ == "__main__":
    add_face_vector_column()


