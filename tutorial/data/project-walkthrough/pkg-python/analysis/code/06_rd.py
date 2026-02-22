"""
Analysis Script 06: Regression Discontinuity Design

Motivating context:
  We estimate the causal effect of legally being able to drink alcohol
  (turning 21) on mortality rate.  The running variable is days_from_21:
  negative values are days before the 21st birthday, positive values are
  days after.  The cutoff is 0.

  Because age 21 is assigned by a birthday (not by choice), individuals
  just below and just above the cutoff are nearly identical in expectation.
  This local randomization allows us to identify a causal effect.

Approach:
  - Restrict to a bandwidth of +/- 365 days (one year on each side)
  - Model 1 -- Linear RD: allow different linear slopes on each side by
    interacting days_from_21 with over_21
  - Model 2 -- Quadratic RD: add squared terms for robustness
  - RD plot: binned scatter plot with fitted regression lines on each side

Data: analysis/code/rd_data.csv
  - person_id, age_years, days_from_21, over_21, mortality_rate, male, income

Outputs:
  - analysis/output/figures/rd_plot.png
  - analysis/output/tables/rd_results.txt
"""

import io
import os
from contextlib import redirect_stdout
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

try:
    import pyfixest as pf
except ImportError:
    raise ImportError("pyfixest not installed -- run: pip install pyfixest")

ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

# --- Paths -------------------------------------------------------------------
input_file   = ROOT / "analysis/code/rd_data.csv"
output_plot  = ROOT / "analysis/output/figures/rd_plot.png"
output_file  = ROOT / "analysis/output/tables/rd_results.txt"

print("=" * 60)
print("SCRIPT 06: REGRESSION DISCONTINUITY DESIGN")
print("=" * 60)

# --- Load data ---------------------------------------------------------------
print(f"\nReading: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} observations")
print(f"\n  Running variable (days_from_21):")
print(f"    Range: {df['days_from_21'].min():.0f} to {df['days_from_21'].max():.0f}")
print(f"    Below cutoff (age < 21): {(df['days_from_21'] < 0).sum():,}")
print(f"    Above cutoff (age >= 21): {(df['over_21'] == 1).sum():,}")

# --- Bandwidth restriction ---------------------------------------------------
# Using observations far from the cutoff risks violating the local randomization
# assumption.  We limit to one year on each side of the cutoff.
bandwidth = 365   # +/- 365 days = one year on each side
df_bw = df[df["days_from_21"].abs() <= bandwidth].copy()
print(f"\n  Bandwidth: +/- {bandwidth} days")
print(f"  Observations in bandwidth: {len(df_bw):,}")

# --- Interaction terms -------------------------------------------------------
# The key to RD is allowing the slope of the running variable to differ on
# each side of the cutoff.  We do this with a simple interaction:
#
#   E[Y | X] = alpha + beta*over_21 + gamma*X + delta*(X * over_21) + controls
#
# The coefficient on over_21 (beta) is the RD estimate: the discontinuous
# jump in the outcome exactly at the cutoff.
df_bw["days_x_over21"] = df_bw["days_from_21"] * df_bw["over_21"]

# --- Model 1: Linear RD ------------------------------------------------------
print("\n" + "-" * 60)
print("MODEL 1: LINEAR RD")
print("  mortality_rate ~ over_21 + days_from_21 + days_x_over21 + male + income")
print("  Heteroskedasticity-robust SEs")
print("-" * 60)

linear_rd = pf.feols(
    "mortality_rate ~ over_21 + days_from_21 + days_x_over21 + male + income",
    data=df_bw,
    vcov="hetero",
)
linear_rd.summary()

rd_est    = linear_rd.coef()["over_21"]
rd_se     = linear_rd.se()["over_21"]
rd_pval   = linear_rd.pvalue()["over_21"]
rd_ci_lo  = rd_est - 1.96 * rd_se
rd_ci_hi  = rd_est + 1.96 * rd_se

print(f"\n  RD estimate (linear): {rd_est:.4f}")
print(f"  SE:                   {rd_se:.4f}")
print(f"  p-value:              {rd_pval:.4f}")
print(f"  95% CI:               [{rd_ci_lo:.4f}, {rd_ci_hi:.4f}]")

# --- Model 2: Quadratic RD ---------------------------------------------------
# A quadratic specification lets us check whether the linear result is robust
# to a more flexible functional form for the relationship between age and mortality.
print("\n" + "-" * 60)
print("MODEL 2: QUADRATIC RD (robustness check)")
print("  Adds days_from_21^2 and its interaction with over_21")
print("-" * 60)

df_bw["days_sq"]          = df_bw["days_from_21"] ** 2
df_bw["days_sq_x_over21"] = df_bw["days_sq"] * df_bw["over_21"]

quad_rd = pf.feols(
    "mortality_rate ~ over_21 + days_from_21 + days_x_over21 "
    "+ days_sq + days_sq_x_over21 + male + income",
    data=df_bw,
    vcov="hetero",
)
quad_rd.summary()

rd_est_q    = quad_rd.coef()["over_21"]
rd_se_q     = quad_rd.se()["over_21"]
rd_pval_q   = quad_rd.pvalue()["over_21"]
rd_ci_lo_q  = rd_est_q - 1.96 * rd_se_q
rd_ci_hi_q  = rd_est_q + 1.96 * rd_se_q

