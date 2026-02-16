"""
Analysis Script 03: Event Study Analysis

Estimates event study models using pyfixest:
1. Event study with time-to-treatment indicators
2. Creates event study plot using both pyfixest.iplot and matplotlib
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
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
output_plot = ROOT / "analysis/figures/event_study.png"

print("\n" + "=" * 60)
print("EVENT STUDY ANALYSIS")
print("=" * 60)

# Read analysis panel
print(f"\nReading data from: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} observations")

# Create log outcome
df['log_fatal_crashes'] = np.log(df['fatal_crashes'] + 1)

# Create time-to-treatment variable
print("\nCreating time-to-treatment variable...")

# For treated states: years relative to adoption
# For never-treated states: set to NaN (they serve as controls via FE)
df['time_to_treat'] = np.where(
    df['adoption_year'].notna() & (df['adoption_year'] > 0),
    df['year'] - df['adoption_year'],
    np.nan
)

# Bin endpoints at -5 and +5
treated_mask = df['time_to_treat'].notna()
print(f"  Time-to-treatment range: {df.loc[treated_mask, 'time_to_treat'].min():.0f} to "
      f"{df.loc[treated_mask, 'time_to_treat'].max():.0f}")
print(f"  Never-treated observations: {(~treated_mask).sum():,}")

df['event_time'] = df['time_to_treat'].copy()
df.loc[df['event_time'] < -5, 'event_time'] = -5
df.loc[df['event_time'] > 5, 'event_time'] = 5

print("\n" + "-" * 60)
print("EVENT STUDY REGRESSION")
print("-" * 60)

# Create dummies manually for each event time (excluding -1 as reference)
event_times = sorted(df.loc[treated_mask, 'event_time'].dropna().unique().astype(int))

def et_name(t):
    """Create valid variable name for event time dummy."""
    return f'et_m{abs(t)}' if t < 0 else f'et_p{t}'

for t in event_times:
    df[et_name(t)] = ((df['event_time'] == t) & treated_mask).astype(int)

# Drop the reference period (t = -1)
event_vars = [et_name(t) for t in event_times if t != -1]
formula = "log_fatal_crashes ~ " + " + ".join(event_vars) + " | state_fips + year"

mod = pf.feols(
    formula,
    data=df,
    vcov={'CRV1': 'state_fips'}
)

print(mod.summary())

# Extract coefficients for plotting
coef_data = []
for t in event_times:
    if t == -1:
        coef_data.append({'time_to_treat': t, 'coefficient': 0.0, 'se': 0.0})
    else:
        var = et_name(t)
        coef_data.append({
            'time_to_treat': t,
            'coefficient': mod.coef()[var],
            'se': mod.se()[var]
        })

coef_df = pd.DataFrame(coef_data).sort_values('time_to_treat')

# Calculate confidence intervals
coef_df['ci_lower'] = coef_df['coefficient'] - 1.96 * coef_df['se']
coef_df['ci_upper'] = coef_df['coefficient'] + 1.96 * coef_df['se']

print("\n" + "-" * 60)
print("EVENT STUDY COEFFICIENTS")
print("-" * 60)
print(coef_df.to_string(index=False))

print("\n" + "-" * 60)
print("CREATING EVENT STUDY PLOTS")
print("-" * 60)

# Create event study plot using matplotlib
print("\nCreating event study plot...")
fig, ax = plt.subplots(figsize=(12, 7))

# Plot coefficients
ax.scatter(coef_df['time_to_treat'], coef_df['coefficient'],
          color='steelblue', s=50, zorder=3, label='Point estimate')

# Plot confidence intervals
ax.fill_between(coef_df['time_to_treat'],
                coef_df['ci_lower'],
                coef_df['ci_upper'],
                alpha=0.2, color='steelblue', label='95% CI')

# Add connecting line
ax.plot(coef_df['time_to_treat'], coef_df['coefficient'],
       color='steelblue', linewidth=1.5, alpha=0.6, zorder=2)

# Reference lines
ax.axhline(y=0, color='black', linestyle='-', linewidth=1.0)
ax.axvline(x=-0.5, color='red', linestyle='--', linewidth=1.5, alpha=0.7, label='Policy adoption')

# Styling
ax.set_xlabel('Years Relative to Policy Adoption', fontsize=13, fontweight='bold')
ax.set_ylabel('Coefficient (Log Fatal Crashes)', fontsize=13, fontweight='bold')
ax.set_title('Event Study: Effect of Policy on Log Fatal Crashes',
            fontsize=15, fontweight='bold', pad=20)
ax.grid(True, alpha=0.3, linestyle='--')
ax.legend(loc='best', frameon=True, shadow=True)

# Set x-axis limits to focus on relevant range
time_range = coef_df['time_to_treat']
time_range = time_range[(time_range >= -10) & (time_range <= 10)]
if len(time_range) > 0:
    ax.set_xlim(time_range.min() - 1, time_range.max() + 1)

plt.tight_layout()
output_plot.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(output_plot, dpi=300, bbox_inches='tight')
plt.close()

print(f"✓ Saved: {output_plot.relative_to(ROOT)}")

print("\n" + "=" * 60)
print("EVENT STUDY COMPLETE")
print("=" * 60)
print(f"✓ Estimated {len(coef_df) - 1} event-time coefficients")
print(f"✓ Reference period: t = -1")
print(f"✓ Created event study plot")
