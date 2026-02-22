"""
Build Script 02: Collapse Crashes
Reads filtered crash data and collapses to counts by
state, year, and severity.
"""
import os
from pathlib import Path

# Project root — main.py sets PROJECT_ROOT; fall back to relative path
ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

import pandas as pd

crashes = pd.read_csv(ROOT / "build" / "output" / "crashes_filtered.csv")

crashes_collapsed = (
    crashes
    .groupby(["state_fips", "year", "severity"])
    .size()
    .reset_index(name="n_crashes")
)

crashes_collapsed.to_csv(ROOT / "build" / "output" / "crashes_collapsed.csv", index=False)

print(f"  Rows after collapse: {len(crashes_collapsed):,}")
