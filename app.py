import cv2
import numpy as np
import base64
import json
import uuid
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from database import get_db, create_face, get_all_faces, delete_all_faces

app = Flask(__name__)
CORS(app)

class OptimizedFaceRecognitionService:
    def __init__(self):
        # Load only essential OpenCV classifiers
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.eye_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye.xml')
        print("✅ Optimized Face Recognition Service initialized")
    
    def base64_to_image(self, base64_string: str) -> np.ndarray:
        """Convert base64 string to OpenCV image with memory optimization"""
        try:
            # Remove data URL prefix if present
            if ',' in base64_string:
                base64_string = base64_string.split(',')[1]
            
            # Decode base64
            image_data = base64.b64decode(base64_string)
            nparr = np.frombuffer(image_data, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # Resize large images immediately to save memory
            if image.shape[0] > 800 or image.shape[1] > 800:
                scale = min(800 / image.shape[0], 800 / image.shape[1])
                new_width = int(image.shape[1] * scale)
                new_height = int(image.shape[0] * scale)
                image = cv2.resize(image, (new_width, new_height))
                print(f"🔍 Resized image to: {image.shape}")
            
            return image
        except Exception as e:
            raise ValueError(f"Invalid base64 image data: {str(e)}")
    
    def detect_faces(self, image: np.ndarray) -> list:
        """Memory-optimized face detection"""
        print(f"🔍 Detecting faces in image: {image.shape}")
        
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply histogram equalization for better detection
        gray = cv2.equalizeHist(gray)
        
        # Detect faces with optimized parameters
        faces = self.face_cascade.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=3,
            minSize=(30, 30),
            flags=cv2.CASCADE_SCALE_IMAGE
        )
        
        print(f"🔍 Detected {len(faces)} faces")
        
        face_data = []
        for i, (x, y, w, h) in enumerate(faces):
            face_info = self._create_face_info(image, x, y, w, h, f"face_{i}")
            if face_info:
                face_data.append(face_info)
        
        return face_data
    
    def _create_face_info(self, image: np.ndarray, x: int, y: int, w: int, h: int, face_id_prefix: str) -> dict:
        """Create face information with basic landmarks"""
        try:
            # Ensure coordinates are within bounds
            x = max(0, min(x, image.shape[1] - w))
            y = max(0, min(y, image.shape[0] - h))
            w = min(w, image.shape[1] - x)
            h = min(h, image.shape[0] - y)
            
            if w <= 0 or h <= 0:
                return None
            
            # Extract face region for eye detection
            face_roi = image[y:y+h, x:x+w]
            gray_roi = cv2.cvtColor(face_roi, cv2.COLOR_BGR2GRAY)
            
            # Detect eyes with minimal processing
            eyes = self.eye_cascade.detectMultiScale(
                gray_roi,
                scaleFactor=1.1,
                minNeighbors=2,
                minSize=(max(5, w//20), max(5, h//20))
            )
            
            # Calculate basic landmarks
            eye_landmarks = []
            for (ex, ey, ew, eh) in eyes:
                eye_center_x = int(x + ex + ew // 2)
                eye_center_y = int(y + ey + eh // 2)
                eye_landmarks.append([eye_center_x, eye_center_y])
            
            # Estimate facial features
            nose_x = int(x + w // 2)
            nose_y = int(y + h // 2)
            mouth_x = int(x + w // 2)
            mouth_y = int(y + h * 0.7)
            
            # Calculate confidence based on face size and eye detection
            confidence = min(0.9, 0.5 + (w * h) / (image.shape[0] * image.shape[1]) * 2)
            if len(eye_landmarks) >= 2:
                confidence += 0.2
            
            return {
                "face_id": f"{face_id_prefix}_{uuid.uuid4().hex[:8]}",
                "bounding_box": [int(x), int(y), int(w), int(h)],
                "confidence": min(0.95, confidence),
                "landmarks": {
                    "left_eye": [int(eye_landmarks[0][0]), int(eye_landmarks[0][1])] if len(eye_landmarks) > 0 else [int(nose_x - 20), int(nose_y - 10)],
                    "right_eye": [int(eye_landmarks[1][0]), int(eye_landmarks[1][1])] if len(eye_landmarks) > 1 else [int(nose_x + 20), int(nose_y - 10)],
                    "nose": [int(nose_x), int(nose_y)],
                    "mouth_left": [int(mouth_x - 15), int(mouth_y)],
                    "mouth_right": [int(mouth_x + 15), int(mouth_y)]
                }
            }
        except Exception as e:
            print(f"Error creating face info: {e}")
            return None
    
    def extract_face_vector(self, image: np.ndarray, face_box: list) -> np.ndarray:
        """Extract simple face vector for recognition"""
        try:
            x, y, w, h = face_box
            
            # Extract face region
            face_roi = image[y:y+h, x:x+w]
            
            # Convert to grayscale
            gray_face = cv2.cvtColor(face_roi, cv2.COLOR_BGR2GRAY)
            
            # Resize to standard size
            resized_face = cv2.resize(gray_face, (64, 64))
            
            # Apply histogram equalization
            equalized_face = cv2.equalizeHist(resized_face)
            
            # Extract simple LBP features (memory efficient)
            lbp_features = self._extract_simple_lbp(equalized_face)
            
            # Normalize
            normalized_features = lbp_features / (np.linalg.norm(lbp_features) + 1e-8)
            
            print(f"✅ Extracted face vector: {len(normalized_features)} dimensions")
            return normalized_features
            
        except Exception as e:
            print(f"❌ Error extracting face vector: {e}")
            return None
    
    def _extract_simple_lbp(self, image: np.ndarray) -> np.ndarray:
        """Extract simple LBP features"""
        try:
            # Simple LBP implementation
            rows, cols = image.shape
            lbp = np.zeros_like(image)
            
            for i in range(1, rows-1):
                for j in range(1, cols-1):
                    center = image[i, j]
                    code = 0
                    code |= (image[i-1, j-1] >= center) << 7
                    code |= (image[i-1, j] >= center) << 6
                    code |= (image[i-1, j+1] >= center) << 5
                    code |= (image[i, j+1] >= center) << 4
                    code |= (image[i+1, j+1] >= center) << 3
                    code |= (image[i+1, j] >= center) << 2
                    code |= (image[i+1, j-1] >= center) << 1
                    code |= (image[i, j-1] >= center) << 0
                    lbp[i, j] = code
            
            # Create histogram
            hist, _ = np.histogram(lbp.ravel(), bins=256, range=(0, 256))
            return hist.astype(np.float32)
            
        except Exception as e:
            print(f"Error extracting LBP: {e}")
            return np.zeros(256, dtype=np.float32)
    
    def compare_face_vectors(self, vector1: np.ndarray, vector2: np.ndarray) -> float:
        """Compare face vectors using cosine similarity"""
        try:
            # Ensure vectors are same length
            min_length = min(len(vector1), len(vector2))
            vector1 = vector1[:min_length]
            vector2 = vector2[:min_length]
            
            # Calculate cosine similarity
            dot_product = np.dot(vector1, vector2)
            norm1 = np.linalg.norm(vector1)
            norm2 = np.linalg.norm(vector2)
            
            if norm1 == 0 or norm2 == 0:
                return 0.0
            
            similarity = dot_product / (norm1 * norm2)
            # Convert to 0-1 range
            similarity = (similarity + 1) / 2
            return float(similarity)
            
        except Exception as e:
            print(f"Error comparing vectors: {e}")
            return 0.0
    
    def register_face(self, image: np.ndarray, person_name: str, relationship: str, additional_info: str) -> dict:
        """Register a new face"""
        try:
            print(f"🔍 Registering face for: {person_name}")
            
            # Detect faces
            faces = self.detect_faces(image)
            
            if not faces:
                return {
                    "success": False,
                    "error": "No faces detected in the image"
                }
            
            # Use the first detected face
            face_info = faces[0]
            face_id = face_info["face_id"]
            print(f"✅ Face detected: {face_info['bounding_box']}")
            
            # Extract face vector
            face_vector = self.extract_face_vector(image, face_info["bounding_box"])
            
            if face_vector is None:
                return {
                    "success": False,
                    "error": "Failed to extract face vector"
                }
            
            # Store in database
            db = next(get_db())
            try:
                db_face = create_face(
                    db=db,
                    person_name=person_name,
                    relationship=relationship,
                    additional_info=additional_info,
                    bounding_box=json.dumps(face_info["bounding_box"]),
                    landmarks=json.dumps(face_info["landmarks"]),
                    face_vector=json.dumps(face_vector.tolist()),
                    image_data=base64.b64encode(cv2.imencode('.jpg', image)[1]).decode('utf-8')
                )
                
                print(f"✅ Face registered: {db_face.id}")
                return {
                    "success": True,
                    "face_id": str(db_face.id),
                    "person_name": person_name,
                    "relationship": relationship,
                    "message": f"Face registered successfully for {person_name}"
                }
            finally:
                db.close()
            
        except Exception as e:
            print(f"❌ Error registering face: {e}")
            return {
                "success": False,
                "error": f"Error registering face: {str(e)}"
            }
    
    def recognize_faces(self, image: np.ndarray, tolerance: float = 0.6) -> dict:
        """Recognize faces in image"""
        try:
            print(f"🔍 Recognizing faces with tolerance: {tolerance}")
            
            # Detect faces
            faces = self.detect_faces(image)
            
            if not faces:
                return {
                    "success": True,
                    "results": []
                }
            
            # Get registered faces
            db = next(get_db())
            try:
                registered_faces = get_all_faces(db)
                print(f"🔍 Found {len(registered_faces)} registered faces")
                
                recognized_faces = []
                
                for face_info in faces:
                    # Extract face vector
                    face_vector = self.extract_face_vector(image, face_info["bounding_box"])
                    
                    if face_vector is None:
                        continue
                    
                    best_match = None
                    best_confidence = 0.0
                    
                    # Compare with registered faces
                    for registered_face in registered_faces:
                        if registered_face.face_vector:
                            try:
                                stored_vector = np.array(json.loads(registered_face.face_vector))
                                similarity = self.compare_face_vectors(face_vector, stored_vector)
                                
                                if similarity > best_confidence and similarity >= tolerance:
                                    best_confidence = similarity
                                    best_match = registered_face
                            except Exception as e:
                                print(f"Error comparing: {e}")
                                continue
                    
                    if best_match:
                        recognized_face = {
                            "face_id": str(best_match.id),
                            "person_name": best_match.person_name,
                            "relationship": best_match.relationship or "Unknown",
                            "additional_info": best_match.additional_info,
                            "confidence": best_confidence,
                            "face_location": face_info["bounding_box"],
                            "landmarks": face_info["landmarks"]
                        }
                    else:
                        recognized_face = {
                            "face_id": face_info["face_id"],
                            "person_name": "Unknown",
                            "relationship": "Unknown",
                            "additional_info": None,
                            "confidence": best_confidence,
                            "face_location": face_info["bounding_box"],
                            "landmarks": face_info["landmarks"]
                        }
                    
                    recognized_faces.append(recognized_face)
                
                return {
                    "success": True,
                    "results": recognized_faces
                }
                
            finally:
                db.close()
            
        except Exception as e:
            print(f"❌ Error recognizing faces: {e}")
            return {
                "success": False,
                "error": f"Error recognizing faces: {str(e)}"
            }
    
    def get_face_landmarks(self, image: np.ndarray) -> dict:
        """Get face landmarks for visualization"""
        try:
            faces = self.detect_faces(image)
            return {
                "success": True,
                "landmarks": faces
            }
        except Exception as e:
            return {
                "success": False,
                "error": f"Error getting landmarks: {str(e)}"
            }

# Initialize service
face_service = OptimizedFaceRecognitionService()

# API Routes
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "service": "face_recognition",
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/face/register', methods=['POST'])
def register_face():
    """Register a new face"""
    try:
        data = request.get_json()
        if not data or 'imageData' not in data or 'personName' not in data:
            return jsonify({
                "success": False,
                "error": "imageData and personName are required"
            }), 400
        
        # Convert base64 to image
        image = face_service.base64_to_image(data['imageData'])
        
        # Register face
        result = face_service.register_face(
            image=image,
            person_name=data['personName'],
            relationship=data.get('relationship', 'Unknown'),
            additional_info=data.get('additionalInfo', '')
        )
        
        if result['success']:
            return jsonify(result), 201
        else:
            return jsonify(result), 400
        
    except Exception as e:
        print(f"❌ Error in register_face endpoint: {e}")
        return jsonify({
            "success": False,
            "error": f"Error registering face: {str(e)}"
        }), 500

@app.route('/face/recognize', methods=['POST'])
def recognize_faces():
    """Recognize faces in image"""
    try:
        data = request.get_json()
        if not data or 'imageData' not in data:
            return jsonify({
                "success": False,
                "error": "imageData is required"
            }), 400
        
        # Convert base64 to image
        image = face_service.base64_to_image(data['imageData'])
        
        # Recognize faces
        tolerance = data.get('tolerance', 0.6)
        result = face_service.recognize_faces(image, tolerance)
        
        return jsonify(result)
        
    except Exception as e:
        print(f"❌ Error in recognize_faces endpoint: {e}")
        return jsonify({
            "success": False,
            "error": f"Error recognizing faces: {str(e)}"
        }), 500

@app.route('/face/landmarks', methods=['POST'])
def get_face_landmarks():
    """Get face landmarks"""
    try:
        data = request.get_json()
        if not data or 'imageData' not in data:
            return jsonify({
                "success": False,
                "error": "imageData is required"
            }), 400
        
        # Convert base64 to image
        image = face_service.base64_to_image(data['imageData'])
        
        # Get landmarks
        result = face_service.get_face_landmarks(image)
        
        return jsonify(result)
        
    except Exception as e:
        print(f"❌ Error in get_face_landmarks endpoint: {e}")
        return jsonify({
            "success": False,
            "error": f"Error getting landmarks: {str(e)}"
        }), 500

@app.route('/face/registered', methods=['GET'])
def get_registered_faces():
    """Get all registered faces"""
    try:
        db = next(get_db())
        try:
            faces = get_all_faces(db)
            faces_list = []
            for face in faces:
                face_info = {
                    "face_id": str(face.id),
                    "person_name": face.person_name,
                    "relationship": face.relationship,
                    "additional_info": face.additional_info,
                    "has_vector": bool(face.face_vector),
                    "vector_size": len(json.loads(face.face_vector)) if face.face_vector else 0,
                    "created_at": face.created_at.isoformat() if face.created_at else None,
                    "registered_at": face.created_at.isoformat() if face.created_at else None
                }
                faces_list.append(face_info)
            
            return jsonify({
                "success": True,
                "faces": faces_list
            })
        finally:
            db.close()
    except Exception as e:
        print(f"❌ Error getting registered faces: {e}")
        return jsonify({
            "success": False,
            "error": f"Error getting registered faces: {str(e)}"
        }), 500

@app.route('/face/clear-all', methods=['DELETE'])
def clear_all_faces():
    """Clear all registered faces"""
    try:
        db = next(get_db())
        try:
            delete_all_faces(db)
            return jsonify({
                "success": True,
                "message": "All faces cleared successfully"
            })
        finally:
            db.close()
    except Exception as e:
        print(f"❌ Error clearing faces: {e}")
        return jsonify({
            "success": False,
            "error": f"Error clearing faces: {str(e)}"
        }), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)


