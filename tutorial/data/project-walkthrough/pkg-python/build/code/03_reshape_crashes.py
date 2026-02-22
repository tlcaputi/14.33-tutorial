"""
Build Script 03: Reshape Crashes
Reads collapsed crash data, pivots from long to wide format
(one row per state-year), and computes total crashes and fatal share.
"""
import os
from pathlib import Path

# Project root — main.py sets PROJECT_ROOT; fall back to relative path
ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

import pandas as pd

crashes = pd.read_csv(ROOT / "build" / "output" / "crashes_collapsed.csv")

crashes_wide = crashes.pivot_table(
    index=["state_fips", "year"],
    columns="severity",
    values="n_crashes",
    fill_value=0,
).reset_index()

crashes_wide.columns.name = None
crashes_wide = crashes_wide.rename(columns={
    "fatal":   "fatal_crashes",
    "serious": "serious_crashes",
})

crashes_wide["total_crashes"] = crashes_wide["fatal_crashes"] + crashes_wide["serious_crashes"]
crashes_wide["fatal_share"]   = crashes_wide["fatal_crashes"] / crashes_wide["total_crashes"]

crashes_wide.to_csv(ROOT / "build" / "output" / "crashes_state_year.csv", index=False)

print(f"  Rows after reshape: {len(crashes_wide):,}")
