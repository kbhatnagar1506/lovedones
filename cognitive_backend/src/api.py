"""
Flask API for Cognitive Assessment Backend
Provides endpoints for iOS app integration
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
import uuid
from datetime import datetime
import numpy as np

from speech_model import SpeechBiomarkerModel
from qlearning_scheduler import QLearningScheduler
from memory_quiz import MemoryQuizSystem
from openai_summarizer import create_openai_summarizer
# Face recognition moved to separate server
# from face_recognition_service import face_service
from simple_database import get_db, init_db, create_user, get_user_by_email, create_task, get_user_tasks, create_user_progress, get_user_progress
from sqlalchemy.orm import Session

app = Flask(__name__)
CORS(app)

# Initialize models
speech_model = None
scheduler = None
quiz_system = None
openai_summarizer = None

def initialize_models():
    """Initialize all models and database"""
    global speech_model, scheduler, quiz_system, openai_summarizer
    
    # Initialize database
    init_db()
    
    # Initialize speech model
    speech_model = SpeechBiomarkerModel()
    if os.path.exists('../outputs/speech_model.json'):
        speech_model.load_model('../outputs/speech_model.json')
    
    # Initialize Q-learning scheduler
    scheduler = QLearningScheduler()
    if os.path.exists('../outputs/qlearning_model.json'):
        scheduler.load_model('../outputs/qlearning_model.json')
    
    # Initialize quiz system
    quiz_system = MemoryQuizSystem('../data/memory_items.csv')
    
    # Initialize OpenAI summarizer
    openai_summarizer = create_openai_summarizer()

# Database-powered endpoints
@app.route('/api/users', methods=['POST'])
def create_user_endpoint():
    """Create a new user"""
    try:
        data = request.get_json()
        if not data or 'name' not in data or 'email' not in data:
            return jsonify({"error": "Name and email are required"}), 400
        
        db = next(get_db())
        user = create_user(
            db=db,
            name=data['name'],
            email=data['email'],
            phone=data.get('phone')
        )
        
        return jsonify({
            "success": True,
            "user": {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "created_at": user.created_at.isoformat() if user.created_at else None
            }
        }), 201
        
    except Exception as e:
        print(f"❌ Error creating user: {str(e)}")
        error_msg = str(e)
        if "duplicate key value violates unique constraint" in error_msg and "users_email_key" in error_msg:
            return jsonify({"error": "Email already exists. Please use a different email or try signing in."}), 409
        return jsonify({"error": f"Error creating user: {str(e)}"}), 500

@app.route('/api/users/login', methods=['POST'])
def login_user_endpoint():
    """Login user by email"""
    try:
        data = request.get_json()
        if not data or 'email' not in data:
            return jsonify({"error": "Email is required"}), 400
        
        db = next(get_db())
        user = get_user_by_email(db, data['email'])
        
        if not user:
            return jsonify({"error": "User not found. Please sign up first."}), 404
        
        return jsonify({
            "success": True,
            "user": {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "created_at": user.created_at.isoformat() if user.created_at else None
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Error logging in user: {str(e)}")
        return jsonify({"error": f"Error logging in user: {str(e)}"}), 500

@app.route('/api/users/<user_id>/tasks', methods=['GET'])
def get_user_tasks_endpoint(user_id):
    """Get user tasks"""
    try:
        db = next(get_db())
        completed = request.args.get('completed')
        completed_bool = None
        if completed:
            completed_bool = completed.lower() == 'true'
        
        tasks = get_user_tasks(db, user_id, completed_bool)
        
        return jsonify({
            "success": True,
            "tasks": [{
                "id": str(task.id),
                "title": task.title,
                "description": task.description,
                "task_type": task.task_type,
                "priority": task.priority,
                "due_date": task.due_date.isoformat() if task.due_date else None,
                "is_completed": task.is_completed,
                "completed_at": task.completed_at.isoformat() if task.completed_at else None,
                "created_at": task.created_at.isoformat() if task.created_at else None
            } for task in tasks]
        })
        
    except Exception as e:
        return jsonify({"error": f"Error fetching tasks: {str(e)}"}), 500

@app.route('/api/users/<user_id>/tasks', methods=['POST'])
def create_task_endpoint(user_id):
    """Create a new task"""
    try:
        data = request.get_json()
        if not data or 'title' not in data or 'task_type' not in data:
            return jsonify({"error": "Title and task_type are required"}), 400
        
        db = next(get_db())
        task = create_task(
            db=db,
            user_id=user_id,
            title=data['title'],
            task_type=data['task_type'],
            description=data.get('description'),
            priority=data.get('priority', 'medium'),
            due_date=datetime.fromisoformat(data['due_date']) if data.get('due_date') else None
        )
        
        return jsonify({
            "success": True,
            "task": {
                "id": str(task.id),
                "title": task.title,
                "description": task.description,
                "task_type": task.task_type,
                "priority": task.priority,
                "due_date": task.due_date.isoformat() if task.due_date else None,
                "is_completed": task.is_completed,
                "created_at": task.created_at.isoformat() if task.created_at else None
            }
        }), 201
        
    except Exception as e:
        return jsonify({"error": f"Error creating task: {str(e)}"}), 500

@app.route('/api/users/<user_id>/progress', methods=['GET'])
def get_user_progress_endpoint(user_id):
    """Get user progress data"""
    try:
        metric_name = request.args.get('metric_name')
        days = int(request.args.get('days', 30))
        
        db = next(get_db())
        progress = get_user_progress(db, user_id, metric_name, days)
        
        return jsonify({
            "success": True,
            "progress": [{
                "id": str(p.id),
                "metric_name": p.metric_name,
                "metric_value": p.metric_value,
                "measurement_date": p.measurement_date.isoformat() if p.measurement_date else None,
                "notes": p.notes,
                "created_at": p.created_at.isoformat() if p.created_at else None
            } for p in progress]
        })
        
    except Exception as e:
        return jsonify({"error": f"Error fetching progress: {str(e)}"}), 500

@app.route('/api/users/<user_id>/progress', methods=['POST'])
def create_user_progress_endpoint(user_id):
    """Create user progress entry"""
    try:
        data = request.get_json()
        if not data or 'metric_name' not in data or 'metric_value' not in data:
            return jsonify({"error": "metric_name and metric_value are required"}), 400
        
        db = next(get_db())
        progress = create_user_progress(
            db=db,
            user_id=user_id,
            metric_name=data['metric_name'],
            metric_value=data['metric_value'],
            notes=data.get('notes')
        )
        
        return jsonify({
            "success": True,
            "progress": {
                "id": str(progress.id),
                "metric_name": progress.metric_name,
                "metric_value": progress.metric_value,
                "measurement_date": progress.measurement_date.isoformat() if progress.measurement_date else None,
                "notes": progress.notes,
                "created_at": progress.created_at.isoformat() if progress.created_at else None
            }
        }), 201
        
    except Exception as e:
        return jsonify({"error": f"Error creating progress entry: {str(e)}"}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'models_loaded': {
            'speech_model': speech_model is not None,
            'scheduler': scheduler is not None,
            'quiz_system': quiz_system is not None,
            'openai_summarizer': openai_summarizer is not None
        }
    })

@app.route('/init-db', methods=['POST'])
def init_database():
    """Initialize database tables"""
    try:
        init_db()
        return jsonify({
            "success": True,
            "message": "Database initialized successfully"
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Error initializing database: {str(e)}"
        }), 500

@app.route('/speech/analyze', methods=['POST'])
def analyze_speech():
    """Analyze speech features and return cognitive load assessment"""
    try:
        data = request.get_json()
        
        if not data or 'features' not in data:
            return jsonify({'error': 'Speech features required'}), 400
        
        features = data['features']
        required_features = ['wpm', 'pause_rate', 'ttr', 'jitter', 'articulation_rate']
        
        # Validate features
        missing_features = [f for f in required_features if f not in features]
        if missing_features:
            return jsonify({
                'error': f'Missing features: {missing_features}',
                'required': required_features
            }), 400
        
        # Predict cognitive load band
        load_band = speech_model.predict_load_band(features)
        
        # Calculate confidence (simplified)
        confidence = 0.85  # In practice, calculate based on model uncertainty
        
        return jsonify({
            'cognitive_load_band': load_band,
            'confidence': confidence,
            'timestamp': datetime.now().isoformat(),
            'features_analyzed': features
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/memory/quiz/create', methods=['POST'])
def create_quiz():
    """Create a new memory quiz session"""
    try:
        data = request.get_json()
        
        user_id = data.get('user_id', 'anonymous')
        difficulty_level = data.get('difficulty_level', 'mixed')
        n_questions = data.get('n_questions', 8)
        
        # Validate parameters
        if difficulty_level not in ['easy', 'medium', 'hard', 'mixed']:
            return jsonify({'error': 'Invalid difficulty level'}), 400
        
        if not 1 <= n_questions <= 16:
            return jsonify({'error': 'Number of questions must be between 1 and 16'}), 400
        
        # Create quiz session
        session = quiz_system.create_quiz_session(user_id, difficulty_level, n_questions)
        
        return jsonify({
            'success': True,
            'session': session
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/memory/quiz/submit', methods=['POST'])
def submit_quiz_answer():
    """Submit an answer for a quiz question"""
    try:
        data = request.get_json()
        
        required_fields = ['session_id', 'question_id', 'selected_option_id', 'response_time_ms']
        missing_fields = [f for f in required_fields if f not in data]
        if missing_fields:
            return jsonify({'error': f'Missing fields: {missing_fields}'}), 400
        
        result = quiz_system.submit_answer(
            data['session_id'],
            data['question_id'],
            data['selected_option_id'],
            data['response_time_ms']
        )
        
        if 'error' in result:
            return jsonify(result), 400
        
        return jsonify({
            'success': True,
            'result': result
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/memory/quiz/complete', methods=['POST'])
def complete_quiz():
    """Complete a quiz session and get final results"""
    try:
        data = request.get_json()
        
        if 'session_id' not in data:
            return jsonify({'error': 'session_id required'}), 400
        
        result = quiz_system.complete_session(data['session_id'])
        
        if 'error' in result:
            return jsonify(result), 400
        
        return jsonify({
            'success': True,
            'results': result
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/memory/quiz/progress/<user_id>', methods=['GET'])
def get_user_progress(user_id):
    """Get user's quiz progress"""
    try:
        progress = quiz_system.get_user_progress(user_id)
        
        if 'error' in progress:
            return jsonify(progress), 404
        
        return jsonify({
            'success': True,
            'progress': progress
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/scheduler/next_interval', methods=['POST'])
def get_next_interval():
    """Get next review interval for a memory item"""
    try:
        data = request.get_json()
        
        required_fields = ['item_id', 'difficulty', 'load_band']
        missing_fields = [f for f in required_fields if f not in data]
        if missing_fields:
            return jsonify({'error': f'Missing fields: {missing_fields}'}), 400
        
        interval = scheduler.get_next_interval(
            data['item_id'],
            data['difficulty'],
            data['load_band']
        )
        
        return jsonify({
            'success': True,
            'next_interval_seconds': interval,
            'next_interval_minutes': interval / 60.0,
            'item_id': data['item_id']
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/scheduler/record_result', methods=['POST'])
def record_scheduler_result():
    """Record the result of a memory review session"""
    try:
        data = request.get_json()
        
        required_fields = ['item_id', 'correct', 'latency_sec', 'difficulty', 'load_band']
        missing_fields = [f for f in required_fields if f not in data]
        if missing_fields:
            return jsonify({'error': f'Missing fields: {missing_fields}'}), 400
        
        scheduler.record_result(
            data['item_id'],
            data['correct'],
            data['latency_sec'],
            data['difficulty'],
            data['load_band']
        )
        
        # Get updated statistics
        stats = scheduler.get_item_statistics(data['item_id'])
        
        return jsonify({
            'success': True,
            'item_statistics': stats
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/scheduler/item_stats/<int:item_id>', methods=['GET'])
def get_item_statistics(item_id):
    """Get statistics for a specific memory item"""
    try:
        stats = scheduler.get_item_statistics(item_id)
        
        if not stats:
            return jsonify({'error': 'Item not found or no sessions recorded'}), 404
        
        return jsonify({
            'success': True,
            'item_id': item_id,
            'statistics': stats
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/memory/items', methods=['GET'])
def get_memory_items():
    """Get all available memory items"""
    try:
        items = quiz_system.memory_items.to_dict('records')
        
        return jsonify({
            'success': True,
            'items': items,
            'total_count': len(items)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/memory/items/<int:item_id>', methods=['GET'])
def get_memory_item(item_id):
    """Get a specific memory item"""
    try:
        item = quiz_system.memory_items[quiz_system.memory_items['item_id'] == item_id]
        
        if item.empty:
            return jsonify({'error': 'Item not found'}), 404
        
        return jsonify({
            'success': True,
            'item': item.iloc[0].to_dict()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/analytics/session_summary', methods=['POST'])
def get_session_summary():
    """Get analytics summary for a time period"""
    try:
        data = request.get_json()
        
        start_date = data.get('start_date')
        end_date = data.get('end_date')
        user_id = data.get('user_id')
        
        # This would implement more sophisticated analytics
        # For now, return basic summary
        summary = {
            'total_sessions': 0,
            'avg_accuracy': 0.0,
            'avg_response_time': 0.0,
            'cognitive_load_distribution': {'low': 0, 'moderate': 0, 'high': 0},
            'difficulty_performance': {},
            'recommendations': []
        }
        
        return jsonify({
            'success': True,
            'summary': summary
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/ai/session_summary', methods=['POST'])
def generate_ai_session_summary():
    """Generate AI-powered session summary"""
    try:
        data = request.get_json()
        
        if not openai_summarizer:
            return jsonify({'error': 'OpenAI summarizer not available'}), 503
        
        session_data = data.get('session_data', {})
        summary = openai_summarizer.generate_session_summary(session_data)
        
        return jsonify({
            'success': True,
            'ai_summary': summary
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/ai/progress_summary', methods=['POST'])
def generate_ai_progress_summary():
    """Generate AI-powered progress summary"""
    try:
        data = request.get_json()
        
        if not openai_summarizer:
            return jsonify({'error': 'OpenAI summarizer not available'}), 503
        
        progress_data = data.get('progress_data', {})
        summary = openai_summarizer.generate_progress_summary(progress_data)
        
        return jsonify({
            'success': True,
            'ai_summary': summary
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/ai/clinician_report', methods=['POST'])
def generate_ai_clinician_report():
    """Generate AI-powered clinician report"""
    try:
        data = request.get_json()
        
        if not openai_summarizer:
            return jsonify({'error': 'OpenAI summarizer not available'}), 503
        
        assessment_data = data.get('assessment_data', {})
        report = openai_summarizer.generate_clinician_report(assessment_data)
        
        return jsonify({
            'success': True,
            'ai_report': report
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/ai/family_insights', methods=['POST'])
def generate_ai_family_insights():
    """Generate AI-powered family insights"""
    try:
        data = request.get_json()
        
        if not openai_summarizer:
            return jsonify({'error': 'OpenAI summarizer not available'}), 503
        
        family_data = data.get('family_data', {})
        insights = openai_summarizer.generate_family_insights(family_data)
        
        return jsonify({
            'success': True,
            'ai_insights': insights
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/ai/memory_story', methods=['POST'])
def generate_ai_memory_story():
    """Generate AI-powered memory story"""
    try:
        data = request.get_json()
        
        if not openai_summarizer:
            return jsonify({'error': 'OpenAI summarizer not available'}), 503
        
        memory_item = data.get('memory_item', {})
        performance = data.get('performance', {})
        story = openai_summarizer.generate_memory_story(memory_item, performance)
        
        return jsonify({
            'success': True,
            'memory_story': story
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

# Face Recognition Endpoints moved to separate server
# All face recognition functionality is now handled by:
# https://lovedones-face-recognition-810d8ea9f3d0.herokuapp.com

if __name__ == '__main__':
    # Initialize models
    initialize_models()
    
    # Create outputs directory
    os.makedirs('outputs', exist_ok=True)
    
    # Run the app
    app.run(host='0.0.0.0', port=5001, debug=True)
