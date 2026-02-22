"""
Build Script 01: Filter Crashes
Reads raw crash data and keeps only fatal and serious crashes,
dropping minor crashes.
"""
import os
from pathlib import Path

# Project root — main.py sets PROJECT_ROOT; fall back to relative path
ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

import pandas as pd

crashes = pd.read_csv(ROOT / "data" / "crash_data.csv")

crashes = crashes[crashes["severity"].isin(["fatal", "serious"])]

crashes.to_csv(ROOT / "build" / "output" / "crashes_filtered.csv", index=False)

print(f"  Rows after filter: {len(crashes):,}")
