"""
Build Script 05: Collapse Demographics
Reads combined demographic data, applies cleaning and sample
restrictions, then produces population-weighted state-year aggregates.
"""
import os
from pathlib import Path

# Project root — main.py sets PROJECT_ROOT; fall back to relative path
ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

import numpy as np
import pandas as pd

demo = pd.read_csv(ROOT / "build" / "output" / "demographics_combined.csv")

# Drop DC and pre-2000 observations
demo = demo[demo["state_fips"] != 51]
demo = demo[demo["year"] >= 2000]

# Clean income: strip "$" and "," then convert to float
demo["income"] = (
    demo["income"]
    .astype(str)
    .str.replace("$", "", regex=False)
    .str.replace(",", "", regex=False)
    .astype(float)
)

# Weighted collapse
def weighted_agg(g):
    w = g["weight"]
    return pd.Series({
        "population":    w.sum(),
        "median_income": np.average(g["income"], weights=w),
        "pct_urban":     np.average(g["urban"],  weights=w),
    })

demo_collapsed = (
    demo
    .groupby(["state_fips", "year"])
    .apply(weighted_agg)
    .reset_index()
)

assert len(demo_collapsed) == 800, (
    f"Expected 800 rows, got {len(demo_collapsed)}"
)

demo_collapsed.to_csv(ROOT / "build" / "output" / "demographics_state_year.csv", index=False)

print(f"  Rows after collapse: {len(demo_collapsed):,}")
