"""
Build Script 04: Append Demographics
Reads annual demographic survey files for 1995-2015,
adds a year column to each, and appends them into one dataset.
"""
import os
from pathlib import Path

# Project root — main.py sets PROJECT_ROOT; fall back to relative path
ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

import pandas as pd

frames = []
for year in range(1995, 2016):
    path = ROOT / "data" / f"demographic_survey_{year}.csv"
    df = pd.read_csv(path)
    df["year"] = year
    frames.append(df)

demographics = pd.concat(frames, ignore_index=True)

demographics.to_csv(ROOT / "build" / "output" / "demographics_combined.csv", index=False)

print(f"  Rows after append: {len(demographics):,}")
