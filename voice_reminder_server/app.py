from flask import Flask, request, jsonify
import requests
import os
import json
from datetime import datetime
import uuid

app = Flask(__name__)

# VAPI Configuration
VAPI_API_KEY = os.environ.get("VAPI_API_KEY", "19de0c70-e127-4e3d-b65b-833376a4de0c")
VAPI_BASE_URL = "https://api.vapi.ai"

# Phone number configuration
PHONE_NUMBER_ID = "e90ccb0c-f63b-4651-9a02-5f6110637a79"

# OpenAI Configuration
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "YOUR_OPENAI_API_KEY_HERE")

def process_voice_reminder(text: str):
    """Process voice reminder text using OpenAI to extract structured data"""
    
    system_prompt = """You are a voice reminder assistant for an Alzheimer's support app called Cherish. Your role is to help users create structured reminders by listening to their voice commands and extracting key information.

**Your Tasks:**
1. Listen to the user's reminder request
2. Identify the reminder type (medication, appointment, or general)
3. Extract key details like person name, timing, and specific instructions
4. Normalize dates and times to proper formats
5. Return ONLY a structured JSON object

**Guidelines:**
- Be friendly, patient, and clear
- Ask clarifying questions if important information is missing
- Convert relative dates (tomorrow, next week) to absolute dates in America/New_York timezone
- Convert times to 24-hour format (e.g., 8 PM becomes 20:00)
- For medications: extract drug name, strength, timing, and instructions
- For appointments: extract date/time, location, and person
- For general reminders: extract description and due date
- Always confirm the reminder details before saving

**Response Format:**
Return ONLY a JSON object with this structure:
{
  "type": "med|appointment|general",
  "title": "Clear title for the reminder",
  "personName": "Name of person (optional)",
  "payload": {
    "drugName": "Medication name (for med reminders)",
    "strength": "Dosage strength (e.g., '500mg')",
    "instructions": "Special instructions",
    "time": "Time in 24-hour format (e.g., '20:00')",
    "days": ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],
    "datetime": "Full date and time in ISO 8601 format (for appointments)",
    "clinic": "Clinic name (for appointments)",
    "address": "Address (for appointments)",
    "description": "Detailed description",
    "dueDate": "Due date in ISO 8601 format (for general reminders)"
  },
  "naturalLanguage": "Natural language summary of what the user said",
  "timezone": "America/New_York",
  "priority": "time_sensitive|standard"
}"""

    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Process this voice reminder: {text}"}
        ],
        "temperature": 0.1,
        "max_tokens": 1000
    }
    
    try:
        response = requests.post(
            "https://api.openai.com/v1/chat/completions",
            headers=headers,
            json=data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            content = result['choices'][0]['message']['content']
            
            # Try to parse JSON from the response
            try:
                reminder_data = json.loads(content)
                return reminder_data
            except json.JSONDecodeError:
                # If not valid JSON, return a basic structure
                return {
                    "type": "general",
                    "title": "Voice Reminder",
                    "personName": None,
                    "payload": {
                        "description": text
                    },
                    "naturalLanguage": text,
                    "timezone": "America/New_York",
                    "priority": "standard"
                }
        else:
            print(f"OpenAI Error: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"Error calling OpenAI: {str(e)}")
        return None

def create_vapi_call(phone_number: str, message: str):
    """Create a VAPI call for voice reminder"""
    
    call_data = {
        "phoneNumberId": PHONE_NUMBER_ID,
        "customer": {
            "number": phone_number
        },
        "assistantId": "0b140e87-cb49-47e7-913d-df5aec5c96f9",
        "assistantOverrides": {
            "firstMessage": message,
            "voice": {
                "provider": "elevenlabs",
                "voiceId": "21m00Tcm4TlvDq8ikWAM"
            }
        },
        "maxDurationSeconds": 300,
        "recordingEnabled": True
    }
    
    headers = {
        "Authorization": f"Bearer {VAPI_API_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(
            f"{VAPI_BASE_URL}/call",
            headers=headers,
            json=call_data,
            timeout=30
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"VAPI Error: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"Error creating VAPI call: {str(e)}")
        return None

@app.route('/')
def home():
    return "LovedOnes Voice Reminder Server is running!"

@app.route('/health')
def health_check():
    return jsonify({"status": "healthy", "service": "voice-reminder"}), 200

@app.route('/process-voice-reminder', methods=['POST'])
def process_voice_reminder_endpoint():
    """Process voice reminder text and return structured data"""
    try:
        data = request.json or {}
        text = data.get('text', '')
        
        if not text:
            return jsonify({
                "success": False,
                "message": "No text provided"
            }), 400
        
        # Process the voice reminder
        reminder_data = process_voice_reminder(text)
        
        if reminder_data:
            return jsonify({
                "success": True,
                "reminder": reminder_data,
                "message": "Voice reminder processed successfully"
            }), 200
        else:
            return jsonify({
                "success": False,
                "message": "Failed to process voice reminder"
            }), 500
            
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error: {str(e)}"
        }), 500

@app.route('/create-voice-call', methods=['POST'])
def create_voice_call():
    """Create a VAPI call for voice reminder"""
    try:
        data = request.json or {}
        phone_number = data.get('phone_number', '')
        message = data.get('message', '')
        
        if not phone_number or not message:
            return jsonify({
                "success": False,
                "message": "Phone number and message are required"
            }), 400
        
        # Create the VAPI call
        call_result = create_vapi_call(phone_number, message)
        
        if call_result:
            return jsonify({
                "success": True,
                "message": "Voice call initiated successfully",
                "callId": call_result.get("id"),
                "phoneNumber": phone_number
            }), 200
        else:
            return jsonify({
                "success": False,
                "message": "Failed to initiate voice call"
            }), 500
            
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error: {str(e)}"
        }), 500

@app.route('/call-status/<call_id>', methods=['GET'])
def get_call_status(call_id):
    """Get status of a call"""
    try:
        headers = {
            "Authorization": f"Bearer {VAPI_API_KEY}",
            "Content-Type": "application/json"
        }
        
        response = requests.get(
            f"{VAPI_BASE_URL}/call/{call_id}",
            headers=headers,
            timeout=30
        )
        
        if response.status_code == 200:
            return jsonify(response.json()), 200
        else:
            return jsonify({
                "success": False,
                "message": f"Error getting call status: {response.status_code}"
            }), 500
            
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error: {str(e)}"
        }), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get("PORT", 5001)))
