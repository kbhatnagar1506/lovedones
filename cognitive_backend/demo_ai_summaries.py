#!/usr/bin/env python3
"""
Demo script showing AI-powered summaries for cognitive assessment
This demonstrates the fallback functionality when OpenAI API is not available
"""

import sys
import os
sys.path.append('src')

from openai_summarizer import OpenAISummarizer
import json

def demo_ai_summaries():
    """Demo the AI summarization features"""
    print("🤖 AI-Powered Cognitive Assessment Summaries Demo")
    print("=" * 60)
    
    # Create summarizer (will use fallback mode)
    summarizer = OpenAISummarizer("demo_key")
    
    # Demo 1: Session Summary
    print("\n📊 Session Summary Demo")
    print("-" * 30)
    
    session_data = {
        'accuracy': 0.75,
        'avg_response_time': 4.2,
        'cognitive_load': 'moderate',
        'total_questions': 8,
        'difficulty_level': 'mixed'
    }
    
    session_summary = summarizer.generate_session_summary(session_data)
    print("Session Data:", json.dumps(session_data, indent=2))
    print("\nAI Summary:")
    print(json.dumps(session_summary, indent=2))
    
    # Demo 2: Progress Summary
    print("\n📈 Progress Summary Demo")
    print("-" * 30)
    
    progress_data = {
        'total_sessions': 12,
        'avg_accuracy': 0.68,
        'recent_accuracy': 0.72,
        'trend': 'improving',
        'avg_response_time': 5.1,
        'last_session': '2024-09-27T19:30:00'
    }
    
    progress_summary = summarizer.generate_progress_summary(progress_data)
    print("Progress Data:", json.dumps(progress_data, indent=2))
    print("\nAI Summary:")
    print(json.dumps(progress_summary, indent=2))
    
    # Demo 3: Clinician Report
    print("\n🏥 Clinician Report Demo")
    print("-" * 30)
    
    assessment_data = {
        'overall_accuracy': 0.72,
        'overall_latency': 4.8,
        'performance_trend': 'improving',
        'improvement_score': 0.15,
        'load_band_distribution': {'low': 3, 'moderate': 7, 'high': 2},
        'total_sessions': 12
    }
    
    clinician_report = summarizer.generate_clinician_report(assessment_data)
    print("Assessment Data:", json.dumps(assessment_data, indent=2))
    print("\nAI Report:")
    print(json.dumps(clinician_report, indent=2))
    
    # Demo 4: Family Insights
    print("\n👨‍👩‍👧‍👦 Family Insights Demo")
    print("-" * 30)
    
    family_data = {
        'memory_performance': 'moderate',
        'cognitive_load_patterns': 'variable',
        'engagement_level': 'good',
        'family_involvement': 'active',
        'recent_changes': 'stable'
    }
    
    family_insights = summarizer.generate_family_insights(family_data)
    print("Family Data:", json.dumps(family_data, indent=2))
    print("\nAI Insights:")
    print(json.dumps(family_insights, indent=2))
    
    # Demo 5: Memory Story
    print("\n📖 Memory Story Demo")
    print("-" * 30)
    
    memory_item = {
        'title': 'Grandma\'s Morning Coffee',
        'description': 'Grandma\'s favorite morning routine',
        'family_member': 'Grandma',
        'difficulty': 1
    }
    
    performance = {
        'correct': True,
        'response_time_sec': 2.3,
        'cognitive_load': 'low'
    }
    
    memory_story = summarizer.generate_memory_story(memory_item, performance)
    print("Memory Item:", json.dumps(memory_item, indent=2))
    print("Performance:", json.dumps(performance, indent=2))
    print("\nAI Memory Story:")
    print(f'"{memory_story}"')
    
    print("\n" + "=" * 60)
    print("✅ AI Summaries Demo Complete!")
    print("\nNote: This demo uses fallback summaries when OpenAI API is not available.")
    print("To use real AI summaries, set a valid OPENAI_API_KEY environment variable.")

if __name__ == "__main__":
    demo_ai_summaries()


