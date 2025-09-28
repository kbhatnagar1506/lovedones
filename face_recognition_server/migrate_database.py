#!/usr/bin/env python3
"""
Database migration script to add image_data column
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/face_recognition_db")

# Convert postgres:// to postgresql:// for psycopg2 compatibility
if DATABASE_URL.startswith('postgres://'):
    DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)

def migrate_database():
    """Add image_data column to registered_faces table"""
    try:
        print("🔧 Connecting to database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        
        print("🔧 Adding image_data column...")
        cursor.execute("""
            ALTER TABLE registered_faces 
            ADD COLUMN IF NOT EXISTS image_data TEXT;
        """)
        
        conn.commit()
        print("✅ Database migration completed successfully!")
        
    except Exception as e:
        print(f"❌ Error migrating database: {e}")
        if conn:
            conn.rollback()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    migrate_database()


