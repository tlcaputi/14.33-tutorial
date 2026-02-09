# 02_twfe_regression.py - Two-Way Fixed Effects regression

import pandas as pd
import numpy as np
from linearmodels.panel import PanelOLS

# Load analysis data
analysis_data = pd.read_parquet(BUILD / "output" / "analysis_data.parquet")

# Set up panel structure
panel_data = analysis_data.set_index(['state_fips', 'year'])

# Build formula with available controls
# Policy controls are always present (created in build script)
controls = ['alr', 'zero_tolerance', 'primary_seatbelt', 'secondary_seatbelt',
            'mlda21', 'gdl', 'speed_70', 'aggravated_dui']
if 'unemployment' in analysis_data.columns:
    controls.append('unemployment')
if 'income' in analysis_data.columns:
    controls.append('income')

control_str = ' + '.join(controls) if controls else ''
formula_hr = f'ln_hr ~ treated{" + " + control_str if control_str else ""} + EntityEffects + TimeEffects'
formula_nhr = f'ln_nhr ~ treated{" + " + control_str if control_str else ""} + EntityEffects + TimeEffects'

# TWFE regression: Hit-and-run
print(f"  Running: {formula_hr}")
hr_model = PanelOLS.from_formula(formula_hr, data=panel_data, drop_absorbed=True)
hr_results = hr_model.fit(cov_type='clustered', cluster_entity=True)

# TWFE regression: Non-hit-and-run (placebo)
print(f"  Running: {formula_nhr}")
nhr_model = PanelOLS.from_formula(formula_nhr, data=panel_data, drop_absorbed=True)
nhr_results = nhr_model.fit(cov_type='clustered', cluster_entity=True)

# Save results
results_summary = pd.DataFrame({
    'coefficient': [hr_results.params['treated'], nhr_results.params['treated']],
    'std_error': [hr_results.std_errors['treated'], nhr_results.std_errors['treated']],
    'pvalue': [hr_results.pvalues['treated'], nhr_results.pvalues['treated']],
    'n_obs': [hr_results.nobs, nhr_results.nobs],
    'r2': [hr_results.rsquared, nhr_results.rsquared]
}, index=['Hit-Run', 'Non-Hit-Run'])

results_summary.to_csv(ANALYSIS / "output" / "tables" / "twfe_results.csv")

# Print results
print("\n  TWFE Results:")
print("  " + "="*60)
print(f"  {'':20} {'Coefficient':>12} {'Std Error':>12} {'p-value':>10}")
print("  " + "-"*60)
print(f"  {'Hit-Run:':20} {hr_results.params['treated']:12.4f} {hr_results.std_errors['treated']:12.4f} {hr_results.pvalues['treated']:10.4f}")
print(f"  {'Non-Hit-Run:':20} {nhr_results.params['treated']:12.4f} {nhr_results.std_errors['treated']:12.4f} {nhr_results.pvalues['treated']:10.4f}")
print("  " + "="*60)

# Store results for other scripts
TWFE_HR_RESULTS = hr_results
TWFE_NHR_RESULTS = nhr_results
