"""
Session 3: Diff-in-Diff and Event Studies
Course: 14.33 Economics Research and Communication

This script demonstrates:
1. Setting up panel data for DiD
2. Creating treatment timing variables
3. Running two-way fixed effects (TWFE)
4. Running event study specifications
"""

import pandas as pd
import numpy as np
import pyfixest as pf
import matplotlib.pyplot as plt

# Set working directory (adjust as needed)
# import os
# os.chdir("/Users/yourname/Dropbox/14.33")

#===============================================================================
# STEP 1: Load and explore data
#===============================================================================

# Load the data (adjust path as needed)
df = pd.read_stata("bacon_example_diff_in_diff_review.dta")

# Explore structure
print("Years in data:")
print(df['year'].value_counts().sort_index())

print("\nStates in data:")
print(df['stfips'].value_counts().sort_index())

# Examine key variables
print("\nSummary of outcome variable (female suicide rate):")
print(df['asmrs'].describe())

print("\nSummary of control variables:")
print(df[['pcinc', 'asmrh', 'cases']].describe())

#===============================================================================
# STEP 2: Create treatment timing variable
#===============================================================================

# Create adoption year mapping
# NaN = never adopted (control state)
adoption_years = {
    1: 1971, 4: 1973, 6: 1970, 8: 1971, 9: 1973, 11: 1977,
    12: 1971, 13: 1973, 16: 1971, 17: 1984, 18: 1973, 19: 1970,
    20: 1969, 21: 1972, 23: 1973, 25: 1975, 26: 1972, 27: 1974,
    29: 1973, 30: 1975, 31: 1972, 32: 1973, 33: 1971, 34: 1971,
    35: 1973, 38: 1971, 39: 1974, 41: 1973, 42: 1980, 44: 1976,
    45: 1969, 46: 1985, 48: 1974, 53: 1973, 55: 1977, 56: 1977
}

# Add adoption year to dataframe
df['nfd'] = df['stfips'].map(adoption_years)

# Check: how many states adopted vs never adopted?
print("\nNo-fault divorce adoption years:")
print(df['nfd'].value_counts(dropna=False).sort_index())

#===============================================================================
# STEP 3: Create post-treatment indicator for TWFE
#===============================================================================

# Create post-treatment indicator
# = 1 if year >= year state adopted no-fault divorce
# = 0 otherwise (including never-adopters)
df['treat_post'] = ((df['nfd'].notna()) & (df['year'] >= df['nfd'])).astype(int)

# Verify
print("\nPost-treatment indicator distribution:")
print(df['treat_post'].value_counts())

#===============================================================================
# STEP 4: Two-Way Fixed Effects (TWFE) Regression
#===============================================================================

# Basic TWFE: state + year fixed effects
model_twfe_basic = pf.feols('asmrs ~ treat_post | stfips + year',
                             vcov={'CRV1': 'stfips'}, data=df)
print("\n" + "="*60)
print("TWFE Model (No Controls)")
print("="*60)
print(model_twfe_basic.summary())

# With controls
model_twfe_controls = pf.feols('asmrs ~ treat_post + pcinc + asmrh + cases | stfips + year',
                                vcov={'CRV1': 'stfips'}, data=df)
print("\n" + "="*60)
print("TWFE Model (With Controls)")
print("="*60)
print(model_twfe_controls.summary())

# Compare models
pf.etable([model_twfe_basic, model_twfe_controls])

#===============================================================================
# STEP 5: Event Study Specification
#===============================================================================

# Create time relative to treatment
# Negative = years before treatment
# 0 = year of treatment
# Positive = years after treatment
#
# IMPORTANT: Never-treated states don't have a meaningful "time to treatment"
# Set them to -1000 (outside the range of real event times)
# Then exclude with ref=c(-1, -1000) in pyfixest
df['time_to_treat'] = df['year'] - df['nfd']
df['time_to_treat'] = df['time_to_treat'].fillna(-1000).astype(int)
df['ever_treated'] = df['nfd'].notna().astype(int)

