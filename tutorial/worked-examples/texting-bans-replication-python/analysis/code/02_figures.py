# 02_figures.py — Event study plot
# =============================================================================
# Loads coefficients from CSV, adds reference period, and creates
# a publication-quality event study plot.
# =============================================================================

import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ── Load coefficients ────────────────────────────────────────
coef_df = pd.read_csv(ANALYSIS / "output" / "event_study_coefs.csv")

# Add reference period (t = -1, coefficient = 0)
ref_row = pd.DataFrame([{
    "event_time": -1,
    "coefficient": 0.0,
    "std_error": 0.0,
    "ci_lower": 0.0,
    "ci_upper": 0.0,
}])
coef_df = pd.concat([coef_df, ref_row], ignore_index=True).sort_values("event_time")

# ── Create plot ──────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(10, 6))

# Reference lines
ax.axhline(0, color="red", linestyle="--", linewidth=0.8, alpha=0.7)
ax.axvline(-0.5, color="gray", linestyle="--", linewidth=0.8, alpha=0.5)

# Point estimates with error bars
ax.errorbar(
    coef_df["event_time"],
    coef_df["coefficient"],
    yerr=[
        coef_df["coefficient"] - coef_df["ci_lower"],
        coef_df["ci_upper"] - coef_df["coefficient"],
    ],
    fmt="D",
    color="navy",
    capsize=4,
    markersize=5,
    linewidth=1.5,
    capthick=1.2,
)

ax.set_xlabel("Years Relative to Texting Ban", fontsize=12)
ax.set_ylabel("Effect on Log Fatalities", fontsize=12)
ax.set_title("Event Study: Texting Bans and Traffic Fatalities", fontsize=14)

ax.set_xticks(range(-6, 7))
ax.tick_params(labelsize=10)

# Caption
ax.annotate(
    "Coefficients relative to t = \u22121. 95% CIs shown. Clustered SEs at state level.",
    xy=(0.5, -0.12), xycoords="axes fraction",
    ha="center", fontsize=9, color="gray",
)

plt.tight_layout()
out_path = ANALYSIS / "output" / "event_study.png"
plt.savefig(out_path, dpi=300, bbox_inches="tight")
plt.close()
print(f"    Saved plot to {out_path}")
