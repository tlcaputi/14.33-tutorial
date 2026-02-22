"""
Generate synthetic demographic survey CSV files for the project walkthrough.

Reads state_demographics.dta to get target collapsed values, then generates
individual-level survey records that collapse back to those targets.

Output: 21 CSV files in demographic_survey/ (one per year, 1995-2015)

Each CSV has columns: state_fips, weight, income, urban
- state_fips: 1-51 (51 = DC, to be dropped during cleaning)
- weight: survey weight (rawsum to population)
- income: string like "$35,800" (teaches destring)
- urban: 0 or 1
"""

import pandas as pd
import numpy as np
from pathlib import Path

# Reproducibility
np.random.seed(14033)

# Paths
ROOT = Path(__file__).parent
OUTPUT_DIR = ROOT / "demographic_survey"
OUTPUT_DIR.mkdir(exist_ok=True)

# Read target values from state_demographics.dta
targets = pd.read_stata(ROOT / "state_demographics.dta")
print(f"Loaded targets: {len(targets)} rows, states {targets.state_fips.min()}-{targets.state_fips.max()}, years {targets.year.min()}-{targets.year.max()}")

# Parameters
N_PER_STATE = 200  # records per state per year
ALL_STATES = list(range(1, 52))  # 1-51 (51 = DC)
ALL_YEARS = list(range(1995, 2016))  # 1995-2015

# For years/states without targets, we need to extrapolate
# Targets exist for states 1-50, years 2000-2015
target_dict = {}
for _, row in targets.iterrows():
    target_dict[(int(row.state_fips), int(row.year))] = {
        'population': int(row.population),
        'median_income': float(row.median_income),
        'pct_urban': float(row.pct_urban),
    }


def get_target(state, year):
    """Get target values, extrapolating for missing state-years."""
    if (state, year) in target_dict:
        return target_dict[(state, year)]

    # State 51 (DC): use high-urban, high-income values
    if state == 51:
        base_pop = 580_000 + (year - 2000) * 5_000
        base_income = 52_000 + (year - 2000) * 800
        return {
            'population': max(550_000, base_pop),
            'median_income': max(48_000, base_income),
            'pct_urban': 0.98,
        }

    # Years 1995-1999: extrapolate backwards from 2000-2002 trend
    if year < 2000 and (state, 2000) in target_dict:
        t2000 = target_dict[(state, 2000)]
        t2002 = target_dict.get((state, 2002), t2000)

        # Annual growth rate from 2000 to 2002
        pop_growth = (t2002['population'] / t2000['population']) ** 0.5 if t2000['population'] > 0 else 1.0
        inc_growth = (t2002['median_income'] / t2000['median_income']) ** 0.5 if t2000['median_income'] > 0 else 1.0

        years_back = 2000 - year
        return {
            'population': int(t2000['population'] / (pop_growth ** years_back)),
            'median_income': t2000['median_income'] / (inc_growth ** years_back),
            'pct_urban': max(0.1, min(0.95, t2000['pct_urban'] - years_back * 0.003)),
        }

    # Fallback
    return {
        'population': 2_000_000,
        'median_income': 40_000,
        'pct_urban': 0.5,
    }


def format_income(value):
    """Format income as '$XX,XXX' string."""
    return f"${int(round(value)):,}"


def generate_state_year(state, year, target):
    """Generate N_PER_STATE individual records for one state-year."""
    n = N_PER_STATE
    pop = target['population']
    med_inc = target['median_income']
    pct_urb = target['pct_urban']

    # Weights: vary around population/N with some noise
    base_weight = pop / n
    weight_noise = np.random.lognormal(0, 0.3, n)
    weights = base_weight * weight_noise
    # Rescale so sum = population exactly
    weights = weights * (pop / weights.sum())

    # Urban: Bernoulli draws, then adjust to hit target weighted mean
    urban = np.random.binomial(1, pct_urb, n).astype(float)
    # Compute current weighted mean
    current_pct = np.average(urban, weights=weights)
    # Flip some values to get closer to target (iterative adjustment)
    for _ in range(50):
        diff = pct_urb - current_pct
        if abs(diff) < 0.005:
            break
        if diff > 0:
            # Need more 1s — flip a random 0 to 1
            zeros = np.where(urban == 0)[0]
            if len(zeros) > 0:
                idx = np.random.choice(zeros)
                urban[idx] = 1
        else:
            # Need fewer 1s — flip a random 1 to 0
            ones = np.where(urban == 1)[0]
            if len(ones) > 0:
                idx = np.random.choice(ones)
                urban[idx] = 0
        current_pct = np.average(urban, weights=weights)

    # Income: draw from lognormal, then shift to hit target weighted mean
    log_income = np.random.normal(np.log(med_inc) - 0.1, 0.4, n)
    income_raw = np.exp(log_income)
    # Adjust to hit target weighted mean
    current_mean = np.average(income_raw, weights=weights)
    income_raw = income_raw * (med_inc / current_mean)
    # Round to nearest 100
    income_raw = np.round(income_raw / 100) * 100
    # Ensure positive
    income_raw = np.maximum(income_raw, 10_000)

    # Format as "$XX,XXX" strings
    income_str = [format_income(v) for v in income_raw]

    return pd.DataFrame({
        'state_fips': state,
        'weight': np.round(weights, 1),
        'income': income_str,
        'urban': urban.astype(int),
    })


# Generate all files
for year in ALL_YEARS:
    frames = []
    for state in ALL_STATES:
        target = get_target(state, year)
        df = generate_state_year(state, year, target)
        frames.append(df)

    year_df = pd.concat(frames, ignore_index=True)
    outpath = OUTPUT_DIR / f"demographic_survey_{year}.csv"
    year_df.to_csv(outpath, index=False)
    print(f"  {outpath.name}: {len(year_df):,} rows, "
          f"{year_df.state_fips.nunique()} states")

print(f"\nDone. Generated {len(ALL_YEARS)} files in {OUTPUT_DIR}")
print(f"Total records: {N_PER_STATE * len(ALL_STATES) * len(ALL_YEARS):,}")
