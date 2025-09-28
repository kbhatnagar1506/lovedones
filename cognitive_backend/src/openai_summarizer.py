"""
OpenAI-powered summarization and insights generation
Creates personalized summaries and recommendations for cognitive assessment results
"""

import openai
import json
import os
from typing import Dict, List, Any
from datetime import datetime
import pandas as pd

class OpenAISummarizer:
    """
    OpenAI-powered summarization for cognitive assessment results
    """
    
    def __init__(self, api_key: str):
        openai.api_key = api_key
        self.model = "gpt-4o-mini"  # Using GPT-4o-mini for cost efficiency
    
    def generate_session_summary(self, session_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate personalized summary for a quiz session"""
        
        # Convert string values to appropriate types
        accuracy = float(session_data.get('accuracy', 0))
        avg_response_time = float(session_data.get('avg_response_time', 0))
        cognitive_load = session_data.get('cognitive_load', 'unknown')
        total_questions = int(session_data.get('total_questions', 0))
        difficulty_level = session_data.get('difficulty_level', 'mixed')
        
        prompt = f"""
        You are a compassionate cognitive health specialist analyzing a memory assessment session for an elderly person with potential Alzheimer's/dementia concerns.
        
        Session Data:
        - Accuracy: {accuracy:.1%}
        - Average Response Time: {avg_response_time:.1f} seconds
        - Cognitive Load: {cognitive_load}
        - Total Questions: {total_questions}
        - Difficulty Level: {difficulty_level}
        
        Generate:
        1. A warm, encouraging summary (2-3 sentences)
        2. Key insights about their memory performance
        3. Specific recommendations for family members
        4. Encouraging next steps
        
        Format as JSON with keys: summary, insights, family_recommendations, next_steps
        """
        
        try:
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a compassionate cognitive health specialist helping families with Alzheimer's care."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=500
            )
            
            content = response.choices[0].message.content
            # Try to parse as JSON, fallback to structured text
            try:
                return json.loads(content)
            except json.JSONDecodeError:
                return self._parse_text_response(content)
                
        except Exception as e:
            print(f"OpenAI API error: {e}")
            return self._generate_fallback_summary(session_data)
    
    def generate_progress_summary(self, progress_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate summary for user's overall progress"""
        
        # Convert string values to appropriate types
        total_sessions = int(progress_data.get('total_sessions', 0))
        avg_accuracy = float(progress_data.get('avg_accuracy', 0))
        recent_accuracy = float(progress_data.get('recent_accuracy', 0))
        trend = progress_data.get('trend', 'stable')
        avg_response_time = float(progress_data.get('avg_response_time', 0))
        last_session = progress_data.get('last_session', 'unknown')
        
        prompt = f"""
        You are analyzing the cognitive progress of an elderly person over multiple memory assessment sessions.
        
        Progress Data:
        - Total Sessions: {total_sessions}
        - Average Accuracy: {avg_accuracy:.1%}
        - Recent Accuracy: {recent_accuracy:.1%}
        - Trend: {trend}
        - Average Response Time: {avg_response_time:.1f} seconds
        - Last Session: {last_session}
        
        Generate:
        1. Progress overview (encouraging tone)
        2. Trend analysis and what it means
        3. Recommendations for continued care
        4. When to consult healthcare providers
        
        Format as JSON with keys: overview, trend_analysis, care_recommendations, healthcare_guidance
        """
        
        try:
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a compassionate cognitive health specialist providing family guidance."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=600
            )
            
            content = response.choices[0].message.content
            try:
                return json.loads(content)
            except json.JSONDecodeError:
                return self._parse_text_response(content)
                
        except Exception as e:
            print(f"OpenAI API error: {e}")
            return self._generate_fallback_progress_summary(progress_data)
    
    def generate_clinician_report(self, assessment_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate professional clinician report"""
        
        # Convert string values to appropriate types
        overall_accuracy = float(assessment_data.get('overall_accuracy', 0))
        overall_latency = float(assessment_data.get('overall_latency', 0))
        performance_trend = assessment_data.get('performance_trend', 'stable')
        improvement_score = float(assessment_data.get('improvement_score', 0))
        load_band_distribution = assessment_data.get('load_band_distribution', {})
        total_sessions = int(assessment_data.get('total_sessions', 0))
        
        prompt = f"""
        You are a clinical neuropsychologist writing a professional assessment report for a patient with cognitive concerns.
        
        Assessment Data:
        - Overall Accuracy: {overall_accuracy:.1%}
        - Average Response Time: {overall_latency:.1f} seconds
        - Performance Trend: {performance_trend}
        - Improvement Score: {improvement_score:.3f}
        - Load Band Distribution: {load_band_distribution}
        - Total Sessions: {total_sessions}
        
        Generate a professional report with:
        1. Executive Summary (clinical findings)
        2. Performance Analysis (detailed assessment)
        3. Clinical Recommendations (evidence-based)
        4. Monitoring Plan (ongoing care)
        
        Use professional medical terminology while remaining accessible to family members.
        Format as JSON with keys: executive_summary, performance_analysis, clinical_recommendations, monitoring_plan
        """
        
        try:
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a clinical neuropsychologist writing professional assessment reports."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.6,
                max_tokens=800
            )
            
            content = response.choices[0].message.content
            try:
                return json.loads(content)
            except json.JSONDecodeError:
                return self._parse_text_response(content)
                
        except Exception as e:
            print(f"OpenAI API error: {e}")
            return self._generate_fallback_clinician_report(assessment_data)
    
    def generate_family_insights(self, family_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate family-specific insights and recommendations"""
        
        prompt = f"""
        You are a family counselor specializing in Alzheimer's and dementia care, providing guidance to families.
        
        Family Assessment Data:
        - Patient's Memory Performance: {family_data.get('memory_performance', 'moderate')}
        - Cognitive Load Patterns: {family_data.get('cognitive_load_patterns', 'variable')}
        - Engagement Level: {family_data.get('engagement_level', 'good')}
        - Family Involvement: {family_data.get('family_involvement', 'active')}
        - Recent Changes: {family_data.get('recent_changes', 'stable')}
        
        Generate family guidance including:
        1. Understanding the assessment results (family-friendly explanation)
        2. Daily care strategies (practical tips)
        3. Communication techniques (how to interact)
        4. When to seek professional help (warning signs)
        5. Family support resources (emotional and practical)
        
        Use warm, supportive language that empowers families.
        Format as JSON with keys: results_explanation, daily_strategies, communication_tips, warning_signs, support_resources
        """
        
        try:
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a compassionate family counselor specializing in dementia care."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.8,
                max_tokens=700
            )
            
            content = response.choices[0].message.content
            try:
                return json.loads(content)
            except json.JSONDecodeError:
                return self._parse_text_response(content)
                
        except Exception as e:
            print(f"OpenAI API error: {e}")
            return self._generate_fallback_family_insights(family_data)
    
    def generate_memory_story(self, memory_item: Dict[str, Any], performance: Dict[str, Any]) -> str:
        """Generate a personalized story about a memory item based on performance"""
        
        prompt = f"""
        Create a warm, personalized story about this family memory based on the person's performance.
        
        Memory Item:
        - Title: {memory_item.get('title', 'Family Memory')}
        - Description: {memory_item.get('description', 'A special family moment')}
        - Family Member: {memory_item.get('family_member', 'Loved One')}
        - Difficulty: {memory_item.get('difficulty', 2)}
        
        Performance:
        - Correct: {performance.get('correct', False)}
        - Response Time: {performance.get('response_time_sec', 0):.1f} seconds
        - Cognitive Load: {performance.get('cognitive_load', 'moderate')}
        
        Write a 2-3 sentence story that:
        1. Celebrates the memory if they got it right
        2. Gently encourages if they struggled
        3. Connects it to family love and connection
        4. Uses warm, encouraging language
        
        Make it personal and emotionally supportive.
        """
        
        try:
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a compassionate storyteller helping families preserve precious memories."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.9,
                max_tokens=200
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            print(f"OpenAI API error: {e}")
            return self._generate_fallback_memory_story(memory_item, performance)
    
    def _parse_text_response(self, content: str) -> Dict[str, str]:
        """Parse text response into structured format"""
        lines = content.strip().split('\n')
        result = {}
        current_key = None
        current_value = []
        
        for line in lines:
            line = line.strip()
            if line.endswith(':'):
                if current_key:
                    result[current_key] = ' '.join(current_value).strip()
                current_key = line[:-1].lower().replace(' ', '_')
                current_value = []
            elif line and current_key:
                current_value.append(line)
        
        if current_key:
            result[current_key] = ' '.join(current_value).strip()
        
        return result
    
    def _generate_fallback_summary(self, session_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate fallback summary when OpenAI is unavailable"""
        # Convert to float safely
        try:
            accuracy = float(session_data.get('accuracy', 0))
        except (ValueError, TypeError):
            accuracy = 0.0
        
        if accuracy >= 0.8:
            summary = "Great job! You showed excellent memory performance today."
            insights = "Your memory skills are strong and consistent."
        elif accuracy >= 0.6:
            summary = "Good work! You're doing well with your memory exercises."
            insights = "Your memory performance is solid with room for continued improvement."
        else:
            summary = "Keep practicing! Every memory exercise helps strengthen your cognitive abilities."
            insights = "Focus on regular practice to improve memory retention and recall."
        
        return {
            "summary": summary,
            "insights": insights,
            "family_recommendations": "Continue encouraging regular memory exercises and celebrate small victories.",
            "next_steps": "Try the next difficulty level or practice with familiar memories."
        }
    
    def _generate_fallback_progress_summary(self, progress_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate fallback progress summary"""
        trend = progress_data.get('trend', 'stable')
        
        if trend == 'improving':
            overview = "Excellent progress! Your memory skills are getting stronger over time."
        elif trend == 'stable':
            overview = "Consistent performance! You're maintaining good memory function."
        else:
            overview = "Keep up the practice! Regular exercises will help improve your memory."
        
        return {
            "overview": overview,
            "trend_analysis": f"Your performance trend shows {trend} memory function.",
            "care_recommendations": "Continue with regular memory exercises and family engagement.",
            "healthcare_guidance": "Monitor for any significant changes and consult healthcare providers if needed."
        }
    
    def _generate_fallback_clinician_report(self, assessment_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate fallback clinician report"""
        # Convert to float safely
        try:
            accuracy = float(assessment_data.get('overall_accuracy', 0))
        except (ValueError, TypeError):
            accuracy = 0.0
        
        if accuracy >= 0.8:
            summary = "Patient demonstrates strong cognitive performance with high accuracy and good response times."
        elif accuracy >= 0.6:
            summary = "Patient shows moderate cognitive performance with room for improvement through continued practice."
        else:
            summary = "Patient may benefit from additional cognitive support and regular memory exercises."
        
        return {
            "executive_summary": summary,
            "performance_analysis": f"Overall accuracy of {accuracy:.1%} indicates {('strong' if accuracy >= 0.8 else 'moderate' if accuracy >= 0.6 else 'developing')} memory function.",
            "clinical_recommendations": "Continue regular cognitive assessments and family engagement activities.",
            "monitoring_plan": "Schedule follow-up assessments and monitor for any significant changes."
        }
    
    def _generate_fallback_family_insights(self, family_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate fallback family insights"""
        return {
            "results_explanation": "The assessment helps us understand memory patterns and areas for support.",
            "daily_strategies": "Encourage regular memory exercises and maintain familiar routines.",
            "communication_tips": "Use clear, simple language and be patient during conversations.",
            "warning_signs": "Watch for significant changes in memory, mood, or daily functioning.",
            "support_resources": "Connect with local Alzheimer's associations and support groups."
        }
    
    def _generate_fallback_memory_story(self, memory_item: Dict[str, Any], performance: Dict[str, Any]) -> str:
        """Generate fallback memory story"""
        title = memory_item.get('title', 'this special memory')
        if performance.get('correct', False):
            return f"What a wonderful memory of {title}! Your ability to recall this shows the strength of your family connections and the love you share."
        else:
            return f"Memories like {title} are precious treasures. Take your time to remember - these family moments are worth every effort to preserve."

def create_openai_summarizer() -> OpenAISummarizer:
    """Create OpenAI summarizer with API key from environment"""
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        # Try to load from a config file
        try:
            with open('config/openai_key.txt', 'r') as f:
                api_key = f.read().strip()
        except FileNotFoundError:
            print("⚠️ OpenAI API key not found. Set OPENAI_API_KEY environment variable or create config/openai_key.txt")
            return None
    
    return OpenAISummarizer(api_key)

if __name__ == "__main__":
    # Test the summarizer
    summarizer = create_openai_summarizer()
    
    if summarizer:
        # Test session summary
        session_data = {
            'accuracy': 0.75,
            'avg_response_time': 4.2,
            'cognitive_load': 'moderate',
            'total_questions': 8,
            'difficulty_level': 'mixed'
        }
        
        summary = summarizer.generate_session_summary(session_data)
        print("Session Summary:")
        print(json.dumps(summary, indent=2))
    else:
        print("OpenAI summarizer not available - using fallback summaries")
