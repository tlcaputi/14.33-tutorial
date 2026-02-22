"""
Analysis Script 03: Event Study

Tests the parallel trends assumption and traces the dynamic effect of the
policy over time by estimating a set of "event-time" dummies relative to
each state's adoption year.

Approach:
  - Compute time_to_treat = year - adoption_year for treated states
  - Bin endpoints: values < -5 are coded as -5; values > 5 are coded as +5
  - Create indicator dummies et_m5, et_m4, ..., et_m1, et_p0, ..., et_p5
  - Omit et_m1 (t = -1) as the reference period so all coefficients are
    relative to the year immediately before adoption
  - Never-treated states (policy_adopted == 0) contribute to identification
    of the year fixed effects as the comparison group

If pre-treatment coefficients (et_m5 through et_m2) are near zero, this
supports the parallel trends assumption underlying the DD design.

Output: analysis/output/figures/event_study.png
"""

import os
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

try:
    import pyfixest as pf
except ImportError:
    raise ImportError("pyfixest not installed — run: pip install pyfixest")

ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

# ─── Paths ────────────────────────────────────────────────────────────────────
input_file   = ROOT / "build/output/analysis_panel.csv"
output_plot  = ROOT / "analysis/output/figures/event_study.png"

print("=" * 60)
print("SCRIPT 03: EVENT STUDY")
print("=" * 60)

# ─── Load data ────────────────────────────────────────────────────────────────
print(f"\nReading: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} state-year observations")

# ─── Log outcome ──────────────────────────────────────────────────────────────
df["log_fatal"] = np.log(df["fatal_crashes"] + 1)

# ─── Time-to-treatment variable ───────────────────────────────────────────────
# For states that never adopted (policy_adopted == 0), adoption_year is NaN.
# Those observations serve as a control group via the year fixed effects and
# do NOT receive event-time dummies.
treated_mask = df["policy_adopted"] == 1

df["time_to_treat"] = np.where(
    treated_mask,
    df["year"] - df["adoption_year"],
    np.nan,
)

# Bin at -5 and +5 so the endpoints absorb all pre/post observations
df["event_time"] = df["time_to_treat"].copy()
df.loc[df["event_time"] < -5, "event_time"] = -5
df.loc[df["event_time"] >  5, "event_time"] =  5

event_times = list(range(-5, 6))  # -5, -4, ..., 0, ..., 5

print(f"\n  Treated states: {df.loc[treated_mask, 'state_fips'].nunique()}")
print(f"  Never-treated states: {df.loc[~treated_mask, 'state_fips'].nunique()}")
print(f"  Event-time range (binned): {min(event_times)} to {max(event_times)}")
print(f"  Reference period: t = -1 (year before adoption)")

# ─── Construct event-time dummies ─────────────────────────────────────────────
# Naming convention: et_mN for negative periods, et_pN for zero/positive.
def et_name(t):
    return f"et_m{abs(t)}" if t < 0 else f"et_p{t}"

for t in event_times:
    df[et_name(t)] = ((df["event_time"] == t) & treated_mask).astype(int)

# Exclude the reference period (t = -1) from the right-hand side
rhs_vars = [et_name(t) for t in event_times if t != -1]
formula = "log_fatal ~ " + " + ".join(rhs_vars) + " | state_fips + year"

print("\n" + "-" * 60)
print("EVENT STUDY REGRESSION")
print(f"  Formula: {formula}")
print("  SE type: cluster-robust (CRV1) by state_fips")
print("-" * 60)

mod = pf.feols(formula, data=df, vcov={"CRV1": "state_fips"})
mod.summary()

# ─── Extract coefficients ─────────────────────────────────────────────────────
# Add the reference period back as a zero row so the plot passes through zero.
rows = []
for t in event_times:
    if t == -1:
        rows.append({"t": t, "coef": 0.0, "se": 0.0})
    else:
        v = et_name(t)
        rows.append({"t": t, "coef": mod.coef()[v], "se": mod.se()[v]})

coef_df = pd.DataFrame(rows).sort_values("t").reset_index(drop=True)
coef_df["ci_lo"] = coef_df["coef"] - 1.96 * coef_df["se"]
coef_df["ci_hi"] = coef_df["coef"] + 1.96 * coef_df["se"]

print("\n" + "-" * 60)
print("EVENT STUDY COEFFICIENTS (t=-1 is reference period, coef=0)")
print("-" * 60)
print(coef_df[["t", "coef", "se", "ci_lo", "ci_hi"]].to_string(index=False))

# ─── Plot ─────────────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(10, 6))

# Shaded confidence-interval ribbon
ax.fill_between(
    coef_df["t"],
    coef_df["ci_lo"],
    coef_df["ci_hi"],
    alpha=0.20,
    color="steelblue",
    label="95% CI",
)

# Connecting line
ax.plot(coef_df["t"], coef_df["coef"], color="steelblue", linewidth=1.5, zorder=2)

# Point estimates
ax.scatter(coef_df["t"], coef_df["coef"], color="steelblue", s=50, zorder=3,
           label="Point estimate")

# Reference lines
ax.axhline(0, color="black", linewidth=0.9)
ax.axvline(-0.5, color="firebrick", linestyle="--", linewidth=1.5, alpha=0.8,
           label="Policy adoption")

ax.set_xticks(event_times)
ax.set_xlabel("Years Relative to Policy Adoption", fontsize=12)
ax.set_ylabel("Coefficient (log fatal crashes)", fontsize=12)
ax.set_title("Event Study: Dynamic Effect of Policy on Fatal Crashes",
             fontsize=13, pad=14)
ax.legend(frameon=True)
ax.grid(True, alpha=0.25, linestyle="--")

plt.tight_layout()
output_plot.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(output_plot, dpi=300, bbox_inches="tight")
plt.close()

print(f"\nSaved: {output_plot.relative_to(ROOT)}")
print("  Reference period: t = -1 (coef fixed at 0)")
print("  CI ribbon: +/- 1.96 * SE")
