"""
Analysis Script 01: Descriptive Statistics Table

Creates a 4-column descriptive table:
- All observations
- Treated × Post
- Treated × Pre
- Untreated (Control)
"""

import pandas as pd
import numpy as np
from pathlib import Path

# Set project root
ROOT = Path(__file__).parent.parent.parent
print(f"Project root: {ROOT}")

# Define paths
input_file = ROOT / "build/output/analysis_panel.csv"
output_file = ROOT / "analysis/output/descriptive_table.csv"

print("\n" + "=" * 60)
print("DESCRIPTIVE STATISTICS TABLE")
print("=" * 60)

# Read analysis panel
print(f"\nReading data from: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} observations")

# Define variables for descriptive table
variables = [
    'total_crashes',
    'fatal_crashes',
    'serious_crashes',
    'fatal_share',
    'population',
    'median_income',
    'pct_urban',
]

# Create subsamples
all_obs = df
treated_post = df[(df['policy_adopted'] == 1) & (df['year'] >= df['adoption_year'])]
treated_pre = df[(df['policy_adopted'] == 1) & (df['year'] < df['adoption_year'])]
control = df[df['policy_adopted'] == 0]

print(f"\nSample sizes:")
print(f"  All observations:  {len(all_obs):>6,}")
print(f"  Treated × Post:    {len(treated_post):>6,}")
print(f"  Treated × Pre:     {len(treated_pre):>6,}")
print(f"  Control:           {len(control):>6,}")

# Function to compute statistics
def compute_stats(data, variables):
    stats = []
    for var in variables:
        mean = data[var].mean()
        std = data[var].std()
        stats.append({
            'variable': var,
            'mean': mean,
            'std': std,
            'n': data[var].notna().sum()
        })
    return pd.DataFrame(stats)

# Compute statistics for each subsample
print("\nComputing statistics...")
stats_all = compute_stats(all_obs, variables)
stats_all['sample'] = 'All'

stats_treated_post = compute_stats(treated_post, variables)
stats_treated_post['sample'] = 'Treated×Post'

stats_treated_pre = compute_stats(treated_pre, variables)
stats_treated_pre['sample'] = 'Treated×Pre'

stats_control = compute_stats(control, variables)
stats_control['sample'] = 'Control'

# Combine all statistics
all_stats = pd.concat([stats_all, stats_treated_post, stats_treated_pre, stats_control])

# Pivot to wide format
table = all_stats.pivot(index='variable', columns='sample', values=['mean', 'std'])
table = table.reorder_levels([1, 0], axis=1)
table = table[['All', 'Treated×Post', 'Treated×Pre', 'Control']]

# Format the table
print("\n" + "=" * 100)
print("DESCRIPTIVE STATISTICS TABLE")
print("=" * 100)
print()

# Print formatted table
for var in variables:
    print(f"{var:20s}", end="")
    for sample in ['All', 'Treated×Post', 'Treated×Pre', 'Control']:
        mean_val = table.loc[var, (sample, 'mean')]
        std_val = table.loc[var, (sample, 'std')]
        print(f"  {mean_val:>10.2f} ({std_val:>8.2f})", end="")
    print()

print()
print(f"Observations", end="")
for sample in ['All', 'Treated×Post', 'Treated×Pre', 'Control']:
    n = all_stats[all_stats['sample'] == sample]['n'].iloc[0]
    print(f"  {n:>10,}{' ':>11s}", end="")
print()
print("=" * 100)

# Create output dataframe
output_table = pd.DataFrame()
for var in variables:
    row_data = {'Variable': var}
    for sample in ['All', 'Treated×Post', 'Treated×Pre', 'Control']:
        mean_val = table.loc[var, (sample, 'mean')]
        std_val = table.loc[var, (sample, 'std')]
        row_data[f'{sample}_mean'] = mean_val
        row_data[f'{sample}_sd'] = std_val
    output_table = pd.concat([output_table, pd.DataFrame([row_data])], ignore_index=True)

# Save output
print(f"\nSaving to: {output_file.relative_to(ROOT)}")
output_file.parent.mkdir(parents=True, exist_ok=True)
output_table.to_csv(output_file, index=False)

print(f"✓ Saved descriptive statistics table")
print(f"✓ Variables: {len(variables)}")
print(f"✓ Samples: 4 (All, Treated×Post, Treated×Pre, Control)")