print(f"\n  RD estimate (quadratic): {rd_est_q:.4f}")
print(f"  SE:                      {rd_se_q:.4f}")
print(f"  p-value:                 {rd_pval_q:.4f}")
print(f"  95% CI:                  [{rd_ci_lo_q:.4f}, {rd_ci_hi_q:.4f}]")

# --- RD Plot -----------------------------------------------------------------
# Standard RD plot: bin the running variable into intervals, compute the mean
# outcome in each bin, then overlay the fitted regression lines from the linear
# model on each side of the cutoff.
print("\n" + "-" * 60)
print("CREATING RD PLOT")
print("-" * 60)

n_bins = 40
df_bw["bin"] = pd.cut(df_bw["days_from_21"], bins=n_bins)

bin_stats = (
    df_bw.groupby("bin", observed=True)
    .agg(
        days_from_21=("days_from_21", "mean"),
        mortality_rate=("mortality_rate", "mean"),
        over_21=("over_21", "first"),
    )
    .reset_index(drop=True)
    .dropna(subset=["days_from_21"])
)

# Build fitted lines using the linear model coefficients at mean controls
coefs       = linear_rd.coef()
mean_male   = df_bw["male"].mean()
mean_income = df_bw["income"].mean()

x_below = np.linspace(-bandwidth, 0, 200)
x_above = np.linspace(0,  bandwidth, 200)

# Below cutoff: over_21 = 0, days_x_over21 = 0
y_below = (
    coefs["Intercept"]
    + coefs["days_from_21"] * x_below
    + coefs["male"]   * mean_male
    + coefs["income"] * mean_income
)

# Above cutoff: over_21 = 1, days_x_over21 = x
y_above = (
    coefs["Intercept"]
    + coefs["over_21"]
    + coefs["days_from_21"]  * x_above
    + coefs["days_x_over21"] * x_above
    + coefs["male"]   * mean_male
    + coefs["income"] * mean_income
)

fig, ax = plt.subplots(figsize=(10, 6))

below_bins = bin_stats[bin_stats["days_from_21"] < 0]
above_bins = bin_stats[bin_stats["days_from_21"] >= 0]

ax.scatter(below_bins["days_from_21"], below_bins["mortality_rate"],
           color="steelblue", s=45, alpha=0.7, zorder=3,
           label="Below cutoff (age < 21)")
ax.scatter(above_bins["days_from_21"], above_bins["mortality_rate"],
           color="firebrick", s=45, alpha=0.7, zorder=3,
           label="Above cutoff (age >= 21)")

ax.plot(x_below, y_below, color="steelblue", linewidth=2.0, zorder=2)
ax.plot(x_above, y_above, color="firebrick",  linewidth=2.0, zorder=2)

ax.axvline(0, color="black", linestyle="--", linewidth=1.5, alpha=0.8,
           label="Cutoff (age 21)")

ax.set_xlabel("Days from 21st Birthday", fontsize=12)
ax.set_ylabel("Mortality Rate", fontsize=12)
ax.set_title("RD Plot: Effect of Turning 21 on Mortality Rate", fontsize=13, pad=14)
ax.legend(frameon=True)
ax.grid(True, alpha=0.25, linestyle="--")

plt.tight_layout()
output_plot.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(output_plot, dpi=300, bbox_inches="tight")
plt.close()
print(f"  Saved: {output_plot.relative_to(ROOT)}")

# --- Save results text -------------------------------------------------------
def capture(fn):
    buf = io.StringIO()
    with redirect_stdout(buf):
        fn()
    return buf.getvalue()

output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, "w") as f:
    f.write("=" * 80 + "\n")
    f.write("REGRESSION DISCONTINUITY DESIGN RESULTS\n")
    f.write("=" * 80 + "\n\n")

    f.write("MODEL 1: LINEAR RD\n")
    f.write("  mortality_rate ~ over_21 + days_from_21 + days_x_over21 + male + income\n")
    f.write("-" * 80 + "\n")
    f.write(capture(linear_rd.summary))
    f.write(f"\nRD estimate (linear): {rd_est:.4f}  (SE {rd_se:.4f})\n")
    f.write(f"p-value:              {rd_pval:.4f}\n")
    f.write(f"95% CI:               [{rd_ci_lo:.4f}, {rd_ci_hi:.4f}]\n\n")

    f.write("MODEL 2: QUADRATIC RD\n")
    f.write("  ... + days_sq + days_sq_x_over21\n")
    f.write("-" * 80 + "\n")
    f.write(capture(quad_rd.summary))
    f.write(f"\nRD estimate (quadratic): {rd_est_q:.4f}  (SE {rd_se_q:.4f})\n")
    f.write(f"p-value:                 {rd_pval_q:.4f}\n")
    f.write(f"95% CI:                  [{rd_ci_lo_q:.4f}, {rd_ci_hi_q:.4f}]\n")

print(f"\nSaved: {output_file.relative_to(ROOT)}")
print(f"  Linear RD estimate:    {rd_est:.4f}  (SE {rd_se:.4f}, p={rd_pval:.4f})")
print(f"  Quadratic RD estimate: {rd_est_q:.4f}  (SE {rd_se_q:.4f}, p={rd_pval_q:.4f})")
print(f"  Bandwidth: +/- {bandwidth} days")
