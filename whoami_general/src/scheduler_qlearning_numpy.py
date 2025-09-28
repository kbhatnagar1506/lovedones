
import numpy as np
from .utils import band_id, latency_bin

class SRSchedulerQL:
    """Tabular Q-learning spaced-retrieval scheduler."""
    def __init__(self, alpha=0.2, gamma=0.9, eps=0.2):
        self.alpha = alpha
        self.gamma = gamma
        self.eps = eps
        self.intervals = np.array([30, 60, 120, 240])  # seconds
        self.A = len(self.intervals)
        self.Q = np.zeros((3, 4, 3, 3, self.A))  # diff, streak(0..3), latbin(0..2), band(0..2), actions

    def choose_action(self, d, s, l, b):
        if np.random.rand() < self.eps:
            return np.random.randint(self.A)
        return int(np.argmax(self.Q[d,s,l,b,:]))

    def update(self, d, s, l, b, a, r, d2, s2, l2, b2):
        best_next = np.max(self.Q[d2, s2, l2, b2, :])
        old = self.Q[d,s,l,b,a]
        self.Q[d,s,l,b,a] = (1-self.alpha)*old + self.alpha*(r + self.gamma*best_next)

    def step_env(self, difficulty, interval, load_band_lbl):
        # Simulates recall & latency
        base = 0.55 + 0.15*np.log1p(interval/30)
        base -= 0.15*difficulty
        base -= 0.12*band_id(load_band_lbl)
        p_correct = float(np.clip(base, 0.05, 0.95))
        correct = np.random.rand() < p_correct
        mu = 2.5 + 1.0*difficulty + 0.8*band_id(load_band_lbl) + (0.8 if not correct else 0.0)
        latency = max(0.5, np.random.normal(mu, 0.8))
        return int(correct), float(latency)

    def reward(self, correct, latency):
        return (1.0 if correct else -0.3) + max(0.0, (3.5 - latency)) * 0.1
