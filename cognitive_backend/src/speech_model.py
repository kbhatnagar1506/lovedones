"""
Speech Biomarker Model for Cognitive Load Assessment
Uses NumPy-based ridge regression to predict cognitive load from speech features
"""

import numpy as np
import pandas as pd
from typing import Tuple, List, Dict
import json
import os

class SpeechBiomarkerModel:
    """
    NumPy-based speech biomarker model for cognitive load assessment
    """
    
    def __init__(self, lambda_reg: float = 0.01):
        self.lambda_reg = lambda_reg
        self.coefficients = None
        self.feature_names = ['wpm', 'pause_rate', 'ttr', 'jitter', 'articulation_rate']
        self.load_bands = {1: 'low', 2: 'moderate', 3: 'high'}
        
    def prepare_features(self, df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
        """Prepare features and target for training"""
        X = df[self.feature_names].values
        y = df['cognitive_load'].values
        
        # Add bias term
        X_with_bias = np.column_stack([np.ones(X.shape[0]), X])
        
        return X_with_bias, y
    
    def train(self, df: pd.DataFrame) -> Dict:
        """Train the ridge regression model using normal equation"""
        X, y = self.prepare_features(df)
        
        # Ridge regression: β = (X^T X + λI)^-1 X^T y
        XtX = X.T @ X
        XtX_reg = XtX + self.lambda_reg * np.eye(XtX.shape[0])
        XtX_inv = np.linalg.inv(XtX_reg)
        self.coefficients = XtX_inv @ X.T @ y
        
        # Calculate training metrics
        predictions = X @ self.coefficients
        mse = np.mean((y - predictions) ** 2)
        r2 = 1 - (np.sum((y - predictions) ** 2) / np.sum((y - np.mean(y)) ** 2))
        
        return {
            'mse': mse,
            'r2': r2,
            'coefficients': self.coefficients.tolist(),
            'feature_names': ['bias'] + self.feature_names
        }
    
    def predict_load_band(self, features: Dict[str, float]) -> str:
        """Predict cognitive load band from speech features"""
        if self.coefficients is None:
            raise ValueError("Model must be trained before making predictions")
        
        # Prepare feature vector
        feature_vector = np.array([
            1.0,  # bias term
            features.get('wpm', 0),
            features.get('pause_rate', 0),
            features.get('ttr', 0),
            features.get('jitter', 0),
            features.get('articulation_rate', 0)
        ])
        
        # Predict cognitive load
        predicted_load = feature_vector @ self.coefficients
        
        # Convert to load band
        if predicted_load <= 1.5:
            return 'low'
        elif predicted_load <= 2.5:
            return 'moderate'
        else:
            return 'high'
    
    def predict_batch(self, features_list: List[Dict[str, float]]) -> List[str]:
        """Predict load bands for multiple feature sets"""
        return [self.predict_load_band(features) for features in features_list]
    
    def save_model(self, filepath: str):
        """Save model to file"""
        model_data = {
            'coefficients': self.coefficients.tolist(),
            'feature_names': self.feature_names,
            'lambda_reg': self.lambda_reg,
            'load_bands': self.load_bands
        }
        
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            json.dump(model_data, f, indent=2)
    
    def load_model(self, filepath: str):
        """Load model from file"""
        with open(filepath, 'r') as f:
            model_data = json.load(f)
        
        self.coefficients = np.array(model_data['coefficients'])
        self.feature_names = model_data['feature_names']
        self.lambda_reg = model_data['lambda_reg']
        self.load_bands = model_data['load_bands']

def train_speech_model(data_path: str, output_path: str) -> Dict:
    """Train speech biomarker model and save results"""
    # Load data
    df = pd.read_csv(data_path)
    
    # Train model
    model = SpeechBiomarkerModel()
    metrics = model.train(df)
    
    # Save model
    model.save_model(output_path)
    
    # Generate predictions for analysis
    predictions = model.predict_batch(df[model.feature_names].to_dict('records'))
    df['predicted_load_band'] = predictions
    
    # Save predictions
    predictions_df = df[['date', 'cognitive_load', 'predicted_load_band'] + model.feature_names].copy()
    predictions_df.to_csv(output_path.replace('.json', '_predictions.csv'), index=False)
    
    return metrics

if __name__ == "__main__":
    # Train model
    metrics = train_speech_model(
        'data/synthetic_speech.csv',
        'outputs/speech_model.json'
    )
    
    print("Speech Model Training Results:")
    print(f"MSE: {metrics['mse']:.4f}")
    print(f"R²: {metrics['r2']:.4f}")
    print(f"Coefficients: {metrics['coefficients']}")
