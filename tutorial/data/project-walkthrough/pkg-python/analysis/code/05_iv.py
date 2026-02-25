"""
Analysis Script 05: Instrumental Variables Regression

Motivating context:
  We want to estimate the causal effect of class size on student test scores.
  The problem: schools with more disadvantaged students may both have larger
  classes AND lower test scores (confounding).  Simply regressing test_score
  on class_size gives a biased OLS estimate.

  The instrument here is school enrollment.  Enrollment affects class size
  (first stage), but conditional on the percent of disadvantaged students,
  enrollment itself shouldn't directly affect test scores (exclusion
  restriction).  This is a simplified version of Angrist & Lavy (1999).

Steps:
  1. First stage — regress class_size on enrollment + pct_disadvantaged
  2. Reduced form — regress test_score on enrollment + pct_disadvantaged
  3. OLS — naive (biased) estimate of class_size effect
  4. 2SLS — IV estimate using enrollment as instrument for class_size
  5. Compare OLS vs IV and interpret the difference

Data: analysis/code/iv_data.csv
  - school_id, enrollment, class_size, test_score, pct_disadvantaged

Output: analysis/output/tables/iv_results.txt
        analysis/output/tables/iv_results.tex
"""

import io
import os
from contextlib import redirect_stdout
from pathlib import Path

import pandas as pd

try:
    import pyfixest as pf
except ImportError:
    raise ImportError("pyfixest not installed — run: pip install pyfixest")

ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

# ─── Paths ────────────────────────────────────────────────────────────────────
input_file  = ROOT / "analysis/code/iv_data.csv"
output_file = ROOT / "analysis/output/tables/iv_results.txt"
output_tex  = ROOT / "analysis/output/tables/iv_results.tex"

print("=" * 60)
print("SCRIPT 05: INSTRUMENTAL VARIABLES REGRESSION")
print("=" * 60)

# ─── Load data ────────────────────────────────────────────────────────────────
print(f"\nReading: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} schools")
print("\nVariables:")
for col in df.columns:
    print(f"  {col}: mean={df[col].mean():.2f}, sd={df[col].std():.2f}")

# ─── Step 1: First stage ──────────────────────────────────────────────────────
# Does enrollment predict class size?  We expect larger schools to have
# larger classes on average (a mechanical relationship).
print("\n" + "-" * 60)
print("STEP 1: FIRST STAGE")
print("  class_size ~ enrollment + pct_disadvantaged")
print("  (Does the instrument predict the endogenous variable?)")
print("-" * 60)

first_stage = pf.feols(
    "class_size ~ enrollment + pct_disadvantaged",
    data=df,
    vcov="hetero",   # heteroskedasticity-robust SEs (no clustering — cross-sectional)
)
first_stage.summary()

# Compute first-stage F-statistic for the instrument
enrollment_coef = first_stage.coef()["enrollment"]
enrollment_se   = first_stage.se()["enrollment"]
f_stat = (enrollment_coef / enrollment_se) ** 2

print(f"\n  First-stage F-statistic on instrument: {f_stat:.2f}")
if f_stat >= 20:
    print("  Strong instrument (F >= 20)")
elif f_stat >= 10:
    print("  Adequate instrument (10 <= F < 20)")
else:
    print("  WARNING: Weak instrument (F < 10) — IV estimates may be unreliable")

# ─── Step 2: Reduced form ─────────────────────────────────────────────────────
# Does the instrument affect the outcome?  If enrollment affects test scores,
# and enrollment only matters through class size, this is indirect evidence
# that class size matters.
print("\n" + "-" * 60)
print("STEP 2: REDUCED FORM")
print("  test_score ~ enrollment + pct_disadvantaged")
print("  (Does the instrument affect the outcome?)")
print("-" * 60)

reduced_form = pf.feols(
    "test_score ~ enrollment + pct_disadvantaged",
    data=df,
    vcov="hetero",
)
reduced_form.summary()

# ─── Step 3: OLS (biased) ─────────────────────────────────────────────────────
# OLS ignores the endogeneity of class_size.  If higher-ability students sort
# into smaller classes, OLS overstates the benefit of smaller classes (or
# understates the harm of larger classes).
print("\n" + "-" * 60)
print("STEP 3: OLS (LIKELY BIASED)")
print("  test_score ~ class_size + pct_disadvantaged")
print("  (class_size is endogenous — OLS estimate is not causal)")
print("-" * 60)

ols_model = pf.feols(
    "test_score ~ class_size + pct_disadvantaged",
    data=df,
    vcov="hetero",
)
ols_model.summary()

