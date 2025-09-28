from flask import Flask, request, jsonify, send_file
import os
import json
from datetime import datetime

app = Flask(__name__)

# Audio files directory
AUDIO_DIR = "data"

# Voice note metadata
VOICE_NOTES = {
    "I love you grandpa": {
        "filename": "I love you grandpa .mp3",
        "speaker": "Emma",
        "relationship": "Granddaughter",
        "duration": "3.2s",
        "message": "I love you grandpa",
        "timestamp": "2024-09-27T22:50:20Z"
    },
    "I love the special s": {
        "filename": "I love the special s.mp3",
        "speaker": "Tommy",
        "relationship": "Son",
        "duration": "2.8s",
        "message": "I love the special moments we share",
        "timestamp": "2024-09-27T22:54:32Z"
    },
    "I am cooking pasta t": {
        "filename": "I am cooking pasta t.mp3",
        "speaker": "Sarah",
        "relationship": "Wife",
        "duration": "2.5s",
        "message": "I am cooking pasta tonight",
        "timestamp": "2024-09-27T22:57:18Z"
    },
    "When I get old I wil": {
        "filename": "When I get old I wil.mp3",
        "speaker": "Emma",
        "relationship": "Granddaughter",
        "duration": "4.1s",
        "message": "When I get old I will remember these times",
        "timestamp": "2024-09-27T22:36:43Z"
    },
    "I love you David": {
        "filename": "I love you David .mp3",
        "speaker": "Sarah",
        "relationship": "Wife",
        "duration": "2.9s",
        "message": "I love you David",
        "timestamp": "2024-09-27T22:36:44Z"
    },
    "I love you David 1": {
        "filename": "I love you David 1.mp3",
        "speaker": "Tommy",
        "relationship": "Son",
        "duration": "3.0s",
        "message": "I love you David",
        "timestamp": "2024-09-27T22:38:34Z"
    }
}

@app.route('/')
def home():
    return "LovedOnes Audio Backend Server is running!"

@app.route('/health')
def health_check():
    return jsonify({"status": "healthy", "service": "audio-backend"}), 200

@app.route('/voice-notes')
def get_voice_notes():
    """Get all available voice notes"""
    try:
        voice_notes_list = []
        
        for key, note in VOICE_NOTES.items():
            file_path = os.path.join(AUDIO_DIR, note["filename"])
            if os.path.exists(file_path):
                voice_notes_list.append({
                    "id": key,
                    "filename": note["filename"],
                    "speaker": note["speaker"],
                    "relationship": note["relationship"],
                    "duration": note["duration"],
                    "message": note["message"],
                    "timestamp": note["timestamp"],
                    "url": f"/audio/{key}"
                })
        
        return jsonify({
            "success": True,
            "voice_notes": voice_notes_list,
            "count": len(voice_notes_list)
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error getting voice notes: {str(e)}"
        }), 500

@app.route('/voice-notes/<note_id>')
def get_voice_note(note_id):
    """Get specific voice note details"""
    try:
        if note_id not in VOICE_NOTES:
            return jsonify({
                "success": False,
                "message": "Voice note not found"
            }), 404
        
        note = VOICE_NOTES[note_id]
        file_path = os.path.join(AUDIO_DIR, note["filename"])
        
        if not os.path.exists(file_path):
            return jsonify({
                "success": False,
                "message": "Audio file not found"
            }), 404
        
        return jsonify({
            "success": True,
            "voice_note": {
                "id": note_id,
                "filename": note["filename"],
                "speaker": note["speaker"],
                "relationship": note["relationship"],
                "duration": note["duration"],
                "message": note["message"],
                "timestamp": note["timestamp"],
                "url": f"/audio/{note_id}"
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error getting voice note: {str(e)}"
        }), 500

@app.route('/audio/<note_id>')
def serve_audio(note_id):
    """Serve audio file"""
    try:
        if note_id not in VOICE_NOTES:
            return jsonify({"error": "Voice note not found"}), 404
        
        note = VOICE_NOTES[note_id]
        file_path = os.path.join(AUDIO_DIR, note["filename"])
        
        if not os.path.exists(file_path):
            return jsonify({"error": "Audio file not found"}), 404
        
        return send_file(
            file_path,
            as_attachment=False,
            mimetype='audio/mpeg',
            download_name=note["filename"]
        )
        
    except Exception as e:
        return jsonify({"error": f"Error serving audio: {str(e)}"}), 500

@app.route('/voice-notes/by-memory/<memory_id>')
def get_voice_notes_by_memory(memory_id):
    """Get voice notes associated with a specific memory"""
    try:
        # Map memory IDs to voice notes
        memory_voice_mapping = {
            "memorylane_1": ["I love you grandpa"],
            "memorylane_2": ["I love the special s"],
            "memorylane_3": ["I am cooking pasta t"],
            "memorylane_4": ["When I get old I wil"],
            "memorylane_5": ["I love you David"],
            "memorylane_6": ["I love you David 1"],
            "memorylane_7": ["I love you grandpa"],  # Reuse for additional memories
            "memorylane_8": ["I love the special s"],
            "memorylane_9": ["I am cooking pasta t"],
            "memorylane_10": ["When I get old I wil"],
            "memorylane_11": ["I love you David"],
            "memorylane_12": ["I love you David 1"]
        }
        
        if memory_id not in memory_voice_mapping:
            return jsonify({
                "success": True,
                "voice_notes": [],
                "count": 0
            }), 200
        
        voice_note_ids = memory_voice_mapping[memory_id]
        voice_notes_list = []
        
        for note_id in voice_note_ids:
            if note_id in VOICE_NOTES:
                note = VOICE_NOTES[note_id]
                file_path = os.path.join(AUDIO_DIR, note["filename"])
                if os.path.exists(file_path):
                    voice_notes_list.append({
                        "id": note_id,
                        "filename": note["filename"],
                        "speaker": note["speaker"],
                        "relationship": note["relationship"],
                        "duration": note["duration"],
                        "message": note["message"],
                        "timestamp": note["timestamp"],
                        "url": f"/audio/{note_id}"
                    })
        
        return jsonify({
            "success": True,
            "voice_notes": voice_notes_list,
            "count": len(voice_notes_list)
        }), 200
        
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Error getting voice notes for memory: {str(e)}"
        }), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get("PORT", 5001)))

