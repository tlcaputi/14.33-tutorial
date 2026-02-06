"""
Python Session 2: Loops, Organization, and Regression
14.33 Economics Research and Communication

This script covers:
- Loops (for, list comprehensions)
- Variables and functions
- Project organization
- OLS regression (statsmodels)
- Fixed effects (pyfixest)
- Instrumental variables
- Exporting results
"""

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf

# Try to import pyfixest for fixed effects
try:
    import pyfixest as pf
    HAS_PYFIXEST = True
except ImportError:
    HAS_PYFIXEST = False
    print("Note: pyfixest not installed. Install with: pip install pyfixest")

#===============================================================================
# PART 1: LOOPS
#===============================================================================

# Basic for loop
for i in range(1, 6):
    print(f"Iteration {i}")

# Loop with step size
for i in range(5, 26, 5):
    print(f"Value: {i}")

# Loop over a list
vars_list = ['mpg', 'horsepower', 'weight']
for var in vars_list:
    print(f"Variable: {var}")

# List comprehension (more Pythonic)
results = [f"Variable: {var}" for var in vars_list]
print(results)

#===============================================================================
# PART 2: VARIABLES AND FUNCTIONS
#===============================================================================

# Store a value
myvar = 7
print(myvar)

# Store a list of controls
controls = ['horsepower', 'weight']

# Load sample data
try:
    import seaborn as sns
    mtcars = sns.load_dataset('mpg').dropna()
except:
    # Create sample data if seaborn not available
    mtcars = pd.DataFrame({
        'mpg': [21.0, 21.0, 22.8, 21.4, 18.7, 18.1, 14.3, 24.4, 22.8, 19.2],
        'cylinders': [6, 6, 4, 6, 8, 6, 8, 4, 4, 6],
        'horsepower': [110, 110, 93, 110, 175, 105, 245, 62, 95, 123],
        'weight': [2620, 2875, 2320, 3215, 3440, 3460, 3570, 2200, 2465, 3520],
        'origin': ['usa', 'usa', 'japan', 'usa', 'usa', 'usa', 'usa', 'europe', 'japan', 'usa']
    })

# Use in a model
model = smf.ols('mpg ~ horsepower + weight', data=mtcars).fit()
print(model.summary())

# Extract coefficient
coef_hp = model.params['horsepower']
print(f"Horsepower coefficient: {coef_hp:.4f}")

#===============================================================================
# PART 3: PROJECT ORGANIZATION
#===============================================================================

# Example master script structure:
"""
from pathlib import Path

# Set paths
ROOT = Path("/Users/me/Dropbox/project")
BUILD = ROOT / "build"
ANALYSIS = ROOT / "analysis"

# Run scripts
exec(open(BUILD / "code" / "01_import.py").read())
exec(open(BUILD / "code" / "02_clean.py").read())
exec(open(ANALYSIS / "code" / "01_regressions.py").read())
"""

#===============================================================================
# PART 4: REGRESSION
#===============================================================================

# Simple OLS
model = smf.ols('mpg ~ horsepower', data=mtcars).fit()
print(model.summary())

# Multiple regression
model = smf.ols('mpg ~ horsepower + weight', data=mtcars).fit()
print(model.summary())

# Heteroskedasticity-robust standard errors (HC1)
model_robust = smf.ols('mpg ~ horsepower + weight', data=mtcars).fit(cov_type='HC1')
print(model_robust.summary())

# Clustered standard errors
model_cluster = smf.ols('mpg ~ horsepower + weight', data=mtcars).fit(
    cov_type='cluster',
    cov_kwds={'groups': mtcars['cylinders']}
)
print(model_cluster.summary())

#===============================================================================
# PART 5: INTERACTIONS
#===============================================================================

# Create binary variable for interaction
mtcars['foreign'] = (mtcars['origin'] != 'usa').astype(int)

# : adds just the interaction
model = smf.ols('mpg ~ horsepower + foreign:weight', data=mtcars).fit()

# * adds interaction AND main effects
model = smf.ols('mpg ~ horsepower + foreign * weight', data=mtcars).fit()
print(model.summary())

