-- LovedOnes App Database Schema
-- PostgreSQL Database for iOS App Backend

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table for patient information
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Family members and caregivers
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    is_primary_contact BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Face recognition data
CREATE TABLE registered_faces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    family_member_id UUID REFERENCES family_members(id) ON DELETE CASCADE,
    person_name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100) NOT NULL,
    face_encoding TEXT, -- Base64 encoded face encoding
    face_landmarks JSONB, -- Face landmarks data
    additional_info TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cognitive assessment sessions
CREATE TABLE cognitive_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_type VARCHAR(50) NOT NULL, -- 'memory_quiz', 'speech_analysis', 'daily_check'
    difficulty_level VARCHAR(20) DEFAULT 'medium',
    total_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    score DECIMAL(5,2),
    duration_seconds INTEGER,
    session_data JSONB, -- Detailed session results
    ai_insights TEXT, -- AI-generated insights
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Memory quiz questions and answers
CREATE TABLE memory_quiz_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL, -- 'image_recognition', 'text_recall', 'spatial'
    difficulty_level VARCHAR(20) NOT NULL,
    image_url TEXT,
    correct_answer TEXT NOT NULL,
    options JSONB, -- Array of answer options
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quiz responses
CREATE TABLE quiz_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES cognitive_sessions(id) ON DELETE CASCADE,
    question_id UUID REFERENCES memory_quiz_questions(id),
    user_answer TEXT,
    is_correct BOOLEAN,
    response_time_seconds INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Speech biomarker data
CREATE TABLE speech_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES cognitive_sessions(id) ON DELETE CASCADE,
    audio_file_url TEXT,
    speech_features JSONB, -- Extracted speech features
    cognitive_load_score DECIMAL(5,2),
    confidence_score DECIMAL(5,2),
    analysis_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tasks and reminders
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    task_type VARCHAR(50) NOT NULL, -- 'medication', 'appointment', 'general', 'voice'
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    due_date TIMESTAMP,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    reminder_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI chat conversations
CREATE TABLE ai_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    conversation_title VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI chat messages
CREATE TABLE ai_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES ai_conversations(id) ON DELETE CASCADE,
    message_type VARCHAR(20) NOT NULL, -- 'user', 'assistant'
    content TEXT NOT NULL,
    metadata JSONB, -- Additional message data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User progress tracking
CREATE TABLE user_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL, -- 'memory_score', 'cognitive_load', 'task_completion'
    metric_value DECIMAL(10,4) NOT NULL,
    measurement_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- App settings and preferences
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, setting_key)
);

-- Emergency contacts and alerts
CREATE TABLE emergency_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL, -- 'fall_detection', 'medication_missed', 'location_alert'
    severity VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high', 'critical'
    message TEXT NOT NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_family_members_user_id ON family_members(user_id);
CREATE INDEX idx_registered_faces_user_id ON registered_faces(user_id);
CREATE INDEX idx_cognitive_sessions_user_id ON cognitive_sessions(user_id);
CREATE INDEX idx_cognitive_sessions_created_at ON cognitive_sessions(created_at);
CREATE INDEX idx_quiz_responses_session_id ON quiz_responses(session_id);
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_ai_messages_conversation_id ON ai_messages(conversation_id);
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_measurement_date ON user_progress(measurement_date);
CREATE INDEX idx_emergency_alerts_user_id ON emergency_alerts(user_id);
CREATE INDEX idx_emergency_alerts_created_at ON emergency_alerts(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_registered_faces_updated_at BEFORE UPDATE ON registered_faces
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_conversations_updated_at BEFORE UPDATE ON ai_conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO users (name, email, phone, date_of_birth, emergency_contact_name, emergency_contact_phone) 
VALUES ('John Doe', 'john.doe@example.com', '+1234567890', '1950-01-15', 'Jane Doe', '+1234567891');

-- Insert sample family members
INSERT INTO family_members (user_id, name, relationship, phone, email, is_primary_contact)
SELECT id, 'Jane Doe', 'Spouse', '+1234567891', 'jane.doe@example.com', TRUE
FROM users WHERE email = 'john.doe@example.com';

INSERT INTO family_members (user_id, name, relationship, phone, email, is_primary_contact)
SELECT id, 'Mike Doe', 'Son', '+1234567892', 'mike.doe@example.com', FALSE
FROM users WHERE email = 'john.doe@example.com';

-- Insert sample memory quiz questions
INSERT INTO memory_quiz_questions (question_text, question_type, difficulty_level, correct_answer, options, category)
VALUES 
('What is the capital of France?', 'text_recall', 'easy', 'Paris', '["London", "Berlin", "Madrid", "Paris"]', 'Geography'),
('Which animal is known as the King of the Jungle?', 'text_recall', 'easy', 'Lion', '["Tiger", "Lion", "Elephant", "Bear"]', 'Animals'),
('What color do you get when you mix red and blue?', 'text_recall', 'medium', 'Purple', '["Green", "Orange", "Purple", "Yellow"]', 'Colors');

-- Insert sample tasks
INSERT INTO tasks (user_id, title, description, task_type, priority, due_date)
SELECT id, 'Take morning medication', 'Take blood pressure medication with breakfast', 'medication', 'high', CURRENT_TIMESTAMP + INTERVAL '1 day'
FROM users WHERE email = 'john.doe@example.com';

INSERT INTO tasks (user_id, title, description, task_type, priority, due_date)
SELECT id, 'Doctor appointment', 'Annual checkup with Dr. Smith', 'appointment', 'medium', CURRENT_TIMESTAMP + INTERVAL '3 days'
FROM users WHERE email = 'john.doe@example.com';


