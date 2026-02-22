# 03_event_study.py - Event study specification

import pandas as pd
import numpy as np
import pyfixest as pf

# Load analysis data
analysis_data = pd.read_parquet(BUILD / "output" / "analysis_data.parquet")

# Bin event time at endpoints (-5 to +10)
MIN_ET, MAX_ET = -5, 10
analysis_data['event_time_binned'] = analysis_data['event_time'].copy()
analysis_data.loc[analysis_data['event_time'] < MIN_ET, 'event_time_binned'] = MIN_ET
analysis_data.loc[analysis_data['event_time'] > MAX_ET, 'event_time_binned'] = MAX_ET

# Get unique event times (excluding -1 as reference)
event_times = sorted([et for et in analysis_data['event_time_binned'].dropna().unique() if et != -1])

# Create event time dummies with safe column names
for et in event_times:
    safe_name = f'et_m{abs(int(et))}' if et < 0 else f'et_p{int(et)}'
    analysis_data[safe_name] = (analysis_data['event_time_binned'] == et).astype(int)

# Build formula
et_cols = [f'et_m{abs(int(et))}' if et < 0 else f'et_p{int(et)}' for et in event_times]
# Policy controls are always present (created in build script)
controls = ['alr', 'zero_tolerance', 'primary_seatbelt', 'secondary_seatbelt',
            'mlda21', 'gdl', 'speed_70', 'aggravated_dui']
if 'unemployment' in analysis_data.columns:
    controls.append('unemployment')
if 'income' in analysis_data.columns:
    controls.append('income')
all_vars = et_cols + controls
formula_hr = f'ln_hr ~ {" + ".join(all_vars)} | state_fips + year'

print(f"  Running event study: ln_hr ~ event_time_dummies + FE")

# Fit model
hr_results = pf.feols(formula_hr, data=analysis_data, vcov={'CRV1': 'state_fips'})

# Extract coefficients
coefs = []
for et in event_times:
    safe_name = f'et_m{abs(int(et))}' if et < 0 else f'et_p{int(et)}'
    coefs.append({
        'event_time': et,
        'coefficient': hr_results.coef()[safe_name],
        'std_error': hr_results.se()[safe_name],
        'pvalue': hr_results.pvalue()[safe_name],
        'ci_lower': hr_results.coef()[safe_name] - 1.96 * hr_results.se()[safe_name],
        'ci_upper': hr_results.coef()[safe_name] + 1.96 * hr_results.se()[safe_name]
    })

# Add reference period
coefs.append({
    'event_time': -1,
    'coefficient': 0,
    'std_error': 0,
    'pvalue': np.nan,
    'ci_lower': 0,
    'ci_upper': 0
})

coef_df_hr = pd.DataFrame(coefs).sort_values('event_time')
coef_df_hr.to_csv(ANALYSIS / "output" / "tables" / "es_coefficients_hr.csv", index=False)

print("  Event study coefficients (Hit-Run):")
for _, row in coef_df_hr.iterrows():
    sig = '*' if (row['std_error'] > 0 and abs(row['coefficient'] / row['std_error']) > 1.96) else ''
    print(f"    t={int(row['event_time']):+3d}: {row['coefficient']:7.4f} ({row['std_error']:.4f}){sig}")

# Also run for non-hit-run
formula_nhr = f'ln_nhr ~ {" + ".join(all_vars)} | state_fips + year'
nhr_results = pf.feols(formula_nhr, data=analysis_data, vcov={'CRV1': 'state_fips'})

coefs_nhr = []
for et in event_times:
    safe_name = f'et_m{abs(int(et))}' if et < 0 else f'et_p{int(et)}'
    coefs_nhr.append({
        'event_time': et,
        'coefficient': nhr_results.coef()[safe_name],
        'std_error': nhr_results.se()[safe_name],
        'pvalue': nhr_results.pvalue()[safe_name],
        'ci_lower': nhr_results.coef()[safe_name] - 1.96 * nhr_results.se()[safe_name],
        'ci_upper': nhr_results.coef()[safe_name] + 1.96 * nhr_results.se()[safe_name]
    })

coefs_nhr.append({
    'event_time': -1,
    'coefficient': 0,
    'std_error': 0,
    'pvalue': np.nan,
    'ci_lower': 0,
    'ci_upper': 0
})

coef_df_nhr = pd.DataFrame(coefs_nhr).sort_values('event_time')
coef_df_nhr.to_csv(ANALYSIS / "output" / "tables" / "es_coefficients_nhr.csv", index=False)

# Store for figures script
ES_COEF_HR = coef_df_hr
ES_COEF_NHR = coef_df_nhr

print("  Saved event study coefficients")
