# 03_merge_controls.py — Merge policy dates and economic controls
# =============================================================================
# 1. Merge state-year fatalities with texting_ban_dates.csv
# 2. Create treatment variables (ever_treated, treated, event_time)
# 3. Download state unemployment and per-capita income from FRED
# 4. Save analysis-ready dataset
# =============================================================================

import pandas as pd
import numpy as np
import time

# ── Load data ────────────────────────────────────────────────
state_year = pd.read_parquet(BUILD / "output" / "state_year_fatalities.parquet")
policy = pd.read_csv(ROOT / "texting_ban_dates.csv", na_values=["", "NA", "."])

# ── Merge and create treatment variables ─────────────────────
analysis_data = state_year.merge(policy, on="state", how="left")

analysis_data["ever_treated"] = analysis_data["texting_ban_year"].notna()
analysis_data["treated"] = (analysis_data["ever_treated"] &
                            (analysis_data["year"] >= analysis_data["texting_ban_year"]))
analysis_data["event_time"] = np.where(
    analysis_data["texting_ban_year"].isna(),
    -1000,
    analysis_data["year"] - analysis_data["texting_ban_year"]
).astype(int)

print(f"    {analysis_data['ever_treated'].sum()} treated obs, "
      f"{(~analysis_data['ever_treated']).sum()} never-treated obs")

# ── Download FRED controls ───────────────────────────────────
state_codes = [
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
    "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
    "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
]
state_fips = [
     1,  2,  4,  5,  6,  8,  9, 10, 12, 13,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
    25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
    35, 36, 37, 38, 39, 40, 41, 42, 44, 45,
    46, 47, 48, 49, 50, 51, 53, 54, 55, 56
]

import requests

def download_fred_series(series_suffix, value_name):
    """Download a FRED series for all 50 states."""
    frames = []
    for st, fips in zip(state_codes, state_fips):
        series_id = f"{st}{series_suffix}"
        url = f"https://fred.stlouisfed.org/graph/fredgraph.csv?id={series_id}"
        try:
            df = pd.read_csv(url)
            # FRED CSVs have 2 columns: date column + value column
            # Names vary (DATE vs observation_date, ALUR vs value)
            df.columns = ["date", value_name]
            df["date"] = pd.to_datetime(df["date"])
            df[value_name] = pd.to_numeric(df[value_name], errors="coerce")
            df["year"] = df["date"].dt.year
            df = (df.query("2007 <= year <= 2022")
                  .groupby("year")[value_name].mean()
                  .reset_index())
            df["state"] = fips
            frames.append(df)
        except Exception:
            pass
        time.sleep(0.3)  # be polite to FRED
    return pd.concat(frames, ignore_index=True) if frames else pd.DataFrame()

print("    Downloading unemployment from FRED...", flush=True)
all_unemp = download_fred_series("UR", "unemployment")
print(f"    Got unemployment for {all_unemp['state'].nunique()} states")

print("    Downloading per-capita income from FRED...", flush=True)
all_income = download_fred_series("PCPI", "income")
print(f"    Got income for {all_income['state'].nunique()} states")

# ── Merge controls ───────────────────────────────────────────
analysis_data = (analysis_data
    .merge(all_unemp, on=["state", "year"], how="left")
    .merge(all_income, on=["state", "year"], how="left"))

# Drop DC (FIPS 11) — not in FARS consistently
analysis_data = analysis_data[analysis_data["state"] != 11].copy()

print(f"    Final dataset: {len(analysis_data)} rows, "
      f"{analysis_data.columns.tolist()}")

analysis_data.to_parquet(BUILD / "output" / "analysis_data.parquet", index=False)