# Check the distribution
print("\nTime to treatment distribution:")
print(df['time_to_treat'].value_counts().sort_index())

# Event study using pyfixest's i() syntax
# i(time_to_treat, ever_treated, ref=c(-1, -1000)):
#   - time_to_treat: relative time variable (-1000 for never-treated)
#   - ever_treated: interaction (so never-treated don't get dummies)
#   - ref=c(-1, -1000): exclude both reference period AND never-treated
# See: https://lrberge.github.io/fixest/articles/fixest_walkthrough.html
model_es = pf.feols(
    'asmrs ~ i(time_to_treat, ever_treated, ref=c(-1, -1000)) + pcinc + asmrh + cases | stfips + year',
    vcov={'CRV1': 'stfips'}, data=df
)

print("\n" + "="*60)
print("Event Study Model")
print("="*60)
print(model_es.summary())

#===============================================================================
# STEP 6: Create Event Study Plot
#===============================================================================

# pyfixest provides a convenient plotting function
fig = model_es.iplot(figsize=(12, 6))
plt.title("Event Study: No-Fault Divorce and Female Suicide")
plt.xlabel("Years Relative to No-Fault Divorce Adoption")
plt.ylabel("Effect on Female Suicide Rate")
plt.axhline(y=0, linestyle='--', color='gray', alpha=0.5)
plt.axvline(x=-0.5, linestyle='--', color='red', alpha=0.3, label='Treatment')
plt.tight_layout()
plt.savefig('output/event_study_plot.png', dpi=300)
plt.show()

# Alternative: Manual plotting with more control
# Extract coefficients
coef_df = pd.DataFrame({
    'coef': model_es.coef(),
    'se': model_es.se()
}).reset_index()
coef_df.columns = ['term', 'estimate', 'se']

# Filter to time_to_treat coefficients
es_coefs = coef_df[coef_df['term'].str.contains('time_to_treat')].copy()
es_coefs['time'] = es_coefs['term'].str.extract(r'time_to_treat::(-?\d+)').astype(float)
es_coefs['ci_lower'] = es_coefs['estimate'] - 1.96 * es_coefs['se']
es_coefs['ci_upper'] = es_coefs['estimate'] + 1.96 * es_coefs['se']

# Add reference period (t = -1)
ref_row = pd.DataFrame({'time': [-1], 'estimate': [0], 'se': [0], 'ci_lower': [0], 'ci_upper': [0]})
es_coefs = pd.concat([es_coefs[['time', 'estimate', 'se', 'ci_lower', 'ci_upper']], ref_row])
es_coefs = es_coefs.sort_values('time')

# Create custom plot
fig, ax = plt.subplots(figsize=(12, 6))
ax.axhline(y=0, linestyle='--', color='gray', alpha=0.5)
ax.axvline(x=-0.5, linestyle='--', color='red', alpha=0.3)
ax.fill_between(es_coefs['time'], es_coefs['ci_lower'], es_coefs['ci_upper'],
                alpha=0.2, color='steelblue')
ax.plot(es_coefs['time'], es_coefs['estimate'], 'o-', color='steelblue', markersize=6)
ax.set_xlabel("Years Relative to No-Fault Divorce Adoption")
ax.set_ylabel("Effect on Female Suicide Rate")
ax.set_title("Event Study: No-Fault Divorce and Female Suicide", fontweight='bold')
plt.tight_layout()
plt.savefig('output/event_study_custom.png', dpi=300)
plt.show()

#===============================================================================
# NOTES
#===============================================================================

print("""
Key things to check in event studies:
1. Pre-treatment coefficients should be near zero (parallel trends)
2. Look for anticipation effects (significant coefficients before t=0)
3. Post-treatment coefficients show the treatment effect over time

Modern DiD methods for staggered adoption:
- Goodman-Bacon decomposition
- Callaway & Sant'Anna: differences package
- Sun & Abraham: pyfixest supports this
- Imputation estimator

Session 3 complete!
""")
