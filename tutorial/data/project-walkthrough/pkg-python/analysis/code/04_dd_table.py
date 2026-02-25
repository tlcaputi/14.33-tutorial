"""
Analysis Script 04: Multi-Column DD Table

Estimates five DD models side-by-side using pyfixest and compares them
with etable().  This is a common table structure in applied micro papers:
the first columns establish the main result, subsequent columns probe
robustness (controls, subsamples, alternative outcomes).

Models:
  m1 – Baseline: no controls
  m2 – Add time-varying controls (log_pop, median_income)
  m3 – Southern states only
  m4 – Non-Southern states only
  m5 – Alternative outcome (serious_crashes, levels)

All models use state and year fixed effects.  Models m1-m4 cluster SEs
by state; m5 also clusters by state.

Output: analysis/output/tables/dd_table.txt
        analysis/output/tables/dd_table.tex
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
output_file = ROOT / "analysis/output/tables/dd_table.txt"
output_tex  = ROOT / "analysis/output/tables/dd_table.tex"

print("=" * 60)
print("SCRIPT 04: MULTI-COLUMN DD TABLE")
print("=" * 60)

# ─── Load data ────────────────────────────────────────────────────────────────
print(f"\nReading: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} state-year observations")

# ─── Construct treatment indicator ────────────────────────────────────────────
# post_treated = 1 for states that adopted the policy AND are past adoption.
df["post_treated"] = (
    (df["policy_adopted"] == 1) & (df["year"] >= df["adoption_year"])
).astype(int)

# ─── Subsets for robustness ───────────────────────────────────────────────────
df_south     = df[df["region"] == "South"].copy()
df_non_south = df[df["region"] != "South"].copy()

print(f"\n  Full sample:      {len(df):,} obs")
print(f"  South only:       {len(df_south):,} obs")
print(f"  Non-South only:   {len(df_non_south):,} obs")

# ─── Model 1: Baseline — no controls ──────────────────────────────────────────
print("\n" + "-" * 60)
print("MODEL 1: Baseline (no controls)")
print("  fatal_crashes ~ post_treated | state_fips + year")
print("-" * 60)

m1 = pf.feols(
    "fatal_crashes ~ post_treated | state_fips + year",
    data=df,
    vcov={"CRV1": "state_fips"},
)
m1.summary()

# ─── Model 2: Add controls ────────────────────────────────────────────────────
print("\n" + "-" * 60)
print("MODEL 2: With controls (log_pop, median_income)")
print("  fatal_crashes ~ post_treated + log_pop + median_income | ...")
print("-" * 60)

m2 = pf.feols(
    "fatal_crashes ~ post_treated + log_pop + median_income | state_fips + year",
    data=df,
    vcov={"CRV1": "state_fips"},
)
m2.summary()

# ─── Model 3: South subsample ─────────────────────────────────────────────────
print("\n" + "-" * 60)
print("MODEL 3: South subsample")
print("  fatal_crashes ~ post_treated | state_fips + year  [South only]")
print("-" * 60)

m3 = pf.feols(
    "fatal_crashes ~ post_treated | state_fips + year",
    data=df_south,
    vcov={"CRV1": "state_fips"},
)
m3.summary()

# ─── Model 4: Non-South subsample ─────────────────────────────────────────────
print("\n" + "-" * 60)
print("MODEL 4: Non-South subsample")
print("  fatal_crashes ~ post_treated | state_fips + year  [Non-South only]")
print("-" * 60)

m4 = pf.feols(
    "fatal_crashes ~ post_treated | state_fips + year",
    data=df_non_south,
    vcov={"CRV1": "state_fips"},
)
m4.summary()

# ─── Model 5: Alternative outcome — serious crashes ───────────────────────────
print("\n" + "-" * 60)
print("MODEL 5: Alternative outcome (serious_crashes)")
print("  serious_crashes ~ post_treated + log_pop | state_fips + year")
print("-" * 60)

m5 = pf.feols(
    "serious_crashes ~ post_treated + log_pop | state_fips + year",
    data=df,
    vcov={"CRV1": "state_fips"},
)
m5.summary()

# ─── Side-by-side comparison ──────────────────────────────────────────────────
print("\n" + "=" * 60)
print("SIDE-BY-SIDE COMPARISON (etable)")
print("=" * 60)
pf.etable([m1, m2, m3, m4, m5])

# ─── Save output ──────────────────────────────────────────────────────────────
def capture(fn):
    buf = io.StringIO()
    with redirect_stdout(buf):
        fn()
    return buf.getvalue()

output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, "w") as f:
    f.write("=" * 80 + "\n")
    f.write("MULTI-COLUMN DIFFERENCE-IN-DIFFERENCES TABLE\n")
    f.write("=" * 80 + "\n\n")

    f.write("MODEL 1: Baseline — no controls\n")
    f.write("  fatal_crashes ~ post_treated | state_fips + year\n")
    f.write("-" * 80 + "\n")
    f.write(capture(m1.summary) + "\n")

    f.write("MODEL 2: With controls (log_pop, median_income)\n")
    f.write("  fatal_crashes ~ post_treated + log_pop + median_income | state_fips + year\n")
    f.write("-" * 80 + "\n")
    f.write(capture(m2.summary) + "\n")

    f.write("MODEL 3: South subsample\n")
    f.write("  fatal_crashes ~ post_treated | state_fips + year  [region == South]\n")
    f.write("-" * 80 + "\n")
    f.write(capture(m3.summary) + "\n")

    f.write("MODEL 4: Non-South subsample\n")
    f.write("  fatal_crashes ~ post_treated | state_fips + year  [region != South]\n")
    f.write("-" * 80 + "\n")
    f.write(capture(m4.summary) + "\n")

    f.write("MODEL 5: Alternative outcome — serious_crashes\n")
    f.write("  serious_crashes ~ post_treated + log_pop | state_fips + year\n")
    f.write("-" * 80 + "\n")
    f.write(capture(m5.summary) + "\n")

    f.write("SIDE-BY-SIDE COMPARISON\n")
    f.write("-" * 80 + "\n")
    f.write(capture(lambda: pf.etable([m1, m2, m3, m4, m5])) + "\n")

# ─── Save LaTeX output ──────────────────────────────────────────────────────
tex = pf.etable([m1, m2, m3, m4, m5], type="tex", labels={
    "post_treated": r"Treatment $\times$ Post",
    "log_pop": "log(Population)",
    "median_income": "Median Income",
    "fatal_crashes": "Fatal Crashes",
    "serious_crashes": "Serious Crashes",
})
with open(output_tex, "w") as f:
    f.write(tex + "\n")

print(f"\nSaved: {output_file.relative_to(ROOT)}")
print(f"Saved: {output_tex.relative_to(ROOT)}")
print("  Models: 5 (baseline, controls, South, Non-South, serious crashes)")
print("  SE type: cluster-robust (CRV1) by state_fips")
