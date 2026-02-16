"""
Analysis Script 04: Instrumental Variables Regression

Estimates IV models:
1. First stage regression (instrument on endogenous variable)
2. Reduced form (outcome on instrument)
3. 2SLS using linearmodels
4. Comparison of OLS vs IV estimates
"""

import pandas as pd
import numpy as np
from pathlib import Path

try:
    import statsmodels.api as sm
    from statsmodels.formula.api import ols
except ImportError:
    print("ERROR: statsmodels not installed. Install with: pip install statsmodels")
    raise

try:
    from linearmodels.iv import IV2SLS
except ImportError:
    print("ERROR: linearmodels not installed. Install with: pip install linearmodels")
    raise

# Set project root
ROOT = Path(__file__).parent.parent.parent
print(f"Project root: {ROOT}")

# Define paths
input_file = ROOT / "analysis/code/iv_data.csv"
output_file = ROOT / "analysis/output/iv_results.txt"

print("\n" + "=" * 60)
print("INSTRUMENTAL VARIABLES REGRESSION")
print("=" * 60)

# Read IV data
print(f"\nReading data from: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} observations")

print("\nVariables:")
for col in df.columns:
    print(f"  - {col}")

print("\nSummary statistics:")
print(df.describe())

print("\n" + "-" * 60)
print("FIRST STAGE REGRESSION")
print("-" * 60)
print("Regression: class_size ~ enrollment + pct_disadvantaged")
print()

# First stage: regress endogenous variable (class_size) on instrument (enrollment)
X_first = sm.add_constant(df[['enrollment', 'pct_disadvantaged']])
y_first = df['class_size']

first_stage = sm.OLS(y_first, X_first).fit()
print(first_stage.summary())

# Calculate F-statistic for instrument
# F-stat for testing enrollment coefficient = 0
enrollment_coef = first_stage.params['enrollment']
enrollment_se = first_stage.bse['enrollment']
f_stat = (enrollment_coef / enrollment_se) ** 2

print(f"\n{'=' * 60}")
print(f"First-stage F-statistic: {f_stat:.2f}")
print(f"{'=' * 60}")

if f_stat < 10:
    print("⚠ WARNING: Weak instrument (F < 10)")
elif f_stat < 20:
    print("⚠ Instrument strength is moderate (10 < F < 20)")
else:
    print("✓ Strong instrument (F > 20)")

print("\n" + "-" * 60)
print("REDUCED FORM REGRESSION")
print("-" * 60)
print("Regression: test_score ~ enrollment + pct_disadvantaged")
print()

# Reduced form: regress outcome (test_score) on instrument (enrollment)
X_reduced = sm.add_constant(df[['enrollment', 'pct_disadvantaged']])
y_reduced = df['test_score']

reduced_form = sm.OLS(y_reduced, X_reduced).fit()
print(reduced_form.summary())

print("\n" + "-" * 60)
print("TWO-STAGE LEAST SQUARES (2SLS)")
print("-" * 60)
print("Endogenous: class_size")
print("Instrument: enrollment")
print("Controls: pct_disadvantaged")
print()

# 2SLS using linearmodels
# Dependent variable
dependent = df['test_score']

# Exogenous variables (controls)
exog = sm.add_constant(df[['pct_disadvantaged']])

# Endogenous variables
endog = df[['class_size']]

# Instruments
instruments = df[['enrollment']]

# Estimate 2SLS
iv_model = IV2SLS(dependent, exog, endog, instruments)
iv_results = iv_model.fit(cov_type='unadjusted')

print(iv_results.summary)

print("\n" + "-" * 60)
print("OLS FOR COMPARISON")
print("-" * 60)
print("Regression: test_score ~ class_size + pct_disadvantaged")
print()

# OLS for comparison
X_ols = sm.add_constant(df[['class_size', 'pct_disadvantaged']])
y_ols = df['test_score']

ols_model = sm.OLS(y_ols, X_ols).fit()
print(ols_model.summary())

print("\n" + "=" * 60)
print("COMPARISON: OLS vs IV")
print("=" * 60)

# Extract coefficients
ols_coef = ols_model.params['class_size']
ols_se = ols_model.bse['class_size']

iv_coef = iv_results.params['class_size']
iv_se = iv_results.std_errors['class_size']

print(f"\nEffect of class_size on test_score:")
print(f"  OLS:  {ols_coef:>8.4f}  (SE: {ols_se:>6.4f})")
print(f"  IV:   {iv_coef:>8.4f}  (SE: {iv_se:>6.4f})")
print(f"  Difference: {iv_coef - ols_coef:>8.4f}")

if abs(iv_coef) > abs(ols_coef):
    print(f"\n✓ IV estimate is larger in magnitude than OLS")
    print(f"  This suggests class_size is endogenous and OLS is biased toward zero")
else:
    print(f"\n✓ OLS estimate is larger in magnitude than IV")

# Save output
print(f"\nSaving to: {output_file.relative_to(ROOT)}")
output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, 'w') as f:
    f.write("=" * 80 + "\n")
    f.write("INSTRUMENTAL VARIABLES REGRESSION RESULTS\n")
    f.write("=" * 80 + "\n\n")

    f.write("FIRST STAGE REGRESSION\n")
    f.write("-" * 80 + "\n")
    f.write(first_stage.summary().as_text() + "\n\n")
    f.write(f"First-stage F-statistic: {f_stat:.2f}\n\n")

    f.write("REDUCED FORM REGRESSION\n")
    f.write("-" * 80 + "\n")
    f.write(reduced_form.summary().as_text() + "\n\n")

    f.write("TWO-STAGE LEAST SQUARES (2SLS)\n")
    f.write("-" * 80 + "\n")
    f.write(str(iv_results.summary) + "\n\n")

    f.write("OLS FOR COMPARISON\n")
    f.write("-" * 80 + "\n")
    f.write(ols_model.summary().as_text() + "\n\n")

    f.write("COMPARISON: OLS vs IV\n")
    f.write("=" * 80 + "\n")
    f.write(f"Effect of class_size on test_score:\n")
    f.write(f"  OLS:  {ols_coef:>8.4f}  (SE: {ols_se:>6.4f})\n")
    f.write(f"  IV:   {iv_coef:>8.4f}  (SE: {iv_se:>6.4f})\n")
    f.write(f"  Difference: {iv_coef - ols_coef:>8.4f}\n")

print(f"✓ Saved IV regression results")
print(f"✓ First-stage F-statistic: {f_stat:.2f}")
print(f"✓ Estimated OLS and IV models")
