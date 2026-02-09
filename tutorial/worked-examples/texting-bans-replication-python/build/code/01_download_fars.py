# 01_download_fars.py — Download FARS accident data (2007-2022)
# =============================================================================
# Downloads ZIP files from NHTSA, extracts accident.csv for each year,
# normalizes column names (uppercase, strip BOM), keeps STATE/YEAR/MONTH/FATALS,
# and saves a combined parquet file.
# Skips download if cached parquet exists.
# =============================================================================

import pandas as pd
import requests
import zipfile
import io
from pathlib import Path

FARS_YEARS = range(2007, 2023)
KEEP_COLS = ["STATE", "YEAR", "MONTH", "FATALS"]
CACHE_FILE = BUILD / "output" / "fars_raw.parquet"
RAW_DIR = BUILD / "output" / "fars_csvs"


def read_fars_csv(path, year):
    """Read a FARS CSV, normalizing column names across year-to-year variations."""
    # Try utf-8-sig first (handles BOM), fall back to latin-1
    try:
        df = pd.read_csv(path, encoding="utf-8-sig", low_memory=False)
    except UnicodeDecodeError:
        df = pd.read_csv(path, encoding="latin-1", low_memory=False)
        # Strip latin-1-decoded BOM if present
        df.columns = df.columns.str.replace("Ï»¿", "", regex=False)

    df.columns = df.columns.str.strip().str.upper()

    # Some older FARS files don't have YEAR — add from filename
    if "YEAR" not in df.columns:
        df["YEAR"] = year

    # Select only the columns we need
    for col in KEEP_COLS:
        if col not in df.columns:
            raise ValueError(f"Column {col} not found in {path}. Available: {list(df.columns[:20])}")

    return df[KEEP_COLS].copy()


if CACHE_FILE.exists():
    print("    Cached fars_raw.parquet found — skipping download.")
    fars_raw = pd.read_parquet(CACHE_FILE)
else:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    frames = []

    for year in FARS_YEARS:
        csv_path = RAW_DIR / f"accident_{year}.csv"

        if csv_path.exists():
            print(f"    {year}: using cached CSV")
        else:
            url = (f"https://static.nhtsa.gov/nhtsa/downloads/FARS/"
                   f"{year}/National/FARS{year}NationalCSV.zip")
            print(f"    {year}: downloading...", end=" ", flush=True)
            r = requests.get(url, timeout=120)
            r.raise_for_status()

            with zipfile.ZipFile(io.BytesIO(r.content)) as z:
                accident_name = [f for f in z.namelist()
                                 if f.lower().endswith("accident.csv")][0]
                with z.open(accident_name) as src:
                    raw_bytes = src.read()

            csv_path.write_bytes(raw_bytes)
            print("OK")

        df = read_fars_csv(csv_path, year)
        frames.append(df)

    fars_raw = pd.concat(frames, ignore_index=True)
    fars_raw.columns = fars_raw.columns.str.lower()
    fars_raw.to_parquet(CACHE_FILE, index=False)
    print(f"    Saved {len(fars_raw):,} rows to fars_raw.parquet")
