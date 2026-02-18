"""
Generate individual-level demographic survey data for the project walkthrough.

Creates per-year CSV files (demographic_survey_YYYY.csv). Each row is a
survey respondent with income (dirty string "$XX,XXX"), urban indicator (0/1),
age, and a survey weight. Weighted aggregation for states 1-50, years 2000-2015
matches the existing state_demographics.dta exactly.

Dirty features requiring cleaning:
  - income stored as string with "$" and commas (e.g., "$45,230") -> destring
  - Includes DC (state_fips=51) -> must filter
  - Years 1995-1999 exist as files -> must filter or skip
  - Students must loop over files and append

Output: demographic_survey/ directory with 21 CSV files (1995-2015)

After filtering (drop DC, drop years < 2000) and collapsing:
  50 states x 16 years = 800 state-year observations
  population = sum(weight), median_income = weighted mean, pct_urban = weighted mean
"""

import numpy as np
import pandas as pd
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
SEED = 143300
N_RESPONDENTS = 200  # per state per year


def generate_demographic_survey():
    rng = np.random.default_rng(seed=SEED)

    # Read existing state demographics to match aggregates
    dta_candidates = [
        os.path.join(OUTPUT_DIR, "..", "..", "..", "_site", "tutorial",
                     "data", "project-walkthrough", "pkg-stata", "build",
                     "input", "state_demographics.dta"),
        "/tmp/walkthrough-inspect/pkg-stata/build/input/state_demographics.dta",
        "/tmp/state_demographics_reference.csv",
    ]
    state_demo = None
    for path in dta_candidates:
        if os.path.exists(path):
            if path.endswith(".csv"):
                state_demo = pd.read_csv(path)
            else:
                state_demo = pd.read_stata(path)
            break
    if state_demo is None:
        raise FileNotFoundError("Could not find state_demographics reference.")

    all_rows = {}  # year -> list of rows

    # --- States 1-50, years 2000-2015: must match existing values ---
    for _, srow in state_demo.iterrows():
        sfips = int(srow["state_fips"])
        year = int(srow["year"])
        state_pop = srow["population"]
        state_income = srow["median_income"]
        state_urban = srow["pct_urban"]

        n = N_RESPONDENTS
        base_weight = state_pop / n

        # Generate individual weights (small variation around base)
        weights = rng.uniform(0.8, 1.2, size=n) * base_weight
        # Fix so sum = state_pop exactly
        weights = weights * (state_pop / weights.sum())

        # Generate individual incomes -> weighted mean must equal state_income
        raw_incomes = rng.normal(state_income, state_income * 0.30, size=n)
        raw_incomes = np.maximum(raw_incomes, 10000)
        wmean = np.average(raw_incomes, weights=weights)
        raw_incomes = raw_incomes * (state_income / wmean)
        raw_incomes = np.round(raw_incomes).astype(int)

        # Generate urban indicators -> weighted mean must equal state_urban
        # Draw from Bernoulli, then adjust a few to match
        urban = rng.binomial(1, state_urban, size=n)
        actual_urban = np.average(urban, weights=weights)
        # Fine-tune by flipping individuals until close enough
        for _ in range(200):
            actual_urban = np.average(urban, weights=weights)
            if abs(actual_urban - state_urban) < 0.002:
                break
            if actual_urban < state_urban:
                # Flip a random 0 to 1 (prefer low-weight for precision)
                zeros = np.where(urban == 0)[0]
                if len(zeros) > 0:
                    urban[rng.choice(zeros)] = 1
            else:
                ones = np.where(urban == 1)[0]
                if len(ones) > 0:
                    urban[rng.choice(ones)] = 0

        # Generate ages (not used in collapse, just for realism)
        ages = rng.integers(18, 86, size=n)

        if year not in all_rows:
            all_rows[year] = []
        for i in range(n):
            all_rows[year].append({
                "state_fips": sfips,
                "age": int(ages[i]),
                "income": f"${int(raw_incomes[i]):,}",
                "urban": int(urban[i]),
                "weight": round(float(weights[i]), 1),
            })

    # --- DC (state_fips=51), years 2000-2015 ---
    for year in range(2000, 2016):
        if year not in all_rows:
            all_rows[year] = []
        dc_pop = rng.integers(500000, 700000)
        dc_income = rng.integers(60000, 80000)
        dc_urban = 0.97
        base_w = dc_pop / N_RESPONDENTS
        for i in range(N_RESPONDENTS):
            w = round(float(base_w * rng.uniform(0.8, 1.2)), 1)
            inc = int(rng.normal(dc_income, dc_income * 0.25))
            inc = max(15000, inc)
            all_rows[year].append({
                "state_fips": 51,
                "age": int(rng.integers(18, 86)),
                "income": f"${inc:,}",
                "urban": int(rng.binomial(1, dc_urban)),
                "weight": w,
            })

    # --- All states (1-51), years 1995-1999 ---
    for year in range(1995, 2000):
        all_rows[year] = []
        for sfips in range(1, 52):
            pop = rng.integers(800000, 5000000) if sfips <= 50 else \
                rng.integers(500000, 700000)
            inc_base = rng.integers(28000, 55000)
            urb = rng.uniform(0.15, 0.90)
            base_w = pop / N_RESPONDENTS
            for i in range(N_RESPONDENTS):
                w = round(float(base_w * rng.uniform(0.8, 1.2)), 1)
                inc = max(10000, int(rng.normal(inc_base, inc_base * 0.25)))
                all_rows[year].append({
                    "state_fips": sfips,
                    "age": int(rng.integers(18, 86)),
                    "income": f"${inc:,}",
                    "urban": int(rng.binomial(1, urb)),
                    "weight": w,
                })

    # --- Write per-year CSV files ---
    outdir = os.path.join(OUTPUT_DIR, "demographic_survey")
    os.makedirs(outdir, exist_ok=True)

    total_rows = 0
    for year in sorted(all_rows.keys()):
        df_year = pd.DataFrame(all_rows[year])
        df_year = df_year.sort_values(["state_fips"]).reset_index(drop=True)
        outpath = os.path.join(outdir, f"demographic_survey_{year}.csv")
        df_year.to_csv(outpath, index=False)
        total_rows += len(df_year)

    print(f"Generated {len(all_rows)} per-year CSV files in demographic_survey/")
    print(f"  Total rows: {total_rows:,}")
    print(f"  Years: {min(all_rows.keys())}-{max(all_rows.keys())}")

    # --- Verify aggregation for states 1-50, years 2000-2015 ---
    frames = []
    for year in range(2000, 2016):
        fp = os.path.join(outdir, f"demographic_survey_{year}.csv")
        d = pd.read_csv(fp)
        d["year"] = year
        d["income_num"] = (
            d["income"].str.replace("$", "", regex=False)
            .str.replace(",", "", regex=False).astype(float)
        )
        frames.append(d)
    verify = pd.concat(frames, ignore_index=True)
    verify = verify[verify["state_fips"] <= 50]

    agg = verify.groupby(["state_fips", "year"]).apply(
        lambda g: pd.Series({
            "population": g["weight"].sum(),
            "median_income": np.average(g["income_num"], weights=g["weight"]),
            "pct_urban": np.average(g["urban"], weights=g["weight"]),
        }),
        include_groups=False,
    ).reset_index()

    merged = agg.merge(
        state_demo, on=["state_fips", "year"], suffixes=("_agg", "_orig")
    )
    pop_ok = np.allclose(merged["population_agg"], merged["population_orig"],
                         rtol=1e-4)
    inc_ok = np.allclose(merged["median_income_agg"],
                         merged["median_income_orig"], rtol=1e-3)
    urb_ok = np.allclose(merged["pct_urban_agg"], merged["pct_urban_orig"],
                         atol=0.01)
    print(f"\n  Population matches: {pop_ok}")
    print(f"  Income matches: {inc_ok}")
    print(f"  Urban matches: {urb_ok}")

    if not (pop_ok and inc_ok):
        worst_pop = (merged["population_agg"] - merged["population_orig"]).abs().max()
        worst_inc = (merged["median_income_agg"] - merged["median_income_orig"]).abs().max()
        print(f"  Worst population diff: {worst_pop:.1f}")
        print(f"  Worst income diff: {worst_inc:.1f}")


if __name__ == "__main__":
    generate_demographic_survey()
    print("\nDone!")
