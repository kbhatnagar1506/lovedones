import cv2
import numpy as np
import json
import os
import base64
from typing import List, Dict, Optional, Tuple
import pickle
from datetime import datetime

class SimpleFaceDetectionService:
    def __init__(self, data_dir: str = "data/faces"):
        self.data_dir = data_dir
        self.known_faces = {}
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        
        # Create data directory if it doesn't exist
        os.makedirs(data_dir, exist_ok=True)
        
        # Load existing face data
        self.load_face_data()
    
    def register_face(self, image_data: str, person_name: str, relationship: str, 
                     additional_info: str = "") -> Dict:
        """
        Register a new face for detection (simplified version)
        """
        try:
            # Decode base64 image
            image_bytes = base64.b64decode(image_data)
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # Convert to grayscale for face detection
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Detect faces
            faces = self.face_cascade.detectMultiScale(gray, 1.1, 4)
            
            if len(faces) == 0:
                return {
                    "success": False,
                    "error": "No face detected in the image"
                }
            
            if len(faces) > 1:
                return {
                    "success": False,
                    "error": "Multiple faces detected. Please use an image with only one face"
                }
            
            # Get the first (and only) face
            (x, y, w, h) = faces[0]
            
            # Extract face region
            face_region = gray[y:y+h, x:x+w]
            
            # Resize face to standard size for comparison
            face_resized = cv2.resize(face_region, (100, 100))
            
            # Store face data
            face_id = f"{person_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            self.known_faces[face_id] = {
                "name": person_name,
                "relationship": relationship,
                "additional_info": additional_info,
                "face_data": face_resized.tolist(),
                "face_location": [int(y), int(x+w), int(y+h), int(x)],  # top, right, bottom, left
                "registered_at": datetime.now().isoformat()
            }
            
            # Save face data
            self.save_face_data()
            
            return {
                "success": True,
                "face_id": face_id,
                "person_name": person_name,
                "relationship": relationship,
                "landmarks": {},  # Simplified - no landmarks for now
                "message": f"Successfully registered {person_name} as {relationship}"
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": f"Error registering face: {str(e)}"
            }
    
    def recognize_face(self, image_data: str, tolerance: float = 0.6) -> Dict:
        """
        Recognize faces in the given image (simplified version)
        """
        try:
            # Decode base64 image
            image_bytes = base64.b64decode(image_data)
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # Convert to grayscale
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Detect faces
            faces = self.face_cascade.detectMultiScale(gray, 1.1, 4)
            
            if len(faces) == 0:
                return {
                    "success": False,
                    "error": "No face detected in the image"
                }
            
            results = []
            for (x, y, w, h) in faces:
                # Extract face region
                face_region = gray[y:y+h, x:x+w]
                face_resized = cv2.resize(face_region, (100, 100))
                
                # Compare with known faces
                best_match = None
                best_similarity = 0
                
                for face_id, face_data in self.known_faces.items():
                    known_face = np.array(face_data["face_data"])
                    similarity = self.calculate_similarity(face_resized, known_face)
                    
                    if similarity > best_similarity and similarity > tolerance:
                        best_similarity = similarity
                        best_match = face_data
                
                if best_match:
                    results.append({
                        "face_id": face_id,
                        "person_name": best_match["name"],
                        "relationship": best_match["relationship"],
                        "additional_info": best_match["additional_info"],
                        "confidence": best_similarity,
                        "landmarks": {},  # Simplified - no landmarks
                        "face_location": [int(y), int(x+w), int(y+h), int(x)]
                    })
                else:
                    results.append({
                        "person_name": "Unknown",
                        "relationship": "Unknown",
                        "confidence": 0,
                        "landmarks": {},
                        "face_location": [int(y), int(x+w), int(y+h), int(x)]
                    })
            
            return {
                "success": True,
                "faces_detected": len(faces),
                "results": results
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": f"Error recognizing face: {str(e)}"
            }
    
    def get_face_landmarks(self, image_data: str) -> Dict:
        """
        Get face landmarks for visualization (simplified version)
        """
        try:
            # Decode base64 image
            image_bytes = base64.b64decode(image_data)
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # Convert to grayscale
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Detect faces
            faces = self.face_cascade.detectMultiScale(gray, 1.1, 4)
            
            if len(faces) == 0:
                return {
                    "success": False,
                    "error": "No face detected in the image"
                }
            
            # Create simple landmark data (just face corners)
            landmarks_data = []
            for i, (x, y, w, h) in enumerate(faces):
                # Create simple landmarks at face corners
                landmarks = {
                    "chin": [[x, y+h], [x+w, y+h]],  # Bottom corners
                    "left_eye": [[x, y]],  # Top-left
                    "right_eye": [[x+w, y]],  # Top-right
                    "nose": [[x+w//2, y+h//2]],  # Center
                    "left_eyebrow": [[x, y+h//4]],  # Left side
                    "right_eyebrow": [[x+w, y+h//4]]  # Right side
                }
                
                landmarks_data.append({
                    "face_index": i,
                    "face_location": [int(y), int(x+w), int(y+h), int(x)],
                    "landmarks": landmarks
                })
            
            return {
                "success": True,
                "faces_detected": len(faces),
                "landmarks": landmarks_data
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": f"Error getting face landmarks: {str(e)}"
            }
    
    def get_registered_faces(self) -> Dict:
        """
        Get list of all registered faces
        """
        faces_list = []
        for face_id, face_data in self.known_faces.items():
            faces_list.append({
                "face_id": face_id,
                "person_name": face_data["name"],
                "relationship": face_data["relationship"],
                "additional_info": face_data["additional_info"],
                "registered_at": face_data["registered_at"]
            })
        
        return {
            "success": True,
            "faces": faces_list,
            "total_faces": len(faces_list)
        }
    
    def delete_face(self, face_id: str) -> Dict:
        """
        Delete a registered face
        """
        try:
            if face_id not in self.known_faces:
                return {
                    "success": False,
                    "error": "Face not found"
                }
            
            # Remove from known faces
            del self.known_faces[face_id]
            
            # Save updated data
            self.save_face_data()
            
            return {
                "success": True,
                "message": f"Face {face_id} deleted successfully"
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": f"Error deleting face: {str(e)}"
            }
    
    def calculate_similarity(self, face1: np.ndarray, face2: np.ndarray) -> float:
        """
        Calculate similarity between two face images using template matching
        """
        try:
            # Normalize the images
            face1_norm = cv2.normalize(face1, None, 0, 255, cv2.NORM_MINMAX)
            face2_norm = cv2.normalize(face2, None, 0, 255, cv2.NORM_MINMAX)
            
            # Calculate correlation coefficient
            result = cv2.matchTemplate(face1_norm, face2_norm, cv2.TM_CCOEFF_NORMED)
            _, max_val, _, _ = cv2.minMaxLoc(result)
            
            return float(max_val)
        except:
            return 0.0
    
    def save_face_data(self):
        """Save face data to disk"""
        try:
            # Save face metadata
            with open(os.path.join(self.data_dir, "faces_metadata.json"), "w") as f:
                json.dump(self.known_faces, f, indent=2)
                
        except Exception as e:
            print(f"Error saving face data: {e}")
    
    def load_face_data(self):
        """Load face data from disk"""
        try:
            # Load face metadata
            metadata_path = os.path.join(self.data_dir, "faces_metadata.json")
            if os.path.exists(metadata_path):
                with open(metadata_path, "r") as f:
                    self.known_faces = json.load(f)
                    
        except Exception as e:
            print(f"Error loading face data: {e}")

# Global instance
face_service = SimpleFaceDetectionService()


