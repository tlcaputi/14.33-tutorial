# 02_clean_fars.py — Aggregate FARS data to state-year level
# =============================================================================
# Loads the raw crash-level data and collapses to state-year totals:
#   - fatalities: sum of FATALS
#   - n_crashes:  count of fatal crashes
# =============================================================================

import pandas as pd

fars_raw = pd.read_parquet(BUILD / "output" / "fars_raw.parquet")

state_year = (fars_raw
    .groupby(["state", "year"])
    .agg(fatalities=("fatals", "sum"),
         n_crashes=("fatals", "count"))
    .reset_index())

# Quick sanity check
n_states = state_year["state"].nunique()
n_years = state_year["year"].nunique()
print(f"    {n_states} states × {n_years} years = {len(state_year)} rows")
print(f"    Mean annual fatalities per state: {state_year['fatalities'].mean():.0f}")

state_year.to_parquet(BUILD / "output" / "state_year_fatalities.parquet", index=False)
