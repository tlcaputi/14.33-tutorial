# 02_twfe_regression.py - Two-Way Fixed Effects regression

import pandas as pd
import numpy as np
import pyfixest as pf

# Load analysis data
analysis_data = pd.read_parquet(BUILD / "output" / "analysis_data.parquet")

# Build formula with available controls
# Policy controls are always present (created in build script)
controls = ['alr', 'zero_tolerance', 'primary_seatbelt', 'secondary_seatbelt',
            'mlda21', 'gdl', 'speed_70', 'aggravated_dui']
if 'unemployment' in analysis_data.columns:
    controls.append('unemployment')
if 'income' in analysis_data.columns:
    controls.append('income')

control_str = ' + '.join(controls) if controls else ''

# TWFE regression: Hit-and-run
if control_str:
    hr_formula = f'ln_hr ~ treated + {control_str} | state_fips + year'
else:
    hr_formula = 'ln_hr ~ treated | state_fips + year'

print(f"  Running: {hr_formula}")
hr_results = pf.feols(hr_formula, data=analysis_data, vcov={'CRV1': 'state_fips'})

# TWFE regression: Non-hit-and-run (placebo)
if control_str:
    nhr_formula = f'ln_nhr ~ treated + {control_str} | state_fips + year'
else:
    nhr_formula = 'ln_nhr ~ treated | state_fips + year'

print(f"  Running: {nhr_formula}")
nhr_results = pf.feols(nhr_formula, data=analysis_data, vcov={'CRV1': 'state_fips'})

# Save results
results_summary = pd.DataFrame({
    'outcome': ['Hit-Run', 'Non-Hit-Run'],
    'coefficient': [hr_results.coef()['treated'], nhr_results.coef()['treated']],
    'std_error': [hr_results.se()['treated'], nhr_results.se()['treated']],
    'pvalue': [hr_results.pvalue()['treated'], nhr_results.pvalue()['treated']],
    'n_obs': [hr_results._N, nhr_results._N],
    'r2': [hr_results._adj_r2, nhr_results._adj_r2]
})

results_summary.to_csv(ANALYSIS / "output" / "tables" / "twfe_results.csv", index=False)

# Print results
hr_coef = hr_results.coef()['treated']
hr_se = hr_results.se()['treated']
hr_pval = hr_results.pvalue()['treated']
nhr_coef = nhr_results.coef()['treated']
nhr_se = nhr_results.se()['treated']
nhr_pval = nhr_results.pvalue()['treated']

print("\n  TWFE Results:")
print("  " + "="*60)
print(f"  {'':20} {'Coefficient':>12} {'Std Error':>12} {'p-value':>10}")
print("  " + "-"*60)
print(f"  {'Hit-Run:':20} {hr_coef:12.4f} {hr_se:12.4f} {hr_pval:10.4f}")
print(f"  {'Non-Hit-Run:':20} {nhr_coef:12.4f} {nhr_se:12.4f} {nhr_pval:10.4f}")
print("  " + "="*60)

# Store results for other scripts
TWFE_HR_RESULTS = hr_results
TWFE_NHR_RESULTS = nhr_results
