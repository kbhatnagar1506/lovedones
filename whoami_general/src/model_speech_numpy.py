
import numpy as np
import pandas as pd
from .utils import band_from_score

class SpeechLoadModel:
    """NumPy ridge regression for cognitive-load estimation."""
    def __init__(self, lam: float = 1e-2):
        self.lam = lam
        self.beta = None
        self.cols = None

    def fit(self, df: pd.DataFrame):
        # expects columns: wpm, pause_rate, ttr, jitter, artic_rate; target: cog_load_true
        X = df[["wpm","pause_rate","ttr","jitter","artic_rate"]].values
        y = df["cog_load_true"].values
        n = X.shape[0]
        X_ = np.column_stack([np.ones(n), X])
        I = np.eye(X_.shape[1]); I[0,0] = 0
        self.beta = np.linalg.inv(X_.T @ X_ + self.lam * I) @ X_.T @ y
        self.cols = ["intercept","wpm","pause_rate","ttr","jitter","artic_rate"]
        return self

    def predict(self, df: pd.DataFrame) -> np.ndarray:
        X = df[["wpm","pause_rate","ttr","jitter","artic_rate"]].values
        n = X.shape[0]
        X_ = np.column_stack([np.ones(n), X])
        yhat = X_ @ self.beta
        return np.clip(yhat, 0, 5)

    def band(self, score: float) -> str:
        return band_from_score(score)

    def coef(self):
        return dict(zip(self.cols, self.beta.tolist()))
