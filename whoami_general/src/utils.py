
import numpy as np
import pandas as pd

def band_from_score(x: float) -> str:
    if x < 1.5: return "low"
    if x < 3.0: return "moderate"
    return "high"

def band_id(lbl: str) -> int:
    return {"low":0, "moderate":1, "high":2}[lbl]

def latency_bin(lat: float) -> int:
    if lat < 3: return 0
    if lat < 6: return 1
    return 2

def save_csv(df: pd.DataFrame, path):
    df.to_csv(path, index=False)
