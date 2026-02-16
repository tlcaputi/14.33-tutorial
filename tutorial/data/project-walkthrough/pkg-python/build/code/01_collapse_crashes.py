"""
Build Script 01: Collapse Crash Data

Reads individual crash-level data and collapses to state-year level.
Creates aggregated crash statistics by severity.
"""

import pandas as pd
from pathlib import Path

# Set project root
ROOT = Path(__file__).parent.parent.parent
print(f"Project root: {ROOT}")

# Define paths
input_file = ROOT / "build/input/crash_data.csv"
output_file = ROOT / "build/output/crashes_state_year.csv"

print("\n" + "=" * 60)
print("COLLAPSING CRASH DATA TO STATE-YEAR LEVEL")
print("=" * 60)

# Read crash data
print(f"\nReading crash data from: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} individual crashes")
print(f"Years: {df['year'].min()} - {df['year'].max()}")
print(f"States: {df['state_fips'].nunique()}")

# Create severity indicators
df['fatal'] = (df['severity'] == 'fatal').astype(int)
df['serious'] = (df['severity'] == 'serious').astype(int)

# Collapse to state-year level
print("\nCollapsing to state-year level...")
collapsed = df.groupby(['state_fips', 'year']).agg(
    total_crashes=('severity', 'count'),
    fatal_crashes=('fatal', 'sum'),
    serious_crashes=('serious', 'sum')
).reset_index()

# Calculate fatal share
collapsed['fatal_share'] = collapsed['fatal_crashes'] / collapsed['total_crashes']

# Display summary statistics
print(f"\nCollapsed dataset: {len(collapsed):,} state-year observations")
print(f"\nSummary statistics:")
print(collapsed[['total_crashes', 'fatal_crashes', 'serious_crashes', 'fatal_share']].describe())

# Save output
print(f"\nSaving to: {output_file.relative_to(ROOT)}")
output_file.parent.mkdir(parents=True, exist_ok=True)
collapsed.to_csv(output_file, index=False)

print(f"✓ Saved {len(collapsed):,} observations")
print(f"✓ Variables: {', '.join(collapsed.columns)}")
