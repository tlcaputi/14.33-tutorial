"""
Analysis Script 02: Difference-in-Differences Regression

Estimates two DD models using pyfixest with state and year fixed effects
and cluster-robust standard errors (clustered by state):

  Model 1 – No controls:
      log_fatal ~ post_treated | state_fips + year

  Model 2 – With controls:
      log_fatal ~ post_treated + log_pop + median_income + pct_urban
               | state_fips + year

The key treatment indicator is `post_treated` (= 1 for treated states in
post-adoption years, 0 otherwise).  The outcome is log(fatal_crashes + 1)
to handle zeros while preserving a percentage-change interpretation.

Output: analysis/output/tables/dd_results.txt
"""

import io
import os
from contextlib import redirect_stdout
from pathlib import Path

import numpy as np
import pandas as pd

try:
    import pyfixest as pf
except ImportError:
    raise ImportError("pyfixest not installed — run: pip install pyfixest")

ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

# ─── Paths ────────────────────────────────────────────────────────────────────
input_file  = ROOT / "build/output/analysis_panel.csv"
output_file = ROOT / "analysis/output/tables/dd_results.txt"

print("=" * 60)
print("SCRIPT 02: DIFFERENCE-IN-DIFFERENCES REGRESSION")
print("=" * 60)

# ─── Load data ────────────────────────────────────────────────────────────────
print(f"\nReading: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} state-year observations")

# ─── Construct the treatment indicator ────────────────────────────────────────
# post_treated = 1 for states that adopted the policy AND are in the post
# period; 0 for all other observations (never-treated, or pre-adoption).
#
# NOTE: The raw panel already contains a `treated` column that equals 1 for
# states that ever adopted the policy (regardless of year).  We need the
# *interaction* of treated × post, i.e. post_treated.
df["post_treated"] = (
    (df["policy_adopted"] == 1) & (df["year"] >= df["adoption_year"])
).astype(int)

print(f"\n  post_treated == 1: {df['post_treated'].sum():,} obs")
print(f"  post_treated == 0: {(df['post_treated'] == 0).sum():,} obs")

# ─── Construct log outcome ────────────────────────────────────────────────────
# Add 1 before logging to handle zero counts cleanly.
df["log_fatal"] = np.log(df["fatal_crashes"] + 1)

# ─── Model 1: No controls ─────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("MODEL 1: No controls")
print("  log_fatal ~ post_treated | state_fips + year")
print("-" * 60)

m1 = pf.feols(
    "log_fatal ~ post_treated | state_fips + year",
    data=df,
    vcov={"CRV1": "state_fips"},   # cluster-robust by state
)
m1.summary()

# ─── Model 2: With controls ───────────────────────────────────────────────────
print("\n" + "-" * 60)
print("MODEL 2: With controls (log_pop, median_income, pct_urban)")
print("  log_fatal ~ post_treated + log_pop + median_income + pct_urban")
print("           | state_fips + year")
print("-" * 60)

m2 = pf.feols(
    "log_fatal ~ post_treated + log_pop + median_income + pct_urban | state_fips + year",
    data=df,
    vcov={"CRV1": "state_fips"},
)
m2.summary()

# ─── Side-by-side comparison table ───────────────────────────────────────────
print("\n" + "=" * 60)
print("SIDE-BY-SIDE COMPARISON")
print("=" * 60)
pf.etable([m1, m2])

# ─── Save output ──────────────────────────────────────────────────────────────
def capture(fn):
    """Capture printed output of a callable into a string."""
    buf = io.StringIO()
    with redirect_stdout(buf):
        fn()
    return buf.getvalue()

output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, "w") as f:
    f.write("=" * 80 + "\n")
    f.write("DIFFERENCE-IN-DIFFERENCES REGRESSION RESULTS\n")
    f.write("=" * 80 + "\n\n")

    f.write("MODEL 1: No controls\n")
    f.write("  log(fatal_crashes + 1) ~ post_treated | state_fips + year\n")
    f.write("-" * 80 + "\n")
    f.write(capture(m1.summary) + "\n")

    f.write("MODEL 2: With controls\n")
    f.write("  log(fatal_crashes + 1) ~ post_treated + log_pop + median_income\n")
    f.write("                         + pct_urban | state_fips + year\n")
    f.write("-" * 80 + "\n")
    f.write(capture(m2.summary) + "\n")

    f.write("SIDE-BY-SIDE COMPARISON\n")
    f.write("-" * 80 + "\n")
    f.write(capture(lambda: pf.etable([m1, m2])) + "\n")

print(f"\nSaved: {output_file.relative_to(ROOT)}")
print("  Models estimated: 2 (no controls, with controls)")
print("  SE type: cluster-robust (CRV1) by state_fips")
print("  Outcome: log(fatal_crashes + 1)")
