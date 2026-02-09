# 01_summary_stats.py - Summary statistics

import pandas as pd
import numpy as np

# Load analysis data
analysis_data = pd.read_parquet(BUILD / "output" / "analysis_data.parquet")

print(f"  Observations: {len(analysis_data)}")
print(f"  States: {analysis_data['state_fips'].nunique()}")
print(f"  Years: {analysis_data['year'].min()}-{analysis_data['year'].max()}")

# Create output directories
(ANALYSIS / "output" / "tables").mkdir(parents=True, exist_ok=True)
(ANALYSIS / "output" / "figures").mkdir(parents=True, exist_ok=True)

# Summary statistics
summary_cols = ['total_fatalities', 'hr_fatalities', 'nhr_fatalities',
                'treated', 'ln_hr', 'ln_nhr']
if 'unemployment' in analysis_data.columns:
    summary_cols.append('unemployment')
if 'income' in analysis_data.columns:
    summary_cols.append('income')

summary_stats = analysis_data[summary_cols].describe().T
summary_stats = summary_stats[['count', 'mean', 'std', 'min', 'max']]

# Save
summary_stats.to_csv(ANALYSIS / "output" / "tables" / "summary_stats.csv")
print(f"  Saved summary statistics to analysis/output/tables/summary_stats.csv")

# Also by treatment status
by_treated = analysis_data.groupby('treated')[summary_cols].agg(['mean', 'std', 'count'])
by_treated.to_csv(ANALYSIS / "output" / "tables" / "summary_by_treatment.csv")

print("\n  Summary Statistics:")
print(summary_stats.round(2).to_string())
