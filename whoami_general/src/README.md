# WhoAmI-General (Non-family) — Data + Code (NumPy)

This package gives you **data and code** for a *general* spaced-retrieval + speech-load personalization engine.
You can plug it into any memory-training or cognition-support app (no family face embeddings included).

## What’s inside
- `data/synthetic_speech.csv` — 60 days of synthetic speech features + cognitive load target.
- `data/items.csv` — 16 generic memory items with difficulty labels.
- `src/model_speech_numpy.py` — NumPy ridge regression to estimate cognitive load and banding.
- `src/scheduler_qlearning_numpy.py` — Tabular Q-learning spaced-retrieval scheduler.
- `src/train_and_simulate.py` — End-to-end demo: train speech model, simulate sessions, export report CSV.
- `src/utils.py` — helpers (binning, banding, io).
- `run_demo.sh` — quick run helper (optional).

## Quick start

```bash
# (In a regular Python 3.9+ environment)
pip install numpy pandas matplotlib

# Run the end-to-end simulation
python src/train_and_simulate.py
```

### Outputs
- `outputs/clinician_report_general.csv` — session-level metrics.
- `outputs/fig_accuracy.png`, `outputs/fig_latency.png`, `outputs/fig_true_vs_pred.png` — figures for slides.

## How it works
1. **Speech Load Model**: Linear ridge regression learns to map speech features → cognitive-load score (0–5).
2. **Banding**: load → `{low, moderate, high}` to adapt difficulty and intervals.
3. **Spaced-Retrieval RL**: Q-learning chooses next interval from `(30, 60, 120, 240) (sec)` using state = (difficulty, success_streak, latency_bin, load_band).
4. **Rewards**: +1 for correct, small bonus for faster responses, small penalty if wrong.

## Integrations
- Replace `synthetic_speech.csv` with your app’s real speech features.
- Replace `items.csv` with your item bank (IDs + difficulty).
- Move the `Scheduler` and `SpeechModel` classes into your backend (Flask/FastAPI) routes.

## License
Use freely for hackathon/demo and research prototyping. No warranties.
