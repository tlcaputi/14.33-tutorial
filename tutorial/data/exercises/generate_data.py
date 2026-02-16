"""
Generate synthetic datasets for 14.33 in-class Stata exercises.

Exercise 1: "Did State Job Training Programs Reduce Unemployment?"
  - Non-staggered DiD: 50 states x 10 years (2005-2014)
  - 20 states adopt job training in 2010
  - True treatment effect: -1.5 pp on unemployment

Exercise 2: "The Effect of State Minimum Wage Increases on Teen Employment"
  - Staggered DiD: 50 states x 15 years (2005-2019)
  - ~15 states increase min wage in different years (2010, 2012, 2014, 2016)
  - True treatment effect: -0.8 pp on teen employment rate

All random seeds fixed for reproducibility.
"""

import numpy as np
import pandas as pd
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ============================================================
# EXERCISE 1: Job Training & Unemployment
# ============================================================

def generate_exercise1():
    rng = np.random.default_rng(seed=1433)

    n_states = 50
    years = list(range(2005, 2015))  # 2005-2014
    n_years = len(years)

    state_names = [
        "Alabama", "Alaska", "Arizona", "Arkansas", "California",
        "Colorado", "Connecticut", "Delaware", "Florida", "Georgia",
        "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa",
        "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
        "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
        "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
        "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio",
        "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
        "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
        "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"
    ]

    state_ids = list(range(1, n_states + 1))

    # 20 treated states (first 20 alphabetically for simplicity)
    treated_states = set(range(1, 21))

    # --- training_programs.dta ---
    training_df = pd.DataFrame({
        "state_id": state_ids,
        "state_name": state_names,
        "has_program": [1 if s in treated_states else 0 for s in state_ids]
    })
    training_df.to_stata(
        os.path.join(OUTPUT_DIR, "exercise1", "data", "training_programs.dta"),
        write_index=False
    )

    # --- unemployment.dta ---
    # State fixed effects
    state_fe = {s: rng.normal(6.0, 1.5) for s in state_ids}
    # Year fixed effects (trending down slightly)
    year_fe = {y: -0.1 * (y - 2005) + rng.normal(0, 0.3) for y in years}

    unemp_rows = []
    for s in state_ids:
        for y in years:
            treated = 1 if (s in treated_states and y >= 2010) else 0
            rate = (state_fe[s] + year_fe[y]
                    + (-1.5 * treated)  # true treatment effect
                    + rng.normal(0, 0.5))
            rate = np.clip(rate, 1.0, 15.0)
            unemp_rows.append({
                "state_id": s,
                "year": y,
                "state_name": state_names[s - 1],
                "unemployment_rate": round(rate, 2)
            })

    unemp_df = pd.DataFrame(unemp_rows)
    unemp_df.to_stata(
        os.path.join(OUTPUT_DIR, "exercise1", "data", "unemployment.dta"),
        write_index=False
    )

    # --- worker_survey.dta ---
    # ~500 workers per state-year = 25,000 per year, but we want ~25,000 total
    # So ~50 workers per state-year
    survey_rows = []
    pid = 1
    for s in state_ids:
        for y in years:
            n_workers = rng.integers(45, 56)  # 45-55 workers per state-year
            for _ in range(n_workers):
                age = int(rng.integers(22, 66))
                female = int(rng.integers(0, 2))
                college = int(rng.binomial(1, 0.35))
                # Income depends on state, year, education
                base_income = 30000 + state_fe[s] * 2000 + (y - 2005) * 500
                income = (base_income
                          + college * 15000
                          + (age - 22) * 300
                          + rng.normal(0, 8000))
                income = max(10000, round(income, 2))
                survey_rows.append({
                    "person_id": pid,
                    "state_id": s,
                    "year": y,
                    "age": age,
                    "female": female,
                    "college": college,
                    "income": round(income, 2)
                })
                pid += 1

    survey_df = pd.DataFrame(survey_rows)
    survey_df.to_stata(
        os.path.join(OUTPUT_DIR, "exercise1", "data", "worker_survey.dta"),
        write_index=False
    )

    print(f"Exercise 1: unemployment.dta ({len(unemp_df)} obs), "
          f"worker_survey.dta ({len(survey_df)} obs), "
          f"training_programs.dta ({len(training_df)} obs)")


# ============================================================
# EXERCISE 2: Minimum Wage & Teen Employment
# ============================================================

