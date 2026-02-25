"""
Build Script 06: Merge Datasets
Merges crash, demographic, policy adoption, and state name
datasets into a single analysis panel.
"""
import os
from pathlib import Path

# Project root — main.py sets PROJECT_ROOT; fall back to relative path
ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

import numpy as np
import pandas as pd

crashes     = pd.read_csv(ROOT / "build" / "output" / "crashes_state_year.csv")
demo        = pd.read_csv(ROOT / "build" / "output" / "demographics_state_year.csv")
policy      = pd.read_csv(ROOT / "build" / "input" / "policy_adoptions.csv")
state_names = pd.read_csv(ROOT / "build" / "input" / "state_names.csv")

# Merge sequentially
panel = crashes.merge(demo,        on=["state_fips", "year"], how="inner")
panel = panel.merge(policy,        on="state_fips",           how="left")
panel = panel.merge(state_names,   on="state_fips",           how="left")

# Post-treatment indicator
panel["post_treated"] = (
    (panel["year"] >= panel["adoption_year"]) & panel["adoption_year"].notna()
).astype(int)

# Log population
panel["log_pop"] = np.log(panel["population"])

panel.to_csv(ROOT / "build" / "output" / "analysis_panel.csv", index=False)

print(f"  Rows in analysis panel: {len(panel):,}")
