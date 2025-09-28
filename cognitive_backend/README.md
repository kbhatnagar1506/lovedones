# 🧠 LovedOnes Cognitive Assessment Backend

AI-powered cognitive assessment system for memory lane quizzes and cognitive load monitoring using speech biomarkers and Q-learning spaced retrieval.

## 🚀 Features

- **Speech Biomarker Analysis**: NumPy-based ridge regression model for cognitive load assessment
- **Memory Lane Quizzes**: Picture-based memory tests with adaptive difficulty
- **Q-Learning Scheduler**: Intelligent spaced retrieval for optimal memory review intervals
- **Real-time Analytics**: Comprehensive performance tracking and insights
- **REST API**: Flask-based API for iOS app integration
- **Clinician Reports**: Detailed analytics and recommendations for healthcare providers

## 📁 Project Structure

```
cognitive_backend/
├── data/
│   ├── synthetic_speech.csv      # Speech features training data
│   └── memory_items.csv          # Memory items for quizzes
├── src/
│   ├── speech_model.py           # Speech biomarker model
│   ├── qlearning_scheduler.py    # Q-learning spaced retrieval
│   ├── memory_quiz.py            # Memory quiz system
│   ├── api.py                    # Flask REST API
│   └── train_and_simulate.py    # Training and simulation script
├── outputs/                      # Generated models and reports
├── requirements.txt              # Python dependencies
├── run_demo.sh                   # Quick start script
└── README.md                     # This file
```

## 🛠️ Installation

### Prerequisites

- Python 3.8 or higher
- pip (Python package installer)

### Quick Start

1. **Clone and navigate to the backend directory:**
   ```bash
   cd cognitive_backend
   ```

2. **Run the demo script:**
   ```bash
   chmod +x run_demo.sh
   ./run_demo.sh
   ```

   This will:
   - Install required dependencies
   - Train the speech biomarker model
   - Run Q-learning simulation
   - Generate analytics dashboard
   - Create clinician reports

3. **Start the API server:**
   ```bash
   python3 src/api.py
   ```

   The API will be available at `http://localhost:5000`

### Manual Installation

1. **Install dependencies:**
   ```bash
   pip3 install -r requirements.txt
   ```

2. **Train models and run simulation:**
   ```bash
   python3 src/train_and_simulate.py
   ```

3. **Start the API server:**
   ```bash
   python3 src/api.py
   ```

## 🧠 Models Overview

### Speech Biomarker Model

Uses ridge regression to predict cognitive load from speech features:

- **Features**: WPM, pause rate, type-token ratio, jitter, articulation rate
- **Output**: Cognitive load band (low/moderate/high)
- **Training**: NumPy-based normal equation solver
- **Performance**: R² > 0.8 on synthetic data

### Q-Learning Scheduler

Tabular Q-learning for optimal spaced retrieval intervals:

- **State Space**: (difficulty, success_streak, latency_bin, load_band)
- **Actions**: Review intervals (30s, 1min, 2min, 4min)
- **Reward Function**: Accuracy + speed bonuses + difficulty adjustments
- **Safety Constraints**: Prevents over-challenging high-load situations

### Memory Quiz System

Adaptive quiz system with multiple question types:

- **Question Types**: Recognition, recall, temporal, context-based
- **Difficulty Levels**: Easy, medium, hard, mixed
- **Adaptive Features**: Dynamic difficulty based on performance
- **Analytics**: Real-time performance tracking and insights

## 📊 API Endpoints

### Health Check
```
GET /health
```

### Speech Analysis
```
POST /speech/analyze
{
  "features": {
    "wpm": 145.2,
    "pause_rate": 0.12,
    "ttr": 0.78,
    "jitter": 0.15,
    "articulation_rate": 2.1
  }
}
```

### Memory Quiz
```
POST /memory/quiz/create
{
  "user_id": "user123",
  "difficulty_level": "mixed",
  "n_questions": 8
}

POST /memory/quiz/submit
{
  "session_id": "session_id",
  "question_id": "question_id",
  "selected_option_id": "option_id",
  "response_time_ms": 3500
}

POST /memory/quiz/complete
{
  "session_id": "session_id"
}
```

### Scheduler
```
POST /scheduler/next_interval
{
  "item_id": 1,
  "difficulty": 2,
  "load_band": "moderate"
}

POST /scheduler/record_result
{
  "item_id": 1,
  "correct": true,
  "latency_sec": 3.2,
  "difficulty": 2,
  "load_band": "moderate"
}
```

## 📈 Generated Outputs

After running the training script, you'll find:

- **`cognitive_analytics_dashboard.png`**: Comprehensive analytics visualization
- **`clinician_report_detailed.csv`**: Session-by-session performance data
- **`clinician_summary.json`**: Aggregated metrics and recommendations
- **`speech_model.json`**: Trained speech biomarker model
- **`qlearning_model.json`**: Trained Q-learning scheduler
- **`session_results.csv`**: Simulation results and trends

## 🔧 Configuration

### Speech Model Parameters

```python
# In speech_model.py
lambda_reg = 0.01  # Ridge regularization parameter
```

### Q-Learning Parameters

```python
# In qlearning_scheduler.py
learning_rate = 0.1      # Q-learning learning rate
discount_factor = 0.9    # Future reward discount
epsilon = 0.1           # Exploration rate
```

### API Configuration

```python
# In api.py
apiBaseURL = "http://localhost:5000"  # Change for production
```

## 📱 iOS Integration

The iOS app integrates with this backend through the `CognitiveAssessmentManager` class:

```swift
// Start a memory quiz
assessmentManager.startMemoryQuiz(difficulty: .mixed, questionCount: 8)

// Analyze speech features
let assessment = try await assessmentManager.analyzeSpeechFeatures(features)

// Get next review interval
let interval = try await assessmentManager.getNextReviewInterval(
    itemId: 1, 
    difficulty: 2, 
    loadBand: "moderate"
)
```

## 🧪 Testing

### Run Demo Quiz
```bash
python3 src/memory_quiz.py
```

### Test API Endpoints
```bash
# Health check
curl http://localhost:5000/health

# Speech analysis
curl -X POST http://localhost:5000/speech/analyze \
  -H "Content-Type: application/json" \
  -d '{"features": {"wpm": 145.2, "pause_rate": 0.12, "ttr": 0.78, "jitter": 0.15, "articulation_rate": 2.1}}'
```

## 📊 Performance Metrics

- **Speech Model**: R² > 0.8, MSE < 0.1
- **Q-Learning**: 40+ sessions simulation, accuracy improvement over time
- **Quiz System**: Adaptive difficulty, real-time analytics
- **API Response**: < 200ms average response time

## 🔮 Future Enhancements

- [ ] Replace linear model with neural network
- [ ] Add real-time speech processing
- [ ] Implement federated learning for privacy
- [ ] Add FHIR integration for healthcare workflows
- [ ] Deploy with Docker and cloud infrastructure
- [ ] Add A/B testing framework

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is part of the LovedOnes app for Alzheimer's care and family memory preservation.

## 🆘 Support

For questions or issues:
- Check the API health endpoint: `GET /health`
- Review the generated logs in the console
- Ensure all dependencies are installed correctly
- Verify the data files are in the correct locations

---

**Built with ❤️ for families affected by Alzheimer's and dementia**


