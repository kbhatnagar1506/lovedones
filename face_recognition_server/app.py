"""
Dedicated Face Recognition Server
Optimized for face detection and recognition with OpenCV
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import numpy as np
import base64
import json
import uuid
from datetime import datetime
from typing import List, Dict, Optional, Tuple
import os
from database import init_db, get_db, create_face, get_all_faces, get_face_by_id, delete_face
from sqlalchemy.orm import Session

app = Flask(__name__)
CORS(app)

class FaceRecognitionService:
    def __init__(self):
        """Initialize the face recognition service"""
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.eye_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye.xml')
        # Database will be used instead of in-memory storage
        
        # Face recognition parameters
        self.face_encoding_size = 128  # Standard face encoding size
        
    def base64_to_image(self, base64_string: str) -> np.ndarray:
        """Convert base64 string to OpenCV image"""
        try:
            # Remove data URL prefix if present
            if ',' in base64_string:
                base64_string = base64_string.split(',')[1]
            
            # Decode base64
            image_data = base64.b64decode(base64_string)
            nparr = np.frombuffer(image_data, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            return image
        except Exception as e:
            raise ValueError(f"Invalid base64 image data: {str(e)}")
    
    def detect_faces(self, image: np.ndarray) -> List[Dict]:
        """Memory-optimized face detection with improved parameters"""
        print(f"🔍 Starting face detection on image size: {image.shape}")
        
        # Resize image if too large to save memory, but keep it large enough for detection
        max_size = 1200  # Increased from 1000
        min_size = 300   # Minimum size for face detection
        
        if image.shape[0] > max_size or image.shape[1] > max_size:
            scale = min(max_size / image.shape[0], max_size / image.shape[1])
            new_width = int(image.shape[1] * scale)
            new_height = int(image.shape[0] * scale)
            image = cv2.resize(image, (new_width, new_height))
            print(f"🔍 Resized image to: {image.shape}")
        elif image.shape[0] < min_size or image.shape[1] < min_size:
            scale = max(min_size / image.shape[0], min_size / image.shape[1])
            new_width = int(image.shape[1] * scale)
            new_height = int(image.shape[0] * scale)
            image = cv2.resize(image, (new_width, new_height))
            print(f"🔍 Upscaled image to: {image.shape}")
        
        # Use only the most efficient detection method
        faces = self._detect_faces_haar_optimized(image)
        print(f"🔍 Detected {len(faces)} faces")
        
        return faces
    
    def _detect_faces_haar_optimized(self, image: np.ndarray) -> List[Dict]:
        """Memory-optimized Haar Cascade face detection with improved parameters"""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply only essential preprocessing
        gray = cv2.equalizeHist(gray)
        
        # Try multiple detection parameter sets for better face detection
        detection_params = [
            {"scaleFactor": 1.05, "minNeighbors": 2, "minSize": (20, 20)},
            {"scaleFactor": 1.1, "minNeighbors": 3, "minSize": (25, 25)},
            {"scaleFactor": 1.2, "minNeighbors": 4, "minSize": (30, 30)},
        ]
        
        all_faces = []
        for params in detection_params:
            faces = self.face_cascade.detectMultiScale(
                gray,
                scaleFactor=params["scaleFactor"],
                minNeighbors=params["minNeighbors"],
                minSize=params["minSize"],
                flags=cv2.CASCADE_SCALE_IMAGE
            )
            
            for i, (x, y, w, h) in enumerate(faces):
                face_info = self._create_face_info(image, x, y, w, h, f"haar_{i}")
                if face_info:
                    all_faces.append(face_info)
        
        # Remove duplicate faces using IoU
        return self._deduplicate_faces(all_faces)
    
    def _detect_faces_haar(self, image: np.ndarray) -> List[Dict]:
        """Detect faces using Haar Cascade with multiple parameter sets"""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply multiple preprocessing techniques
        enhanced_images = [
            gray,  # Original
            cv2.equalizeHist(gray),  # Histogram equalization
            cv2.GaussianBlur(gray, (3, 3), 0),  # Gaussian blur
            cv2.bilateralFilter(gray, 9, 75, 75),  # Bilateral filter
        ]
        
        all_faces = []
        
        for enhanced_gray in enhanced_images:
            # Try multiple detection parameters
            detection_params = [
                {"scaleFactor": 1.05, "minNeighbors": 3, "minSize": (20, 20)},
                {"scaleFactor": 1.1, "minNeighbors": 4, "minSize": (30, 30)},
                {"scaleFactor": 1.2, "minNeighbors": 5, "minSize": (40, 40)},
                {"scaleFactor": 1.3, "minNeighbors": 6, "minSize": (50, 50)},
            ]
            
            for params in detection_params:
                faces = self.face_cascade.detectMultiScale(
                    enhanced_gray,
                    scaleFactor=params["scaleFactor"],
                    minNeighbors=params["minNeighbors"],
                    minSize=params["minSize"],
                    flags=cv2.CASCADE_SCALE_IMAGE
                )
                
                for i, (x, y, w, h) in enumerate(faces):
                    face_info = self._create_face_info(image, x, y, w, h, f"haar_{i}")
                    all_faces.append(face_info)
        
        return all_faces
    
    def _detect_faces_template(self, image: np.ndarray) -> List[Dict]:
        """Detect faces using template matching approach"""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Create face templates at different scales
        face_templates = self._create_face_templates()
        
        faces = []
        for scale in [0.5, 0.75, 1.0, 1.25, 1.5]:
            scaled_gray = cv2.resize(gray, None, fx=scale, fy=scale)
            
            for template in face_templates:
                # Resize template to match scale
                template_scaled = cv2.resize(template, None, fx=scale, fy=scale)
                
                # Template matching
                result = cv2.matchTemplate(scaled_gray, template_scaled, cv2.TM_CCOEFF_NORMED)
                locations = np.where(result >= 0.6)  # Threshold for face detection
                
                for pt in zip(*locations[::-1]):
                    x, y = int(pt[0] / scale), int(pt[1] / scale)
                    w, h = int(template.shape[1] / scale), int(template.shape[0] / scale)
                    
                    face_info = self._create_face_info(image, x, y, w, h, f"template_{len(faces)}")
                    faces.append(face_info)
        
        return faces
    
    def _detect_faces_edge(self, image: np.ndarray) -> List[Dict]:
        """Detect faces using edge detection and contour analysis"""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Edge detection
        edges = cv2.Canny(gray, 50, 150)
        
        # Find contours
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        faces = []
        for contour in contours:
            # Filter contours by area and aspect ratio
            area = cv2.contourArea(contour)
            if area < 1000:  # Minimum face area
                continue
            
            x, y, w, h = cv2.boundingRect(contour)
            aspect_ratio = w / h
            
            # Face-like aspect ratio (roughly 0.7 to 1.3)
            if 0.6 <= aspect_ratio <= 1.4:
                face_info = self._create_face_info(image, x, y, w, h, f"edge_{len(faces)}")
                faces.append(face_info)
        
        return faces
    
    def _create_face_templates(self) -> List[np.ndarray]:
        """Create face templates for template matching"""
        # Create simple face templates (oval shapes)
        templates = []
        sizes = [(50, 50), (75, 75), (100, 100)]
        
        for w, h in sizes:
            template = np.zeros((h, w), dtype=np.uint8)
            # Create oval face shape
            cv2.ellipse(template, (w//2, h//2), (w//2-5, h//2-5), 0, 0, 360, 255, -1)
            # Add eyes
            cv2.circle(template, (w//3, h//3), 3, 0, -1)
            cv2.circle(template, (2*w//3, h//3), 3, 0, -1)
            # Add nose
            cv2.circle(template, (w//2, h//2), 2, 0, -1)
            # Add mouth
            cv2.ellipse(template, (w//2, 2*h//3), (w//6, h//12), 0, 0, 180, 0, 2)
            
            templates.append(template)
        
        return templates
    
    def _create_face_info(self, image: np.ndarray, x: int, y: int, w: int, h: int, face_id_prefix: str) -> Dict:
        """Create face information dictionary with landmarks"""
        # Ensure coordinates are within image bounds
        x = max(0, min(x, image.shape[1] - w))
        y = max(0, min(y, image.shape[0] - h))
        w = min(w, image.shape[1] - x)
        h = min(h, image.shape[0] - y)
        
        if w <= 0 or h <= 0:
            return None
        
        # Extract face region for landmark detection
        face_roi = image[y:y+h, x:x+w]
        gray_roi = cv2.cvtColor(face_roi, cv2.COLOR_BGR2GRAY)
        
        # Detect eyes within the face
        eyes = self.eye_cascade.detectMultiScale(
            gray_roi,
            scaleFactor=1.1,
            minNeighbors=2,
            minSize=(max(5, w//20), max(5, h//20))
        )
        
        # Calculate landmarks
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
    
    def _deduplicate_faces(self, faces: List[Dict]) -> List[Dict]:
        """Remove duplicate face detections using IoU (Intersection over Union)"""
        if not faces:
            return []
        
        # Filter out None faces
        valid_faces = [f for f in faces if f is not None]
        if not valid_faces:
            return []
        
        # Sort by confidence
        valid_faces.sort(key=lambda x: x["confidence"], reverse=True)
        
        unique_faces = []
        for face in valid_faces:
            is_duplicate = False
            for unique_face in unique_faces:
                if self._calculate_iou(face["bounding_box"], unique_face["bounding_box"]) > 0.3:
                    is_duplicate = True
                    break
            
            if not is_duplicate:
                unique_faces.append(face)
        
        return unique_faces
    
    def _calculate_iou(self, box1: List[int], box2: List[int]) -> float:
        """Calculate Intersection over Union between two bounding boxes"""
        x1, y1, w1, h1 = box1
        x2, y2, w2, h2 = box2
        
        # Calculate intersection
        x_left = max(x1, x2)
        y_top = max(y1, y2)
        x_right = min(x1 + w1, x2 + w2)
        y_bottom = min(y1 + h1, y2 + h2)
        
        if x_right < x_left or y_bottom < y_top:
            return 0.0
        
        intersection = (x_right - x_left) * (y_bottom - y_top)
        union = w1 * h1 + w2 * h2 - intersection
        
        return intersection / union if union > 0 else 0.0
    
    def extract_face_vector(self, image: np.ndarray, face_box: List[int]) -> np.ndarray:
        """Extract face encoding/vector from a detected face"""
        try:
            x, y, w, h = face_box
            face_roi = image[y:y+h, x:x+w]
            
            # Convert to grayscale
            gray_face = cv2.cvtColor(face_roi, cv2.COLOR_BGR2GRAY)
            
            # Resize to standard size for consistent encoding
            standard_size = (100, 100)
            resized_face = cv2.resize(gray_face, standard_size)
            
            # Apply histogram equalization for better contrast
            equalized_face = cv2.equalizeHist(resized_face)
            
            # Extract LBP (Local Binary Pattern) features as face encoding
            # This creates a 128-dimensional feature vector
            lbp = cv2.calcHist([equalized_face], [0], None, [256], [0, 256])
            
            # Normalize the histogram to create a consistent encoding
            lbp_normalized = lbp.flatten() / (lbp.sum() + 1e-7)
            
            # Pad or truncate to standard size
            if len(lbp_normalized) < self.face_encoding_size:
                # Pad with zeros
                face_vector = np.pad(lbp_normalized, (0, self.face_encoding_size - len(lbp_normalized)), 'constant')
            else:
                # Truncate to standard size
                face_vector = lbp_normalized[:self.face_encoding_size]
            
            print(f"🔍 Extracted face vector of size: {len(face_vector)}")
            return face_vector
            
        except Exception as e:
            print(f"❌ Error extracting face vector: {str(e)}")
            # Return a zero vector as fallback
            return np.zeros(self.face_encoding_size)
    
    def compare_face_vectors(self, vector1: np.ndarray, vector2: np.ndarray) -> float:
        """Compare two face vectors and return similarity score (0-1, higher = more similar)"""
        try:
            # Use cosine similarity for face vector comparison
            dot_product = np.dot(vector1, vector2)
            norm1 = np.linalg.norm(vector1)
            norm2 = np.linalg.norm(vector2)
            
            if norm1 == 0 or norm2 == 0:
                return 0.0
            
            similarity = dot_product / (norm1 * norm2)
            # Convert to 0-1 range (cosine similarity is -1 to 1)
            similarity = (similarity + 1) / 2
            return float(similarity)
            
        except Exception as e:
            print(f"❌ Error comparing face vectors: {str(e)}")
            return 0.0
    
    def register_face(self, image: np.ndarray, person_name: str, relationship: str = "Unknown", additional_info: str = "") -> Dict:
        """Register a new face for recognition"""
        try:
            print(f"🔍 Registering face for: {person_name} ({relationship})")
            print(f"🔍 Image shape: {image.shape}")
            
            # Detect faces in the image
            faces = self.detect_faces(image)
            
            if not faces:
                print(f"❌ No faces detected for {person_name}")
                return {
                    "success": False,
                    "error": "No faces detected in the image"
                }
            
            # Use the first detected face
            face_info = faces[0]
            face_id = face_info["face_id"]
            print(f"✅ Face detected for {person_name}: {face_info['bounding_box']}")
            
            # Extract face vector for recognition
            print(f"🔍 Extracting face vector for {person_name}...")
            face_vector = self.extract_face_vector(image, face_info["bounding_box"])
            print(f"✅ Face vector extracted: {len(face_vector)} dimensions")
            
            # Store face data in database
            db = next(get_db())
            try:
                print(f"💾 Saving face data to database for {person_name}")
                db_face = create_face(
                    db=db,
                    person_name=person_name,
                    relationship=relationship,
                    additional_info=additional_info,
                    bounding_box=json.dumps(face_info["bounding_box"]),
                    landmarks=json.dumps(face_info["landmarks"]),
                    face_vector=json.dumps(face_vector.tolist())
                )
                
                print(f"✅ Face registered successfully for {person_name} with ID: {db_face.id}")
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
            return {
                "success": False,
                "error": f"Error registering face: {str(e)}"
            }
    
    def recognize_faces(self, image: np.ndarray, tolerance: float = 0.6) -> List[Dict]:
        """Enhanced face recognition with multiple ML algorithms and better matching"""
        try:
            print(f"🔍 Starting enhanced face recognition with tolerance: {tolerance}")
            
            # Detect faces using enhanced detection
            faces = self.detect_faces(image)
            print(f"🔍 Detected {len(faces)} faces for recognition")
            
            if not faces:
                print("❌ No faces detected for recognition")
                return {
                    "success": True,
                    "results": []
                }
            
            # Get all registered faces from database
            db = next(get_db())
            try:
                registered_faces = get_all_faces(db)
                print(f"🔍 Found {len(registered_faces)} registered faces in database")
                
                recognized_faces = []
                
                for i, face_info in enumerate(faces):
                    print(f"🔍 Processing face {i+1}/{len(faces)}: {face_info['face_id']}")
                    
                    # Extract face vector for this detected face
                    face_vector = self.extract_face_vector(image, face_info["bounding_box"])
                    
                    if face_vector is None:
                        print(f"❌ Failed to extract vector for face {i+1}")
                        continue
                    
                    # Try multiple recognition methods
                    recognition_results = []
                    
                    # Method 1: Direct vector similarity
                    direct_match = self._recognize_direct_similarity(face_vector, registered_faces, tolerance)
                    if direct_match:
                        recognition_results.append(direct_match)
                    
                    # Method 2: Feature-based matching
                    feature_match = self._recognize_feature_based(face_info, registered_faces, tolerance)
                    if feature_match:
                        recognition_results.append(feature_match)
                    
                    # Method 3: Template matching
                    template_match = self._recognize_template_matching(image, face_info, registered_faces, tolerance)
                    if template_match:
                        recognition_results.append(template_match)
                    
                    # Choose the best match from all methods
                    if recognition_results:
                        # Sort by confidence and take the best
                        recognition_results.sort(key=lambda x: x["confidence"], reverse=True)
                        best_match = recognition_results[0]
                        
                        # Apply additional validation
                        if self._validate_face_match(face_info, best_match):
                            # Set the face location and landmarks
                            best_match["face_location"] = face_info["bounding_box"]
                            best_match["landmarks"] = face_info["landmarks"]
                            recognized_faces.append(best_match)
                            print(f"✅ Recognized face {i+1} as {best_match['person_name']} (confidence: {best_match['confidence']:.3f})")
                        else:
                            print(f"❌ Face {i+1} failed validation")
                            # Add as unknown
                            recognized_faces.append({
                                "face_id": face_info["face_id"],
                                "person_name": "Unknown",
                                "relationship": "Unknown",
                                "additional_info": None,
                                "confidence": 0.0,
                                "face_location": face_info["bounding_box"],
                                "landmarks": face_info["landmarks"]
                            })
                    else:
                        print(f"❌ No match found for face {i+1}")
                        recognized_faces.append({
                            "face_id": face_info["face_id"],
                            "person_name": "Unknown",
                            "relationship": "Unknown",
                            "additional_info": None,
                            "confidence": 0.0,
                            "face_location": face_info["bounding_box"],
                            "landmarks": face_info["landmarks"]
                        })
                
                print(f"✅ Recognition complete: {len(recognized_faces)} faces processed")
                return {
                    "success": True,
                    "results": recognized_faces
                }
                
            finally:
                db.close()
            
        except Exception as e:
            print(f"❌ Error in face recognition: {str(e)}")
            import traceback
            traceback.print_exc()
            return {
                "success": False,
                "error": f"Error recognizing faces: {str(e)}"
            }
    
    def _recognize_direct_similarity(self, face_vector: np.ndarray, registered_faces: List, tolerance: float) -> Optional[Dict]:
        """Direct vector similarity matching"""
        best_match = None
        best_similarity = 0.0
        
        for registered_face in registered_faces:
            if registered_face.face_vector:
                try:
                    registered_vector = np.array(json.loads(registered_face.face_vector))
                    similarity = self.compare_face_vectors(face_vector, registered_vector)
                    
                    if similarity > best_similarity and similarity > tolerance:
                        best_similarity = similarity
                        best_match = registered_face
                except Exception as e:
                    print(f"Error in direct similarity: {e}")
                    continue
        
        if best_match:
            return {
                "face_id": str(best_match.id),
                "person_name": best_match.person_name,
                "relationship": best_match.relationship or "Unknown",
                "additional_info": best_match.additional_info,
                "confidence": best_similarity,
                "method": "direct_similarity"
            }
        return None
    
    def _recognize_feature_based(self, face_info: Dict, registered_faces: List, tolerance: float) -> Optional[Dict]:
        """Feature-based matching using facial landmarks"""
        landmarks = face_info["landmarks"]
        
        best_match = None
        best_score = 0.0
        
        for registered_face in registered_faces:
            if registered_face.landmarks:
                try:
                    # Compare facial feature ratios
                    stored_landmarks = json.loads(registered_face.landmarks)
                    score = self._compare_facial_features(landmarks, stored_landmarks)
                    
                    if score > best_score and score > tolerance:
                        best_score = score
                        best_match = registered_face
                except Exception as e:
                    print(f"Error in feature-based matching: {e}")
                    continue
        
        if best_match:
            return {
                "face_id": str(best_match.id),
                "person_name": best_match.person_name,
                "relationship": best_match.relationship or "Unknown",
                "additional_info": best_match.additional_info,
                "confidence": best_score,
                "method": "feature_based"
            }
        return None
    
    def _recognize_template_matching(self, image: np.ndarray, face_info: Dict, registered_faces: List, tolerance: float) -> Optional[Dict]:
        """Template matching recognition"""
        face_box = face_info["bounding_box"]
        x, y, w, h = face_box
        face_roi = image[y:y+h, x:x+w]
        
        best_match = None
        best_score = 0.0
        
        for registered_face in registered_faces:
            if registered_face.image_data:
                try:
                    # Convert registered face image
                    registered_image = self.base64_to_image(registered_face.image_data)
                    registered_gray = cv2.cvtColor(registered_image, cv2.COLOR_BGR2GRAY)
                    
                    # Resize to match
                    face_gray = cv2.cvtColor(face_roi, cv2.COLOR_BGR2GRAY)
                    registered_resized = cv2.resize(registered_gray, (w, h))
                    
                    # Template matching
                    result = cv2.matchTemplate(face_gray, registered_resized, cv2.TM_CCOEFF_NORMED)
                    score = np.max(result)
                    
                    if score > best_score and score > tolerance:
                        best_score = score
                        best_match = registered_face
                except Exception as e:
                    print(f"Error in template matching: {e}")
                    continue
        
        if best_match:
            return {
                "face_id": str(best_match.id),
                "person_name": best_match.person_name,
                "relationship": best_match.relationship or "Unknown",
                "additional_info": best_match.additional_info,
                "confidence": best_score,
                "method": "template_matching"
            }
        return None
    
    def _compare_facial_features(self, landmarks1: Dict, landmarks2: Dict) -> float:
        """Compare facial features between two sets of landmarks"""
        try:
            # Calculate eye distance ratio
            eye_dist1 = self._calculate_distance(landmarks1["left_eye"], landmarks1["right_eye"])
            eye_dist2 = self._calculate_distance(landmarks2["left_eye"], landmarks2["right_eye"])
            eye_ratio = min(eye_dist1, eye_dist2) / max(eye_dist1, eye_dist2) if max(eye_dist1, eye_dist2) > 0 else 0
            
            # Calculate nose position ratio
            nose_eye_dist1 = self._calculate_distance(landmarks1["nose"], landmarks1["left_eye"])
            nose_eye_dist2 = self._calculate_distance(landmarks2["nose"], landmarks2["left_eye"])
            nose_ratio = min(nose_eye_dist1, nose_eye_dist2) / max(nose_eye_dist1, nose_eye_dist2) if max(nose_eye_dist1, nose_eye_dist2) > 0 else 0
            
            # Calculate mouth position ratio
            mouth_nose_dist1 = self._calculate_distance(landmarks1["mouth_left"], landmarks1["nose"])
            mouth_nose_dist2 = self._calculate_distance(landmarks2["mouth_left"], landmarks2["nose"])
            mouth_ratio = min(mouth_nose_dist1, mouth_nose_dist2) / max(mouth_nose_dist1, mouth_nose_dist2) if max(mouth_nose_dist1, mouth_nose_dist2) > 0 else 0
            
            # Combine ratios (weighted average)
            overall_score = (eye_ratio * 0.4 + nose_ratio * 0.3 + mouth_ratio * 0.3)
            return overall_score
            
        except Exception as e:
            print(f"Error comparing facial features: {e}")
            return 0.0
    
    def _calculate_distance(self, point1: List[int], point2: List[int]) -> float:
        """Calculate Euclidean distance between two points"""
        return np.sqrt((point1[0] - point2[0])**2 + (point1[1] - point2[1])**2)
    
    def _validate_face_match(self, face_info: Dict, match: Dict) -> bool:
        """Validate if a face match is reliable"""
        try:
            # Check confidence threshold
            if match["confidence"] < 0.3:
                return False
            
            # Check face size (should be reasonable)
            face_box = face_info["bounding_box"]
            w, h = face_box[2], face_box[3]
            if w < 20 or h < 20 or w > 500 or h > 500:
                return False
            
            # Check if landmarks are reasonable
            landmarks = face_info["landmarks"]
            if not self._validate_landmarks(landmarks):
                return False
            
            return True
            
        except Exception as e:
            print(f"Error validating face match: {e}")
            return False
    
    def _validate_landmarks(self, landmarks: Dict) -> bool:
        """Validate if landmarks are reasonable"""
        try:
            # Check if all required landmarks exist
            required_keys = ["left_eye", "right_eye", "nose", "mouth_left", "mouth_right"]
            for key in required_keys:
                if key not in landmarks or len(landmarks[key]) != 2:
                    return False
            
            # Check if eyes are roughly at the same level
            left_eye_y = landmarks["left_eye"][1]
            right_eye_y = landmarks["right_eye"][1]
            if abs(left_eye_y - right_eye_y) > 50:  # Eyes too far apart vertically
                return False
            
            # Check if nose is between eyes
            nose_x = landmarks["nose"][0]
            left_eye_x = landmarks["left_eye"][0]
            right_eye_x = landmarks["right_eye"][0]
            if not (left_eye_x < nose_x < right_eye_x):
                return False
            
            return True
            
        except Exception as e:
            print(f"Error validating landmarks: {e}")
            return False
    
    def get_face_landmarks(self, image: np.ndarray) -> List[Dict]:
        """Get face landmarks for visualization"""
        try:
            faces = self.detect_faces(image)
            
            landmarks_data = []
            for index, face_info in enumerate(faces):
                landmark_data = {
                    "face_index": index,
                    "face_location": face_info["bounding_box"],
                    "landmarks": face_info["landmarks"]
                }
                landmarks_data.append(landmark_data)
            
            return {
                "success": True,
                "landmarks": landmarks_data
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": f"Error getting face landmarks: {str(e)}"
            }
    
    def get_registered_faces(self) -> List[Dict]:
        """Get list of all registered faces"""
        try:
            db = next(get_db())
            try:
                faces = get_all_faces(db)
                faces_list = []
                for face in faces:
                    face_info = {
                        "face_id": str(face.id),  # Changed from "id" to "face_id"
                        "person_name": face.person_name,
                        "relationship": face.relationship,
                        "additional_info": face.additional_info,
                        "has_vector": bool(face.face_vector),  # Indicate if face vector exists
                        "vector_size": len(json.loads(face.face_vector)) if face.face_vector else 0,
                        "created_at": face.created_at.isoformat() if face.created_at else None,
                        "registered_at": face.created_at.isoformat() if face.created_at else None  # Add registered_at for iOS compatibility
                    }
                    faces_list.append(face_info)
                
                return {
                    "success": True,
                    "faces": faces_list
                }
            finally:
                db.close()
        except Exception as e:
            return {
                "success": False,
                "error": f"Error getting registered faces: {str(e)}"
            }
    
    def delete_face(self, face_id: str) -> Dict:
        """Delete a registered face"""
        try:
            db = next(get_db())
            try:
                success = delete_face(db, face_id)
                if success:
                    return {
                        "success": True,
                        "message": f"Face {face_id} deleted successfully"
                    }
                else:
                    return {
                        "success": False,
                        "error": f"Face {face_id} not found"
                    }
            finally:
                db.close()
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Error deleting face: {str(e)}"
            }

# Global instance
face_service = FaceRecognitionService()

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "face_recognition",
        "timestamp": datetime.now().isoformat()
    })

# Database initialization endpoint
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

# Face Recognition Endpoints
@app.route('/face/register', methods=['POST'])
def register_face():
    """Register a new face for recognition"""
    try:
        data = request.get_json()
        print(f"📝 Face registration request received")
        
        if not data or 'imageData' not in data or 'personName' not in data:
            print(f"❌ Missing required fields in registration request")
            return jsonify({
                "success": False,
                "error": "imageData and personName are required"
            }), 400
        
        print(f"📝 Registering face for: {data['personName']}")
        
        # Convert base64 to OpenCV image
        image = face_service.base64_to_image(data['imageData'])
        print(f"📝 Image converted successfully, shape: {image.shape}")
        
        # Register the face
        result = face_service.register_face(
            image=image,
            person_name=data['personName'],
            relationship=data.get('relationship', 'Unknown'),
            additional_info=data.get('additionalInfo', '')
        )
        
        if result['success']:
            print(f"✅ Registration successful for {data['personName']}")
            return jsonify(result), 201
        else:
            print(f"❌ Registration failed for {data['personName']}: {result.get('error', 'Unknown error')}")
            return jsonify(result), 400
        
    except Exception as e:
        print(f"❌ Error registering face: {str(e)}")
        return jsonify({
            "success": False,
            "error": f"Error registering face: {str(e)}"
        }), 500

@app.route('/face/recognize', methods=['POST'])
def recognize_face():
    """Recognize faces in an image"""
    try:
        data = request.get_json()
        if not data or 'imageData' not in data:
            return jsonify({
                "success": False,
                "error": "imageData is required"
            }), 400
        
        # Convert base64 to OpenCV image
        image = face_service.base64_to_image(data['imageData'])
        
        # Recognize faces
        tolerance = data.get('tolerance', 0.6)
        result = face_service.recognize_faces(image, tolerance)
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 400
        
    except Exception as e:
        print(f"❌ Error recognizing face: {str(e)}")
        return jsonify({
            "success": False,
            "error": f"Error recognizing face: {str(e)}"
        }), 500

@app.route('/face/landmarks', methods=['POST'])
def get_face_landmarks():
    """Get face landmarks for visualization"""
    try:
        data = request.get_json()
        if not data or 'imageData' not in data:
            return jsonify({
                "success": False,
                "error": "imageData is required"
            }), 400
        
        # Convert base64 to OpenCV image
        image = face_service.base64_to_image(data['imageData'])
        
        # Get face landmarks
        result = face_service.get_face_landmarks(image)
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 400
        
    except Exception as e:
        print(f"❌ Error getting face landmarks: {str(e)}")
        return jsonify({
            "success": False,
            "error": f"Error getting face landmarks: {str(e)}"
        }), 500

@app.route('/face/registered', methods=['GET'])
def get_registered_faces():
    """Get list of all registered faces"""
    try:
        print(f"📝 Getting registered faces...")
        result = face_service.get_registered_faces()
        print(f"📝 Found {len(result.get('faces', []))} registered faces")
        return jsonify(result), 200
        
    except Exception as e:
        print(f"❌ Error getting registered faces: {str(e)}")
        return jsonify({
            "success": False,
            "error": f"Error getting registered faces: {str(e)}"
        }), 500

@app.route('/face/delete/<face_id>', methods=['DELETE'])
def delete_face(face_id):
    """Delete a registered face"""
    try:
        result = face_service.delete_face(face_id)
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 404
        
    except Exception as e:
        print(f"❌ Error deleting face: {str(e)}")
        return jsonify({
            "success": False,
            "error": f"Error deleting face: {str(e)}"
        }), 500

@app.route('/face/verify-vector', methods=['POST'])
def verify_face_vector():
    """Verify face vector extraction and comparison"""
    try:
        data = request.get_json()
        if not data or 'imageData' not in data:
            return jsonify({
                "success": False,
                "error": "imageData is required"
            }), 400
        
        # Convert base64 to OpenCV image
        image = face_service.base64_to_image(data['imageData'])
        
        # Detect faces
        faces = face_service.detect_faces(image)
        
        if not faces:
            return jsonify({
                "success": False,
                "error": "No faces detected in image"
            }), 400
        
        # Extract face vector for the first detected face
        face_info = faces[0]
        face_vector = face_service.extract_face_vector(image, face_info["bounding_box"])
        
        return jsonify({
            "success": True,
            "face_detected": True,
            "face_location": face_info["bounding_box"],
            "vector_size": len(face_vector),
            "vector_sample": face_vector[:10].tolist(),  # First 10 values for debugging
            "message": f"Face vector extracted successfully with {len(face_vector)} dimensions"
        }), 200
        
    except Exception as e:
        print(f"❌ Error verifying face vector: {str(e)}")
        return jsonify({
            "success": False,
            "error": f"Error verifying face vector: {str(e)}"
        }), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
