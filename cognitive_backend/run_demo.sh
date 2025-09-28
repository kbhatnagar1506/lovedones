#!/bin/bash

echo "🚀 Starting LovedOnes Cognitive Assessment Demo"
echo "=============================================="

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi

# Install requirements
echo "📦 Installing requirements..."
pip3 install -r requirements.txt

# Create necessary directories
mkdir -p outputs
mkdir -p data

# Run training and simulation
echo "🧠 Training models and running simulation..."
python3 src/train_and_simulate.py

echo ""
echo "✅ Demo complete! Check the outputs/ directory for results."
echo ""
echo "To start the API server:"
echo "  python3 src/api.py"
echo ""
echo "API will be available at: http://localhost:5000"


