"""
Python Session 1: Basics through Merging
14.33 Economics Research and Communication

This script covers:
- Basic Python/pandas commands
- Exploring data
- Creating variables
- Importing CSV files
- Reshaping data (wide to long)
- Merging datasets
"""

import pandas as pd
import numpy as np

# Set display options
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)

#===============================================================================
# PART 1: BASIC COMMANDS
#===============================================================================

# Load example data (using seaborn's built-in datasets)
# pip install seaborn if needed
try:
    import seaborn as sns
    mtcars = sns.load_dataset('mpg').dropna()
except:
    # Create sample data if seaborn not available
    mtcars = pd.DataFrame({
        'mpg': [21.0, 21.0, 22.8, 21.4, 18.7, 18.1],
        'cylinders': [6, 6, 4, 6, 8, 6],
        'horsepower': [110, 110, 93, 110, 175, 105],
        'weight': [2620, 2875, 2320, 3215, 3440, 3460],
        'origin': ['usa', 'usa', 'japan', 'usa', 'usa', 'usa']
    })

# View the data
print(mtcars.head(10))

# Get an overview
print(mtcars.info())
print(mtcars.dtypes)

# Summary statistics
print(mtcars.describe())

# Summary of specific variables
print(mtcars[['mpg', 'horsepower', 'weight']].describe())

# Frequency table
print(mtcars['cylinders'].value_counts())

# Cross-tabulation
print(pd.crosstab(mtcars['cylinders'], mtcars['origin']))

#===============================================================================
# PART 2: CREATING VARIABLES
#===============================================================================

# Create a new variable
mtcars['hp_per_cyl'] = mtcars['horsepower'] / mtcars['cylinders']

# Create a binary indicator
mtcars['high_mpg'] = mtcars['mpg'] > 20

# Conditional assignment using np.select
conditions = [
    mtcars['mpg'] < 15,
    mtcars['mpg'] < 25,
    mtcars['mpg'] >= 25
]
choices = ['Low', 'Medium', 'High']
# Note: default="" required for numpy 1.25+ when choices are strings
mtcars['efficiency'] = np.select(conditions, choices, default="")

# Filter (like Stata's if condition)
print(mtcars[mtcars['cylinders'] == 6]['mpg'].mean())

# Drop observations
mtcars_clean = mtcars.dropna(subset=['mpg'])

# Keep only certain columns
mtcars_subset = mtcars[['mpg', 'horsepower', 'weight', 'cylinders']]

#===============================================================================
# PART 3: IMPORTING CSV DATA
#===============================================================================

# Import a CSV file
# data = pd.read_csv("mydata.csv")

# Common options:
# data = pd.read_csv("mydata.csv", header=0)  # First row is header
# data = pd.read_csv("mydata.csv", skiprows=1)  # Skip first row
# data = pd.read_csv("mydata.csv", encoding='utf-8')

# Read Stata files
# data = pd.read_stata("mydata.dta")

#===============================================================================
# PART 4: RESHAPING DATA
#===============================================================================

# Create example wide data
wide_data = pd.DataFrame({
    'id': [1, 2, 3],
    'income_2020': [50000, 60000, 45000],
    'income_2021': [52000, 61000, 47000],
    'income_2022': [54000, 63000, 48000]
})

# Look at wide format
print("Wide format:")
print(wide_data)

# Reshape from wide to long using melt
long_data = pd.melt(
    wide_data,
    id_vars=['id'],
    value_vars=['income_2020', 'income_2021', 'income_2022'],
    var_name='year',
    value_name='income'
)

# Clean up year column
long_data['year'] = long_data['year'].str.replace('income_', '').astype(int)

# Look at long format
print("\nLong format:")
print(long_data)

# Reshape back to wide (if needed)
wide_again = long_data.pivot(index='id', columns='year', values='income').reset_index()
wide_again.columns = ['id'] + [f'income_{y}' for y in wide_again.columns[1:]]

#===============================================================================
# PART 5: MERGING DATASETS
#===============================================================================

# Create master dataset (individuals)
individuals = pd.DataFrame({
    'person_id': [1, 2, 3, 4],
    'state': ['MA', 'MA', 'CA', 'NY'],
    'income': [50000, 60000, 70000, 55000]
})

# Create using dataset (state characteristics)
state_data = pd.DataFrame({
    'state': ['MA', 'CA', 'TX'],
    'min_wage': [15.00, 15.50, 7.25],
    'population': [7000000, 39500000, 29500000]
})

# Left join: keep all individuals, add state data where available
merged = individuals.merge(state_data, on='state', how='left', indicator=True)

# Check merge results
print("\nMerge results:")
print(merged['_merge'].value_counts())

# Check for unmatched (NY had no state data)
print("\nUnmatched observations:")
print(merged[merged['min_wage'].isna()])

# Inner join: keep only matched
merged_inner = individuals.merge(state_data, on='state', how='inner')

# View results
print("\nFinal merged data (inner join):")
print(merged_inner)

#===============================================================================
# CLEANUP
#===============================================================================

print("\nSession 1 script complete!")
