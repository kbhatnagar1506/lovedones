"""
Memory Lane Quiz System
Handles picture-based memory tests and cognitive assessments
"""

import numpy as np
import pandas as pd
import json
import os
from typing import Dict, List, Tuple, Optional
from datetime import datetime, timedelta
import random

class MemoryQuizSystem:
    """
    Memory quiz system for cognitive assessment
    """
    
    def __init__(self, memory_items_path: str):
        self.memory_items = pd.read_csv(memory_items_path)
        self.quiz_sessions = []
        self.user_responses = {}
        
    def create_quiz_session(self, user_id: str, difficulty_level: str = 'mixed',
                          n_questions: int = 8) -> Dict:
        """Create a new quiz session"""
        session_id = f"{user_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        # Filter items based on difficulty
        if difficulty_level == 'easy':
            items = self.memory_items[self.memory_items['difficulty'] == 1]
        elif difficulty_level == 'medium':
            items = self.memory_items[self.memory_items['difficulty'] == 2]
        elif difficulty_level == 'hard':
            items = self.memory_items[self.memory_items['difficulty'] == 3]
        else:  # mixed
            items = self.memory_items
        
        # Sample questions
        if len(items) < n_questions:
            n_questions = len(items)
        
        selected_items = items.sample(n=n_questions)
        
        # Create quiz questions
        questions = []
        for idx, (_, item) in enumerate(selected_items.iterrows()):
            question = {
                'question_id': f"{session_id}_q{idx+1}",
                'item_id': item['item_id'],
                'title': item['title'],
                'description': item['description'],
                'image_path': item['image_path'],
                'family_member': item['family_member'],
                'difficulty': item['difficulty'],
                'question_type': self._get_question_type(item['difficulty']),
                'options': self._generate_options(item, selected_items)
            }
            questions.append(question)
        
        # Shuffle questions
        random.shuffle(questions)
        
        session = {
            'session_id': session_id,
            'user_id': user_id,
            'created_at': datetime.now().isoformat(),
            'difficulty_level': difficulty_level,
            'n_questions': n_questions,
            'questions': questions,
            'status': 'active',
            'responses': [],
            'metrics': {}
        }
        
        self.quiz_sessions.append(session)
        return session
    
    def _get_question_type(self, difficulty: int) -> str:
        """Determine question type based on difficulty"""
        if difficulty == 1:
            return random.choice(['recognition', 'simple_recall'])
        elif difficulty == 2:
            return random.choice(['recognition', 'context_recall', 'temporal_recall'])
        else:
            return random.choice(['complex_recall', 'temporal_recall', 'context_recall'])
    
    def _generate_options(self, correct_item: pd.Series, all_items: pd.DataFrame) -> List[Dict]:
        """Generate multiple choice options"""
        # Get 3 incorrect options
        incorrect_items = all_items[all_items['item_id'] != correct_item['item_id']].sample(n=3)
        
        options = []
        
        # Add correct option
        options.append({
            'option_id': f"opt_{correct_item['item_id']}",
            'text': correct_item['title'],
            'is_correct': True,
            'item_id': correct_item['item_id']
        })
        
        # Add incorrect options
        for _, item in incorrect_items.iterrows():
            options.append({
                'option_id': f"opt_{item['item_id']}",
                'text': item['title'],
                'is_correct': False,
                'item_id': item['item_id']
            })
        
        # Shuffle options
        random.shuffle(options)
        return options
    
    def submit_answer(self, session_id: str, question_id: str, 
                     selected_option_id: str, response_time_ms: int) -> Dict:
        """Submit an answer for a quiz question"""
        # Find session
        session = next((s for s in self.quiz_sessions if s['session_id'] == session_id), None)
        if not session:
            return {'error': 'Session not found'}
        
        # Find question
        question = next((q for q in session['questions'] if q['question_id'] == question_id), None)
        if not question:
            return {'error': 'Question not found'}
        
        # Check if already answered
        if any(r['question_id'] == question_id for r in session['responses']):
            return {'error': 'Question already answered'}
        
        # Find correct option
        correct_option = next((opt for opt in question['options'] if opt['is_correct']), None)
        is_correct = selected_option_id == correct_option['option_id']
        
        # Calculate response metrics
        response_time_sec = response_time_ms / 1000.0
        
        response = {
            'question_id': question_id,
            'selected_option_id': selected_option_id,
            'is_correct': is_correct,
            'response_time_ms': response_time_ms,
            'response_time_sec': response_time_sec,
            'difficulty': question['difficulty'],
            'question_type': question['question_type'],
            'timestamp': datetime.now().isoformat()
        }
        
        session['responses'].append(response)
        
        # Update session metrics
        self._update_session_metrics(session)
        
        return {
            'is_correct': is_correct,
            'correct_option_id': correct_option['option_id'],
            'response_time_sec': response_time_sec,
            'session_metrics': session['metrics']
        }
    
    def _update_session_metrics(self, session: Dict):
        """Update session-level metrics"""
        responses = session['responses']
        if not responses:
            return
        
        # Basic metrics
        total_questions = len(responses)
        correct_answers = sum(1 for r in responses if r['is_correct'])
        accuracy = correct_answers / total_questions
        
        # Response time metrics
        response_times = [r['response_time_sec'] for r in responses]
        avg_response_time = np.mean(response_times)
        median_response_time = np.median(response_times)
        
        # Difficulty-based metrics
        difficulty_metrics = {}
        for difficulty in [1, 2, 3]:
            diff_responses = [r for r in responses if r['difficulty'] == difficulty]
            if diff_responses:
                diff_correct = sum(1 for r in diff_responses if r['is_correct'])
                difficulty_metrics[f'difficulty_{difficulty}'] = {
                    'accuracy': diff_correct / len(diff_responses),
                    'avg_response_time': np.mean([r['response_time_sec'] for r in diff_responses]),
                    'count': len(diff_responses)
                }
        
        # Question type metrics
        type_metrics = {}
        question_types = set(r['question_type'] for r in responses)
        for qtype in question_types:
            type_responses = [r for r in responses if r['question_type'] == qtype]
            type_correct = sum(1 for r in type_responses if r['is_correct'])
            type_metrics[qtype] = {
                'accuracy': type_correct / len(type_responses),
                'avg_response_time': np.mean([r['response_time_sec'] for r in type_responses]),
                'count': len(type_responses)
            }
        
        # Cognitive load estimation (simplified)
        cognitive_load = self._estimate_cognitive_load(responses)
        
        session['metrics'] = {
            'total_questions': total_questions,
            'correct_answers': correct_answers,
            'accuracy': accuracy,
            'avg_response_time': avg_response_time,
            'median_response_time': median_response_time,
            'difficulty_metrics': difficulty_metrics,
            'type_metrics': type_metrics,
            'cognitive_load': cognitive_load,
            'completion_rate': len(responses) / session['n_questions']
        }
    
    def _estimate_cognitive_load(self, responses: List[Dict]) -> str:
        """Estimate cognitive load based on response patterns"""
        if not responses:
            return 'unknown'
        
        # Factors that increase cognitive load
        avg_response_time = np.mean([r['response_time_sec'] for r in responses])
        accuracy = sum(1 for r in responses if r['is_correct']) / len(responses)
        difficulty_variance = np.var([r['difficulty'] for r in responses])
        
        # Simple heuristic
        load_score = 0
        
        # Response time factor
        if avg_response_time > 8.0:
            load_score += 2
        elif avg_response_time > 5.0:
            load_score += 1
        
        # Accuracy factor
        if accuracy < 0.6:
            load_score += 2
        elif accuracy < 0.8:
            load_score += 1
        
        # Difficulty variance factor
        if difficulty_variance > 1.0:
            load_score += 1
        
        # Convert to load band
        if load_score >= 4:
            return 'high'
        elif load_score >= 2:
            return 'moderate'
        else:
            return 'low'
    
    def complete_session(self, session_id: str) -> Dict:
        """Mark session as complete and return final results"""
        session = next((s for s in self.quiz_sessions if s['session_id'] == session_id), None)
        if not session:
            return {'error': 'Session not found'}
        
        session['status'] = 'completed'
        session['completed_at'] = datetime.now().isoformat()
        
        # Generate insights
        insights = self._generate_insights(session)
        session['insights'] = insights
        
        return {
            'session_id': session_id,
            'final_metrics': session['metrics'],
            'insights': insights,
            'recommendations': self._generate_recommendations(session)
        }
    
    def _generate_insights(self, session: Dict) -> List[str]:
        """Generate insights from session performance"""
        insights = []
        metrics = session['metrics']
        
        # Accuracy insights
        if metrics['accuracy'] >= 0.9:
            insights.append("Excellent memory performance! You're doing great with recall.")
        elif metrics['accuracy'] >= 0.7:
            insights.append("Good memory performance with room for improvement.")
        elif metrics['accuracy'] >= 0.5:
            insights.append("Memory performance could be improved with practice.")
        else:
            insights.append("Consider focusing on memory exercises and techniques.")
        
        # Response time insights
        if metrics['avg_response_time'] <= 3.0:
            insights.append("Very quick responses - excellent cognitive processing speed.")
        elif metrics['avg_response_time'] <= 6.0:
            insights.append("Good response times - processing speed is within normal range.")
        else:
            insights.append("Consider exercises to improve processing speed.")
        
        # Difficulty-based insights
        if 'difficulty_3' in metrics['difficulty_metrics']:
            hard_accuracy = metrics['difficulty_metrics']['difficulty_3']['accuracy']
            if hard_accuracy >= 0.7:
                insights.append("Great job with challenging memories!")
            elif hard_accuracy < 0.4:
                insights.append("Focus on practicing with more challenging memories.")
        
        # Cognitive load insights
        load = metrics['cognitive_load']
        if load == 'high':
            insights.append("High cognitive load detected - consider taking breaks between sessions.")
        elif load == 'low':
            insights.append("Low cognitive load - you might be ready for more challenging exercises.")
        
        return insights
    
    def _generate_recommendations(self, session: Dict) -> List[str]:
        """Generate recommendations based on performance"""
        recommendations = []
        metrics = session['metrics']
        
        # Accuracy-based recommendations
        if metrics['accuracy'] < 0.7:
            recommendations.append("Practice with easier memories first to build confidence.")
            recommendations.append("Try using memory techniques like association and visualization.")
        
        # Response time recommendations
        if metrics['avg_response_time'] > 6.0:
            recommendations.append("Practice with timed exercises to improve processing speed.")
        
        # Difficulty recommendations
        if 'difficulty_1' in metrics['difficulty_metrics']:
            easy_accuracy = metrics['difficulty_metrics']['difficulty_1']['accuracy']
            if easy_accuracy >= 0.9:
                recommendations.append("Ready to try more challenging memories!")
        
        # Cognitive load recommendations
        load = metrics['cognitive_load']
        if load == 'high':
            recommendations.append("Take shorter, more frequent sessions to reduce cognitive load.")
            recommendations.append("Practice relaxation techniques before memory exercises.")
        
        # General recommendations
        recommendations.append("Regular practice will help maintain and improve memory function.")
        recommendations.append("Consider involving family members in memory exercises for better engagement.")
        
        return recommendations
    
    def get_user_progress(self, user_id: str) -> Dict:
        """Get overall progress for a user"""
        user_sessions = [s for s in self.quiz_sessions if s['user_id'] == user_id and s['status'] == 'completed']
        
        if not user_sessions:
            return {'error': 'No completed sessions found'}
        
        # Aggregate metrics
        total_sessions = len(user_sessions)
        avg_accuracy = np.mean([s['metrics']['accuracy'] for s in user_sessions])
        avg_response_time = np.mean([s['metrics']['avg_response_time'] for s in user_sessions])
        
        # Trend analysis
        recent_sessions = user_sessions[-5:] if len(user_sessions) >= 5 else user_sessions
        recent_accuracy = np.mean([s['metrics']['accuracy'] for s in recent_sessions])
        
        trend = 'improving' if recent_accuracy > avg_accuracy else 'stable' if recent_accuracy == avg_accuracy else 'declining'
        
        return {
            'user_id': user_id,
            'total_sessions': total_sessions,
            'avg_accuracy': avg_accuracy,
            'avg_response_time': avg_response_time,
            'recent_accuracy': recent_accuracy,
            'trend': trend,
            'last_session': user_sessions[-1]['completed_at'] if user_sessions else None
        }
    
    def save_session_data(self, filepath: str):
        """Save all session data to file"""
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            json.dump(self.quiz_sessions, f, indent=2, default=str)
    
    def load_session_data(self, filepath: str):
        """Load session data from file"""
        with open(filepath, 'r') as f:
            self.quiz_sessions = json.load(f)

if __name__ == "__main__":
    # Example usage
    quiz_system = MemoryQuizSystem('data/memory_items.csv')
    
    # Create a quiz session
    session = quiz_system.create_quiz_session('user123', difficulty_level='mixed', n_questions=6)
    print(f"Created session: {session['session_id']}")
    print(f"Questions: {len(session['questions'])}")
    
    # Simulate answering questions
    for question in session['questions'][:3]:  # Answer first 3 questions
        # Simulate response
        response_time = random.randint(2000, 8000)  # 2-8 seconds
        selected_option = random.choice(question['options'])['option_id']
        
        result = quiz_system.submit_answer(
            session['session_id'],
            question['question_id'],
            selected_option,
            response_time
        )
        print(f"Question {question['question_id']}: {result['is_correct']}")
    
    # Complete session
    final_result = quiz_system.complete_session(session['session_id'])
    print(f"Final accuracy: {final_result['final_metrics']['accuracy']:.2f}")
    print(f"Insights: {final_result['insights']}")