# ─── Step 4: 2SLS ─────────────────────────────────────────────────────────────
# pyfixest IV syntax: "y ~ exog_controls | FE | endog ~ instrument"
# Here we have no fixed effects (use 0), controls = pct_disadvantaged,
# endogenous = class_size, instrument = enrollment.
print("\n" + "-" * 60)
print("STEP 4: TWO-STAGE LEAST SQUARES (2SLS)")
print("  test_score ~ pct_disadvantaged | 0 | class_size ~ enrollment")
print("  (enrollment instruments for class_size)")
print("-" * 60)

iv_model = pf.feols(
    "test_score ~ pct_disadvantaged | 0 | class_size ~ enrollment",
    data=df,
    vcov="hetero",
)
iv_model.summary()

# ─── Step 5: OLS vs IV comparison ─────────────────────────────────────────────
ols_coef = ols_model.coef()["class_size"]
ols_se   = ols_model.se()["class_size"]

iv_coef  = iv_model.coef()["class_size"]
iv_se    = iv_model.se()["class_size"]

print("\n" + "=" * 60)
print("COMPARISON: OLS vs IV (effect of class_size on test_score)")
print("=" * 60)
print(f"  OLS:  coef = {ols_coef:>8.4f}  (SE = {ols_se:.4f})")
print(f"  2SLS: coef = {iv_coef:>8.4f}  (SE = {iv_se:.4f})")
print(f"  Difference (IV - OLS): {iv_coef - ols_coef:.4f}")
print()
if abs(iv_coef) > abs(ols_coef):
    print("  The IV estimate is larger in magnitude than OLS.")
    print("  This is consistent with attenuation bias (measurement error in")
    print("  class_size) or negative selection (better students in smaller classes).")
else:
    print("  The OLS estimate is larger in magnitude than IV.")
    print("  This is consistent with positive selection into small classes")
    print("  (high-ability students attending schools with smaller classes).")

# ─── Save output ──────────────────────────────────────────────────────────────
def capture(fn):
    buf = io.StringIO()
    with redirect_stdout(buf):
        fn()
    return buf.getvalue()

output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, "w") as f:
    f.write("=" * 80 + "\n")
    f.write("INSTRUMENTAL VARIABLES REGRESSION RESULTS\n")
    f.write("=" * 80 + "\n\n")

    f.write("STEP 1: FIRST STAGE\n")
    f.write("  class_size ~ enrollment + pct_disadvantaged\n")
    f.write("-" * 80 + "\n")
    f.write(capture(first_stage.summary))
    f.write(f"\nFirst-stage F-statistic on instrument: {f_stat:.2f}\n\n")

    f.write("STEP 2: REDUCED FORM\n")
    f.write("  test_score ~ enrollment + pct_disadvantaged\n")
    f.write("-" * 80 + "\n")
    f.write(capture(reduced_form.summary) + "\n")

    f.write("STEP 3: OLS (BIASED)\n")
    f.write("  test_score ~ class_size + pct_disadvantaged\n")
    f.write("-" * 80 + "\n")
    f.write(capture(ols_model.summary) + "\n")

    f.write("STEP 4: TWO-STAGE LEAST SQUARES\n")
    f.write("  test_score ~ pct_disadvantaged | 0 | class_size ~ enrollment\n")
    f.write("-" * 80 + "\n")
    f.write(capture(iv_model.summary) + "\n")

    f.write("COMPARISON: OLS vs IV\n")
    f.write("-" * 80 + "\n")
    f.write(f"  OLS:  coef = {ols_coef:>8.4f}  (SE = {ols_se:.4f})\n")
    f.write(f"  2SLS: coef = {iv_coef:>8.4f}  (SE = {iv_se:.4f})\n")
    f.write(f"  Difference (IV - OLS): {iv_coef - ols_coef:.4f}\n")
    f.write(f"  First-stage F-statistic: {f_stat:.2f}\n")

# ─── Save LaTeX output ──────────────────────────────────────────────────────
tex = pf.etable([first_stage, reduced_form, ols_model, iv_model], type="tex", labels={
    "enrollment": "Enrollment",
    "pct_disadvantaged": "Pct.\\ Disadvantaged",
    "class_size": "Class Size",
    "test_score": "Test Score",
})
with open(output_tex, "w") as f:
    f.write(tex + "\n")

print(f"\nSaved: {output_file.relative_to(ROOT)}")
print(f"Saved: {output_tex.relative_to(ROOT)}")
print(f"  First-stage F-stat: {f_stat:.2f}")
print(f"  OLS estimate:  {ols_coef:.4f}  (SE {ols_se:.4f})")
print(f"  IV estimate:   {iv_coef:.4f}  (SE {iv_se:.4f})")
