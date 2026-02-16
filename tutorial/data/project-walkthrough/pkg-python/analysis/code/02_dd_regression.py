"""
Analysis Script 02: Difference-in-Differences Regression

Estimates DD models using pyfixest:
1. Main DD regression with state and year fixed effects
2. Subgroup analysis by region
3. Alternative outcome (serious crashes)
"""

import pandas as pd
import numpy as np
from pathlib import Path

try:
    import pyfixest as pf
except ImportError:
    print("ERROR: pyfixest not installed. Install with: pip install pyfixest")
    raise

# Set project root
ROOT = Path(__file__).parent.parent.parent
print(f"Project root: {ROOT}")

# Define paths
input_file = ROOT / "build/output/analysis_panel.csv"
output_file = ROOT / "analysis/output/dd_regression_table.txt"

print("\n" + "=" * 60)
print("DIFFERENCE-IN-DIFFERENCES REGRESSION")
print("=" * 60)

# Read analysis panel
print(f"\nReading data from: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} observations")

# Create log outcome
df['log_fatal_crashes'] = np.log(df['fatal_crashes'] + 1)
df['log_serious_crashes'] = np.log(df['serious_crashes'] + 1)

print("\n" + "-" * 60)
print("MODEL 1: MAIN DD REGRESSION")
print("-" * 60)

# Main DD regression: log fatal crashes on treated with state and year FE
mod1 = pf.feols(
    "log_fatal_crashes ~ treated | state_fips + year",
    data=df,
    vcov={'CRV1': 'state_fips'}
)

print(mod1.summary())

print("\n" + "-" * 60)
print("MODEL 2: DD WITH CONTROLS")
print("-" * 60)

# DD with controls
mod2 = pf.feols(
    "log_fatal_crashes ~ treated + log_pop + median_income + pct_urban | state_fips + year",
    data=df,
    vcov={'CRV1': 'state_fips'}
)

print(mod2.summary())

print("\n" + "-" * 60)
print("MODEL 3: SUBGROUP ANALYSIS BY REGION")
print("-" * 60)

# Subgroup analysis by region
regions = df['region'].unique()
print(f"\nRegions: {', '.join(sorted(regions))}\n")

region_results = []
for region in sorted(regions):
    print(f"Region: {region}")
    df_region = df[df['region'] == region]

    mod_region = pf.feols(
        "log_fatal_crashes ~ treated | state_fips + year",
        data=df_region,
        vcov={'CRV1': 'state_fips'}
    )

    # Extract coefficient and se
    coef = mod_region.coef().values[0]
    se = mod_region.se().values[0]
    pval = mod_region.pvalue().values[0]
    n_obs = mod_region._N

    print(f"  Coefficient: {coef:>8.4f}  SE: {se:>6.4f}  p-value: {pval:>6.4f}  N: {n_obs:>6,}")

    region_results.append({
        'region': region,
        'coefficient': coef,
        'se': se,
        'pvalue': pval,
        'n_obs': n_obs
    })

print("\n" + "-" * 60)
print("MODEL 4: ALTERNATIVE OUTCOME (SERIOUS CRASHES)")
print("-" * 60)

# Alternative outcome
mod4 = pf.feols(
    "log_serious_crashes ~ treated + log_pop + median_income + pct_urban | state_fips + year",
    data=df,
    vcov={'CRV1': 'state_fips'}
)

print(mod4.summary())

print("\n" + "=" * 60)
print("REGRESSION TABLE")
print("=" * 60)

# Create regression table
table = pf.etable([mod1, mod2, mod4])
print(table)

# Save output
print(f"\nSaving to: {output_file.relative_to(ROOT)}")
output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, 'w') as f:
    f.write("=" * 80 + "\n")
    f.write("DIFFERENCE-IN-DIFFERENCES REGRESSION RESULTS\n")
    f.write("=" * 80 + "\n\n")

    f.write("MODEL 1: Main DD Regression\n")
    f.write("-" * 80 + "\n")
    f.write(mod1.summary().__str__() + "\n\n")

    f.write("MODEL 2: DD with Controls\n")
    f.write("-" * 80 + "\n")
    f.write(mod2.summary().__str__() + "\n\n")

    f.write("MODEL 3: Subgroup Analysis by Region\n")
    f.write("-" * 80 + "\n")
    for result in region_results:
        f.write(f"{result['region']:20s} {result['coefficient']:>8.4f} ({result['se']:>6.4f})  "
                f"p={result['pvalue']:>6.4f}  N={result['n_obs']:>6,}\n")
    f.write("\n")

    f.write("MODEL 4: Alternative Outcome (Serious Crashes)\n")
    f.write("-" * 80 + "\n")
    f.write(mod4.summary().__str__() + "\n\n")

    f.write("REGRESSION TABLE\n")
    f.write("=" * 80 + "\n")
    f.write(str(table) + "\n")

print(f"✓ Saved regression results")
print(f"✓ Models: 4 (Main DD, DD with controls, Subgroup, Alternative outcome)")
