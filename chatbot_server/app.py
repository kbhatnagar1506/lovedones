#!/usr/bin/env python3
"""
LovedOnes Chatbot Server
A Flask-based server that provides AI chatbot functionality using OpenAI API
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import openai
import os
import logging
from datetime import datetime
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# OpenAI API configuration
OPENAI_API_KEY = "YOUR_OPENAI_API_KEY_HERE"
openai.api_key = OPENAI_API_KEY

# System prompt for the LovedOnes chatbot
SYSTEM_PROMPT = """You are a caring AI assistant for the LovedOnes app, helping families with elderly loved ones. Be warm, patient, and understanding. Keep responses concise (1-2 sentences) and helpful. Focus on practical caregiving advice, emotional support, and memory care tips. For medical concerns, suggest consulting healthcare professionals."""

# Store conversation history (in production, use a database)
conversation_history = {}

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "LovedOnes Chatbot",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
        
        user_message = data.get('message', '').strip()
        user_id = data.get('user_id', 'default')
        conversation_id = data.get('conversation_id', f"conv_{user_id}")
        
        if not user_message:
            return jsonify({"error": "No message provided"}), 400
        
        logger.info(f"Received message from user {user_id}: {user_message[:100]}...")
        
        # Get or create conversation history
        if conversation_id not in conversation_history:
            conversation_history[conversation_id] = []
        
        # Add user message to history
        conversation_history[conversation_id].append({
            "role": "user",
            "content": user_message
        })
        
        # Prepare messages for OpenAI
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        
        # Add recent conversation history (last 10 messages to avoid token limits)
        recent_history = conversation_history[conversation_id][-10:]
        messages.extend(recent_history)
        
        # Call OpenAI API
        try:
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=messages,
                max_tokens=150,
                temperature=0.5,
                top_p=0.9,
                frequency_penalty=0.0,
                presence_penalty=0.0
            )
            
            ai_response = response.choices[0].message.content.strip()
            
            # Add AI response to history
            conversation_history[conversation_id].append({
                "role": "assistant",
                "content": ai_response
            })
            
            logger.info(f"Generated response for user {user_id}: {ai_response[:100]}...")
            
            return jsonify({
                "success": True,
                "response": ai_response,
                "conversation_id": conversation_id,
                "timestamp": datetime.now().isoformat()
            })
            
        except openai.error.OpenAIError as e:
            logger.error(f"OpenAI API error: {str(e)}")
            return jsonify({
                "success": False,
                "error": "AI service temporarily unavailable",
                "message": "I'm having trouble connecting to my AI brain right now. Please try again in a moment."
            }), 500
            
        except Exception as e:
            logger.error(f"Unexpected error in OpenAI call: {str(e)}")
            return jsonify({
                "success": False,
                "error": "Internal server error",
                "message": "Something went wrong. Please try again."
            }), 500
    
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "message": "I'm experiencing some technical difficulties. Please try again."
        }), 500

@app.route('/conversation/<conversation_id>', methods=['GET'])
def get_conversation(conversation_id):
    """Get conversation history"""
    try:
        if conversation_id in conversation_history:
            return jsonify({
                "success": True,
                "conversation_id": conversation_id,
                "messages": conversation_history[conversation_id],
                "count": len(conversation_history[conversation_id])
            })
        else:
            return jsonify({
                "success": True,
                "conversation_id": conversation_id,
                "messages": [],
                "count": 0
            })
    except Exception as e:
        logger.error(f"Error getting conversation: {str(e)}")
        return jsonify({"error": "Failed to retrieve conversation"}), 500

@app.route('/conversation/<conversation_id>', methods=['DELETE'])
def clear_conversation(conversation_id):
    """Clear conversation history"""
    try:
        if conversation_id in conversation_history:
            del conversation_history[conversation_id]
            return jsonify({
                "success": True,
                "message": "Conversation cleared"
            })
        else:
            return jsonify({
                "success": True,
                "message": "No conversation found to clear"
            })
    except Exception as e:
        logger.error(f"Error clearing conversation: {str(e)}")
        return jsonify({"error": "Failed to clear conversation"}), 500

@app.route('/suggestions', methods=['POST'])
def get_suggestions():
    """Get conversation starter suggestions"""
    try:
        data = request.get_json()
        context = data.get('context', 'general')
        
        suggestions = {
            "general": [
                "How can I help my loved one with memory exercises?",
                "What are some safe activities for someone with dementia?",
                "How do I handle difficult behaviors?",
                "What should I do if my loved one gets confused?",
                "How can I improve communication with my family member?"
            ],
            "memory_care": [
                "What memory games are good for Alzheimer's patients?",
                "How can I create a memory book?",
                "What are reminiscence therapy techniques?",
                "How do I handle memory loss with dignity?",
                "What are signs of memory improvement?"
            ],
            "daily_care": [
                "How do I establish a daily routine?",
                "What are tips for medication management?",
                "How can I make meals easier?",
                "What about personal hygiene assistance?",
                "How do I handle sleep issues?"
            ],
            "emotional_support": [
                "I'm feeling overwhelmed as a caregiver",
                "How do I deal with caregiver guilt?",
                "What about my own mental health?",
                "How do I ask for help from family?",
                "I'm worried about the future"
            ]
        }
        
        return jsonify({
            "success": True,
            "suggestions": suggestions.get(context, suggestions["general"]),
            "context": context
        })
        
    except Exception as e:
        logger.error(f"Error getting suggestions: {str(e)}")
        return jsonify({"error": "Failed to get suggestions"}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    logger.info(f"Starting LovedOnes Chatbot Server on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)
