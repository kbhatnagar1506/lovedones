
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
from .model_speech_numpy import SpeechLoadModel
from .scheduler_qlearning_numpy import SRSchedulerQL
from .utils import band_from_score, band_id, latency_bin, save_csv

def main():
    base = Path(__file__).resolve().parents[1]
    data_dir = base / "data"
    out_dir = base / "outputs"
    out_dir.mkdir(exist_ok=True, parents=True)

    speech = pd.read_csv(data_dir / "synthetic_speech.csv")
    items = pd.read_csv(data_dir / "items.csv")

    # Train speech model (NumPy ridge)
    sm = SpeechLoadModel(lam=1e-2).fit(speech)
    speech["cog_load_pred"] = sm.predict(speech)
    speech["load_band"] = speech["cog_load_pred"].apply(band_from_score)

    # Initialize scheduler
    sched = SRSchedulerQL(alpha=0.2, gamma=0.9, eps=0.2)

    N_ITEMS = len(items)
    N_SESSIONS = 40
    item_streak = np.zeros(N_ITEMS, dtype=int)
    item_last_latency = np.random.uniform(2,6,size=N_ITEMS)

    session_acc, session_lat, session_band = [], [], []

    for s in range(N_SESSIONS):
        day = min(s, len(speech)-1)
        lb = speech.iloc[day]["load_band"]
        corrects = []
        lats = []
        for i in range(N_ITEMS):
            d = int(items.iloc[i]["difficulty"])   # 0..2
            st = min(item_streak[i], 3)
            lbid = band_id(lb)
            lbid_next = lbid

            a = sched.choose_action(d, st, latency_bin(item_last_latency[i]), lbid)
            interval = sched.intervals[a]

            correct, lat = sched.step_env(difficulty=d, interval=interval, load_band_lbl=lb)
            r = sched.reward(correct, lat)

            st_next = min(st + 1, 3) if correct else 0
            l_next = latency_bin(lat)
            sched.update(d, st, latency_bin(item_last_latency[i]), lbid, a, r, d, st_next, l_next, lbid_next)

            item_streak[i] = st_next
            item_last_latency[i] = lat
            corrects.append(int(correct))
            lats.append(float(lat))

        session_acc.append(float(np.mean(corrects)))
        session_lat.append(float(np.mean(lats)))
        session_band.append(lb)

    # Report
    report = pd.DataFrame({
        "session": np.arange(1, N_SESSIONS+1),
        "mean_recall_accuracy": session_acc,
        "mean_latency_sec": session_lat,
        "load_band": session_band
    })

    # Simple support-needed score for clinician view
    lbw = report["load_band"].map({"low":0,"moderate":1,"high":2}).values
    risk = (1.0-report["mean_recall_accuracy"]) * 0.6 + (report["mean_latency_sec"]/10.0) * 0.25 + (lbw/2.0) * 0.15
    report["support_needed_score_0to1"] = np.clip(risk, 0, 1)

    save_csv(report, out_dir / "clinician_report_general.csv")
    save_csv(speech, out_dir / "speech_model_predictions.csv")

    # Plots
    plt.figure(figsize=(8,4))
    plt.plot(report["session"], report["mean_recall_accuracy"], linewidth=2)
    plt.title("Mean Recall Accuracy per Session")
    plt.xlabel("Session"); plt.ylabel("Accuracy (0–1)"); plt.tight_layout()
    plt.savefig(out_dir / "fig_accuracy.png", dpi=150); plt.close()

    plt.figure(figsize=(8,4))
    plt.plot(report["session"], report["mean_latency_sec"], linewidth=2)
    plt.title("Mean Response Latency per Session")
    plt.xlabel("Session"); plt.ylabel("Latency (sec)"); plt.tight_layout()
    plt.savefig(out_dir / "fig_latency.png", dpi=150); plt.close()

    plt.figure(figsize=(6,5))
    plt.scatter(speech["cog_load_true"], speech["cog_load_pred"], s=18)
    plt.xlabel("True Cognitive Load (synthetic)"); plt.ylabel("Predicted Load")
    plt.title("Speech Model — True vs Predicted"); plt.tight_layout()
    plt.savefig(out_dir / "fig_true_vs_pred.png", dpi=150); plt.close()

    # Print a quick console summary
    print("Speech model coefficients:", sm.coef())
    print("Saved:", out_dir / "clinician_report_general.csv")

if __name__ == "__main__":
    main()
