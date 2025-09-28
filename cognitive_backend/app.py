"""
Main application entry point for Heroku deployment
"""

import sys
import os

# Add src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

# Import the Flask app from src/api.py
from api import app

if __name__ == "__main__":
    app.run(debug=False)