#===============================================================================
# PART 6: FIXED EFFECTS (with pyfixest)
#===============================================================================

if HAS_PYFIXEST:
    # One-way fixed effects
    model_fe = pf.feols('mpg ~ horsepower + weight | cylinders', data=mtcars)
    print(model_fe.summary())

    # Two-way fixed effects (if you have another grouping variable)
    # model_twfe = pf.feols('mpg ~ horsepower + weight | cylinders + year', data=mtcars)

    # With clustered standard errors
    model_fe_cl = pf.feols('mpg ~ horsepower + weight | cylinders',
                           data=mtcars, vcov={'CRV1': 'cylinders'})
    print(model_fe_cl.summary())
else:
    # Alternative: use statsmodels with dummy variables
    model_fe = smf.ols('mpg ~ horsepower + weight + C(cylinders)', data=mtcars).fit()
    print(model_fe.summary())

#===============================================================================
# PART 7: INSTRUMENTAL VARIABLES
#===============================================================================

# Using linearmodels for IV
try:
    from linearmodels.iv import IV2SLS

    # IV syntax: Y ~ controls + [endogenous ~ instruments]
    model_iv = IV2SLS.from_formula(
        'mpg ~ weight + [horsepower ~ displacement]',
        data=mtcars.rename(columns={'horsepower': 'horsepower', 'weight': 'weight'})
    )
    # Note: This is just syntax demo, not a real IV setup

except ImportError:
    print("Note: linearmodels not installed. Install with: pip install linearmodels")

#===============================================================================
# PART 8: EXPORTING RESULTS
#===============================================================================

# Run multiple models
m1 = smf.ols('mpg ~ horsepower', data=mtcars).fit(cov_type='HC1')
m2 = smf.ols('mpg ~ horsepower + weight', data=mtcars).fit(cov_type='HC1')
m3 = smf.ols('mpg ~ horsepower + weight + C(cylinders)', data=mtcars).fit(cov_type='HC1')

# Create results DataFrame
results_df = pd.DataFrame({
    'Variable': ['horsepower', 'weight'],
    'Model 1': [f"{m1.params.get('horsepower', ''):.4f}"],
    'Model 2': [f"{m2.params.get('horsepower', ''):.4f}", f"{m2.params.get('weight', ''):.4f}"],
    'Model 3': [f"{m3.params.get('horsepower', ''):.4f}", f"{m3.params.get('weight', ''):.4f}"]
})
print(results_df)

# Export to CSV
# results_df.to_csv("results.csv", index=False)

# For LaTeX tables, use stargazer or manual formatting
# pip install stargazer

#===============================================================================
# PART 9: RUNNING MULTIPLE REGRESSIONS
#===============================================================================

# Run same regression for different outcomes (or subgroups)
outcomes = ['mpg']  # Would have more if we had more outcome variables
results = []

for outcome in outcomes:
    model = smf.ols(f'{outcome} ~ horsepower + weight', data=mtcars).fit(cov_type='HC1')
    results.append({
        'outcome': outcome,
        'beta_hp': model.params['horsepower'],
        'se_hp': model.bse['horsepower'],
        'n': int(model.nobs)
    })

results_df = pd.DataFrame(results)
print(results_df)

#===============================================================================
# PRACTICE EXERCISE
#===============================================================================

print("\n\nPRACTICE EXERCISE:")
print("1. Create a list called 'controls' containing ['weight', 'displacement']")
print("2. Run: smf.ols('mpg ~ horsepower + weight', data=mtcars).fit(cov_type='HC1')")
print("3. Use a loop to print summary stats for 'mpg', 'weight', 'horsepower'\n")

# Solution:
controls = ['weight', 'displacement']
model_practice = smf.ols('mpg ~ horsepower + weight', data=mtcars).fit(cov_type='HC1')
print(model_practice.summary())

for v in ['mpg', 'weight', 'horsepower']:
    print(f"\nSummary for {v}:")
    print(mtcars[v].describe())

print("\n\nSession 2 script complete!")