def generate_exercise2():
    rng = np.random.default_rng(seed=14332)

    n_states = 50
    years = list(range(2005, 2020))  # 2005-2019
    n_years = len(years)

    state_names = [
        "Alabama", "Alaska", "Arizona", "Arkansas", "California",
        "Colorado", "Connecticut", "Delaware", "Florida", "Georgia",
        "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa",
        "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
        "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
        "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
        "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio",
        "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
        "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
        "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"
    ]

    state_ids = list(range(1, n_states + 1))

    # Staggered treatment: ~15 states treated at different times
    # 4 states in 2010, 4 in 2012, 4 in 2014, 3 in 2016
    mw_increase_year = {}
    treat_2010 = [5, 10, 22, 32]    # CA, GA, MS, NY
    treat_2012 = [7, 15, 21, 47]    # CT, IA, MA, WA
    treat_2014 = [6, 23, 37, 45]    # CO, MN, OR, VT
    treat_2016 = [20, 31, 38]       # MD, NM, PA

    for s in treat_2010:
        mw_increase_year[s] = 2010
    for s in treat_2012:
        mw_increase_year[s] = 2012
    for s in treat_2014:
        mw_increase_year[s] = 2014
    for s in treat_2016:
        mw_increase_year[s] = 2016

    # --- minimum_wage_laws.dta ---
    mw_df = pd.DataFrame({
        "state_id": state_ids,
        "state_name": state_names,
        "mw_increase_year": [mw_increase_year.get(s, 0) for s in state_ids]
    })
    mw_df.to_stata(
        os.path.join(OUTPUT_DIR, "exercise2", "data", "minimum_wage_laws.dta"),
        write_index=False
    )

    # --- employment_wide.csv ---
    # State fixed effects for teen employment
    state_fe = {s: rng.normal(45.0, 5.0) for s in state_ids}
    # Year effects (slight upward trend)
    year_fe = {y: 0.2 * (y - 2005) + rng.normal(0, 0.3) for y in years}

    wide_rows = []
    for s in state_ids:
        row = {"state_id": s, "state_name": state_names[s - 1]}
        for y in years:
            treat_yr = mw_increase_year.get(s, 0)
            treated = 1 if (treat_yr > 0 and y >= treat_yr) else 0
            emp_rate = (state_fe[s] + year_fe[y]
                        + (-0.8 * treated)  # true treatment effect
                        + rng.normal(0, 0.8))
            emp_rate = np.clip(emp_rate, 20.0, 70.0)
            row[f"teen_emp_{y}"] = round(emp_rate, 2)
        wide_rows.append(row)

    wide_df = pd.DataFrame(wide_rows)
    wide_df.to_csv(
        os.path.join(OUTPUT_DIR, "employment_wide.csv"),
        index=False
    )

    # --- business_registry.dta ---
    # ~1000 businesses per state, observed each year = too many
    # ~67 businesses per state-year = ~50,000 total
    biz_rows = []
    bid = 1
    industry_codes = list(range(11, 24))  # NAICS-like 2-digit codes
    for s in state_ids:
        for y in years:
            n_biz = rng.integers(60, 75)
            for _ in range(n_biz):
                n_emp = max(1, int(rng.lognormal(2.5, 1.0)))
                ind = int(rng.choice(industry_codes))
                biz_rows.append({
                    "business_id": bid,
                    "state_id": s,
                    "year": y,
                    "num_employees": n_emp,
                    "industry_code": ind
                })
                bid += 1

    biz_df = pd.DataFrame(biz_rows)
    biz_df.to_stata(
        os.path.join(OUTPUT_DIR, "exercise2", "data", "business_registry.dta"),
        write_index=False
    )

    print(f"Exercise 2: employment_wide.csv ({len(wide_df)} obs wide), "
          f"business_registry.dta ({len(biz_df)} obs), "
          f"minimum_wage_laws.dta ({len(mw_df)} obs)")


if __name__ == "__main__":
    # Create output directories
    for d in [
        os.path.join(OUTPUT_DIR, "exercise1", "data"),
        os.path.join(OUTPUT_DIR, "exercise1", "solutions"),
        os.path.join(OUTPUT_DIR, "exercise2", "data"),
        os.path.join(OUTPUT_DIR, "exercise2", "solutions"),
    ]:
        os.makedirs(d, exist_ok=True)

    generate_exercise1()
    generate_exercise2()
    print("Done! All datasets generated.")
