"""
Analysis Script 05: Regression Discontinuity Design

Estimates RD models:
1. Linear RD using statsmodels
2. Polynomial RD (quadratic)
3. RD plot with binned scatter
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

try:
    import statsmodels.api as sm
    from statsmodels.formula.api import ols
except ImportError:
    print("ERROR: statsmodels not installed. Install with: pip install statsmodels")
    raise

# Set project root
ROOT = Path(__file__).parent.parent.parent
print(f"Project root: {ROOT}")

# Define paths
input_file = ROOT / "analysis/code/rd_data.csv"
output_file = ROOT / "analysis/output/rd_results.txt"
output_plot = ROOT / "analysis/figures/rd_plot.png"

print("\n" + "=" * 60)
print("REGRESSION DISCONTINUITY DESIGN")
print("=" * 60)

# Read RD data
print(f"\nReading data from: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} observations")

print("\nVariables:")
for col in df.columns:
    print(f"  - {col}")

# Check the running variable
print(f"\nRunning variable: days_from_21")
print(f"  Range: {df['days_from_21'].min():.1f} to {df['days_from_21'].max():.1f}")
print(f"  Cutoff: 0 (age 21)")
print(f"  Observations below cutoff: {(df['days_from_21'] < 0).sum():,}")
print(f"  Observations above cutoff: {(df['days_from_21'] >= 0).sum():,}")

print("\nSummary statistics:")
print(df.describe())

print("\n" + "-" * 60)
print("LINEAR RD REGRESSION")
print("-" * 60)
print("Model: mortality_rate ~ over_21 + days_from_21 + over_21*days_from_21 + male + income")
print()

# Linear RD
# Create interaction term
df['over_21_x_days'] = df['over_21'] * df['days_from_21']

# Estimate linear RD
formula = 'mortality_rate ~ over_21 + days_from_21 + over_21_x_days + male + income'
linear_rd = ols(formula, data=df).fit()

print(linear_rd.summary())

# Extract RD estimate
rd_estimate = linear_rd.params['over_21']
rd_se = linear_rd.bse['over_21']
rd_pvalue = linear_rd.pvalues['over_21']

print(f"\n{'=' * 60}")
print(f"RD Estimate (Linear): {rd_estimate:.4f}")
print(f"Standard Error:       {rd_se:.4f}")
print(f"P-value:              {rd_pvalue:.4f}")
print(f"95% CI:               [{rd_estimate - 1.96*rd_se:.4f}, {rd_estimate + 1.96*rd_se:.4f}]")
print(f"{'=' * 60}")

print("\n" + "-" * 60)
print("POLYNOMIAL RD REGRESSION (QUADRATIC)")
print("-" * 60)
print("Model: mortality_rate ~ over_21 + days_from_21 + days_from_21^2 + interactions + male + income")
print()

# Polynomial RD
df['days_from_21_sq'] = df['days_from_21'] ** 2
df['over_21_x_days_sq'] = df['over_21'] * df['days_from_21_sq']

formula_poly = 'mortality_rate ~ over_21 + days_from_21 + days_from_21_sq + over_21_x_days + over_21_x_days_sq + male + income'
poly_rd = ols(formula_poly, data=df).fit()

print(poly_rd.summary())

# Extract polynomial RD estimate
rd_estimate_poly = poly_rd.params['over_21']
rd_se_poly = poly_rd.bse['over_21']
rd_pvalue_poly = poly_rd.pvalues['over_21']

print(f"\n{'=' * 60}")
print(f"RD Estimate (Quadratic): {rd_estimate_poly:.4f}")
print(f"Standard Error:          {rd_se_poly:.4f}")
print(f"P-value:                 {rd_pvalue_poly:.4f}")
print(f"95% CI:                  [{rd_estimate_poly - 1.96*rd_se_poly:.4f}, {rd_estimate_poly + 1.96*rd_se_poly:.4f}]")
print(f"{'=' * 60}")

print("\n" + "-" * 60)
print("CREATING RD PLOT")
print("-" * 60)

# Create binned scatter plot
# Restrict to reasonable bandwidth
bandwidth = 730  # 2 years
df_plot = df[(df['days_from_21'] >= -bandwidth) & (df['days_from_21'] <= bandwidth)].copy()

print(f"\nUsing bandwidth: ±{bandwidth} days")
print(f"Observations in bandwidth: {len(df_plot):,}")

# Create bins
n_bins = 40
df_plot['bin'] = pd.cut(df_plot['days_from_21'], bins=n_bins)

# Calculate bin means
bin_stats = df_plot.groupby('bin').agg({
    'days_from_21': 'mean',
    'mortality_rate': 'mean',
    'over_21': 'first'
}).reset_index(drop=True)

# Create fitted values for smooth lines
x_below = np.linspace(-bandwidth, 0, 100)
x_above = np.linspace(0, bandwidth, 100)

# Linear fit
df_below = pd.DataFrame({'days_from_21': x_below, 'over_21': 0, 'over_21_x_days': 0, 'male': df['male'].mean(), 'income': df['income'].mean()})
df_above = pd.DataFrame({'days_from_21': x_above, 'over_21': 1, 'over_21_x_days': x_above, 'male': df['male'].mean(), 'income': df['income'].mean()})

y_below = linear_rd.predict(df_below)
y_above = linear_rd.predict(df_above)

# Create plot
fig, ax = plt.subplots(figsize=(12, 7))

# Plot binned scatter
below_cutoff = bin_stats[bin_stats['days_from_21'] < 0]
above_cutoff = bin_stats[bin_stats['days_from_21'] >= 0]

ax.scatter(below_cutoff['days_from_21'], below_cutoff['mortality_rate'],
          alpha=0.6, s=50, color='steelblue', label='Below cutoff (age < 21)', zorder=3)
ax.scatter(above_cutoff['days_from_21'], above_cutoff['mortality_rate'],
          alpha=0.6, s=50, color='firebrick', label='Above cutoff (age ≥ 21)', zorder=3)

# Plot fitted lines
ax.plot(x_below, y_below, color='steelblue', linewidth=2.5, zorder=2)
ax.plot(x_above, y_above, color='firebrick', linewidth=2.5, zorder=2)

# Add cutoff line
ax.axvline(x=0, color='black', linestyle='--', linewidth=2, alpha=0.7, label='Cutoff (age 21)', zorder=1)

# Add RD estimate annotation
y_at_cutoff_below = linear_rd.predict(pd.DataFrame({'days_from_21': [0], 'over_21': [0], 'over_21_x_days': [0], 'male': [df['male'].mean()], 'income': [df['income'].mean()]}))[0]
y_at_cutoff_above = linear_rd.predict(pd.DataFrame({'days_from_21': [0], 'over_21': [1], 'over_21_x_days': [0], 'male': [df['male'].mean()], 'income': [df['income'].mean()]}))[0]

# Add annotation showing the jump
ax.annotate('',
           xy=(50, y_at_cutoff_above),
           xytext=(50, y_at_cutoff_below),
           arrowprops=dict(arrowstyle='<->', color='green', lw=2))
ax.text(60, (y_at_cutoff_above + y_at_cutoff_below) / 2,
       f'RD Estimate:\n{rd_estimate:.3f}\n(SE: {rd_se:.3f})',
       fontsize=11, fontweight='bold', color='green',
       bbox=dict(boxstyle='round', facecolor='white', edgecolor='green', alpha=0.8))

# Styling
ax.set_xlabel('Days from Age 21', fontsize=13, fontweight='bold')
ax.set_ylabel('Mortality Rate', fontsize=13, fontweight='bold')
ax.set_title('Regression Discontinuity: Effect of Turning 21 on Mortality Rate',
            fontsize=15, fontweight='bold', pad=20)
ax.grid(True, alpha=0.3, linestyle='--')
ax.legend(loc='best', frameon=True, shadow=True, fontsize=11)

plt.tight_layout()
output_plot.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(output_plot, dpi=300, bbox_inches='tight')
plt.close()

print(f"✓ Saved: {output_plot.relative_to(ROOT)}")

# Save results
print(f"\nSaving to: {output_file.relative_to(ROOT)}")
output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, 'w') as f:
    f.write("=" * 80 + "\n")
    f.write("REGRESSION DISCONTINUITY DESIGN RESULTS\n")
    f.write("=" * 80 + "\n\n")

    f.write("LINEAR RD REGRESSION\n")
    f.write("-" * 80 + "\n")
    f.write(linear_rd.summary().as_text() + "\n\n")
    f.write(f"RD Estimate (Linear): {rd_estimate:.4f}\n")
    f.write(f"Standard Error:       {rd_se:.4f}\n")
    f.write(f"P-value:              {rd_pvalue:.4f}\n")
    f.write(f"95% CI:               [{rd_estimate - 1.96*rd_se:.4f}, {rd_estimate + 1.96*rd_se:.4f}]\n\n")

    f.write("POLYNOMIAL RD REGRESSION (QUADRATIC)\n")
    f.write("-" * 80 + "\n")
    f.write(poly_rd.summary().as_text() + "\n\n")
    f.write(f"RD Estimate (Quadratic): {rd_estimate_poly:.4f}\n")
    f.write(f"Standard Error:          {rd_se_poly:.4f}\n")
    f.write(f"P-value:                 {rd_pvalue_poly:.4f}\n")
    f.write(f"95% CI:                  [{rd_estimate_poly - 1.96*rd_se_poly:.4f}, {rd_estimate_poly + 1.96*rd_se_poly:.4f}]\n")

print(f"✓ Saved RD regression results")
print(f"✓ Linear RD estimate: {rd_estimate:.4f} (SE: {rd_se:.4f})")
print(f"✓ Quadratic RD estimate: {rd_estimate_poly:.4f} (SE: {rd_se_poly:.4f})")
print(f"✓ Created RD plot")

print("\n" + "=" * 60)
print("RD ANALYSIS COMPLETE")
print("=" * 60)
