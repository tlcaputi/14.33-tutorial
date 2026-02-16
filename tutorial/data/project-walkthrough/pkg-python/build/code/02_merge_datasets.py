"""
Build Script 02: Merge Datasets

Merges crash data with state demographics, policy adoptions, and state names.
Creates the final analysis panel dataset.
"""

import pandas as pd
import numpy as np
from pathlib import Path

# Set project root
ROOT = Path(__file__).parent.parent.parent
print(f"Project root: {ROOT}")

# Define paths
crashes_file = ROOT / "build/output/crashes_state_year.csv"
demographics_file = ROOT / "build/input/state_demographics.dta"
policy_file = ROOT / "build/input/policy_adoptions.csv"
names_file = ROOT / "build/input/state_names.csv"
output_file = ROOT / "build/output/analysis_panel.csv"

print("\n" + "=" * 60)
print("MERGING DATASETS")
print("=" * 60)

# Read crashes data
print(f"\n[1/4] Reading crashes: {crashes_file.relative_to(ROOT)}")
crashes = pd.read_csv(crashes_file)
print(f"      Loaded {len(crashes):,} state-year observations")

# Read state demographics
print(f"\n[2/4] Reading demographics: {demographics_file.relative_to(ROOT)}")
demographics = pd.read_stata(demographics_file)
print(f"      Loaded {len(demographics):,} state-year observations")

# Read policy adoptions
print(f"\n[3/4] Reading policy adoptions: {policy_file.relative_to(ROOT)}")
policy = pd.read_csv(policy_file)
print(f"      Loaded {len(policy):,} states")
print(f"      Treated states: {policy['policy_adopted'].sum()}")

# Read state names
print(f"\n[4/4] Reading state names: {names_file.relative_to(ROOT)}")
state_names = pd.read_csv(names_file)
print(f"      Loaded {len(state_names):,} states")

# Merge datasets
print("\nMerging datasets...")

# Start with crashes
print("  Step 1: Crashes + Demographics")
df = pd.merge(crashes, demographics, on=['state_fips', 'year'], how='left')
print(f"    Result: {len(df):,} observations")

# Merge policy adoptions
print("  Step 2: + Policy Adoptions")
df = pd.merge(df, policy, on='state_fips', how='left')
print(f"    Result: {len(df):,} observations")

# Merge state names
print("  Step 3: + State Names")
df = pd.merge(df, state_names, on='state_fips', how='left')
print(f"    Result: {len(df):,} observations")

# Create treatment indicator
print("\nCreating treatment variables...")
df['treated'] = np.where(
    df['policy_adopted'] == 1,
    np.where(df['year'] >= df['adoption_year'], 1, 0),
    0
)

# Create log population
df['log_pop'] = np.log(df['population'])

# Display treatment summary
print("\nTreatment summary:")
treated_states = df[df['policy_adopted'] == 1]['state_fips'].nunique()
print(f"  Treated states: {treated_states}")
print(f"  Control states: {df['state_fips'].nunique() - treated_states}")
print(f"  Treated observations: {df['treated'].sum():,}")
print(f"  Control observations: {(df['treated'] == 0).sum():,}")

# Display variable list
print(f"\nFinal dataset variables ({len(df.columns)}):")
for col in df.columns:
    print(f"  - {col}")

# Display summary statistics for key variables
print("\nSummary statistics for key variables:")
key_vars = ['total_crashes', 'fatal_crashes', 'population', 'median_income', 'treated']
print(df[key_vars].describe())

# Save output
print(f"\nSaving to: {output_file.relative_to(ROOT)}")
output_file.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(output_file, index=False)

print(f"✓ Saved {len(df):,} observations")
print(f"✓ Variables: {len(df.columns)}")
print(f"✓ States: {df['state_fips'].nunique()}")
print(f"✓ Years: {df['year'].min()} - {df['year'].max()}")
