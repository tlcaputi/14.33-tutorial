# 01_download_fars.py - Download FARS data (1982-2008)
# This script downloads real FARS crash data from NHTSA
# Run time: ~10-15 minutes depending on internet speed

import pandas as pd
import requests
import zipfile
import io
from pathlib import Path

# Paths are defined in main.py and available via exec()
INPUT_DIR = BUILD / "input" / "fars"
INPUT_DIR.mkdir(parents=True, exist_ok=True)

# Cache file - if exists, skip download
CACHE_FILE = BUILD / "output" / "fars_raw.parquet"
if CACHE_FILE.exists():
    print("  FARS data already downloaded, loading from cache...")
else:
    print("  Downloading FARS data from NHTSA (1982-2008)...")
    print("  This will take ~10-15 minutes...")

    all_data = []

    for year in range(1982, 2009):
        print(f"    Processing {year}...", end=" ", flush=True)

        # Try different URL formats (NHTSA has changed URLs over time)
        urls_to_try = [
            f"https://static.nhtsa.gov/nhtsa/downloads/FARS/{year}/National/FARS{year}NationalCSV.zip",
            f"https://static.nhtsa.gov/nhtsa/downloads/FARS/{year}/FARS{year}NationalCSV.zip",
        ]

        response = None
        for url in urls_to_try:
            try:
                response = requests.get(url, timeout=300)
                if response.status_code == 200:
                    break
            except:
                continue

        if response is None or response.status_code != 200:
            print(f"SKIPPED (couldn't download)")
            continue

        try:
            with zipfile.ZipFile(io.BytesIO(response.content)) as z:
                file_list = z.namelist()

                # Find accident and vehicle files
                accident_file = None
                vehicle_file = None

                for name in file_list:
                    name_lower = name.lower()
                    if name.endswith('.csv') or name.endswith('.CSV'):
                        if accident_file is None:
                            if 'accident' in name_lower or name_lower.startswith('acc'):
                                accident_file = name
                        if vehicle_file is None:
                            if 'vehicle' in name_lower:
                                vehicle_file = name

                if accident_file is None:
                    print(f"no accident file")
                    continue

                # Read accident file
                with z.open(accident_file) as f:
                    acc_df = pd.read_csv(f, encoding='latin-1', low_memory=False)
                acc_df.columns = acc_df.columns.str.upper()

                # Get state and case number
                if 'STATE' in acc_df.columns:
                    acc_df['state_fips'] = acc_df['STATE'].astype(int).astype(str).str.zfill(2)
                if 'ST_CASE' in acc_df.columns:
                    acc_df['st_case'] = acc_df['ST_CASE']
                else:
                    acc_df['st_case'] = acc_df.index

                # Get fatality count
                if 'FATALS' in acc_df.columns:
                    acc_df['fatalities'] = acc_df['FATALS']
                else:
                    acc_df['fatalities'] = 1

                acc_df['year'] = year

                # Read vehicle file for hit-run indicator
                if vehicle_file:
                    with z.open(vehicle_file) as f:
                        veh_df = pd.read_csv(f, encoding='latin-1', low_memory=False)
                    veh_df.columns = veh_df.columns.str.upper()

                    if 'ST_CASE' in veh_df.columns:
                        veh_df['st_case'] = veh_df['ST_CASE']

                    # Find hit-run column (varies by year)
                    hit_run_col = None
                    for col in veh_df.columns:
                        if 'HIT' in col and 'RUN' in col:
                            hit_run_col = col
                            break

                    if hit_run_col:
                        # FARS HIT_RUN codes: 1-4 are all "Yes" categories
                        veh_df['hit_run'] = veh_df[hit_run_col].isin([1, 2, 3, 4, '1', '2', '3', '4']).astype(int)
                        hr_by_crash = veh_df.groupby('st_case')['hit_run'].max().reset_index()
                        acc_df = acc_df.merge(hr_by_crash, on='st_case', how='left')
                        acc_df['hit_run'] = acc_df['hit_run'].fillna(0).astype(int)
                    else:
                        acc_df['hit_run'] = 0
                else:
                    acc_df['hit_run'] = 0

                all_data.append(acc_df[['state_fips', 'year', 'fatalities', 'hit_run']].copy())
                n_hr = acc_df['hit_run'].sum()
                print(f"{len(acc_df):,} crashes, {n_hr:,} hit-run")

        except Exception as e:
            print(f"ERROR: {e}")

    # Combine all years
    if all_data:
        fars_df = pd.concat(all_data, ignore_index=True)

        # Save raw data
        (BUILD / "output").mkdir(parents=True, exist_ok=True)
        fars_df.to_parquet(CACHE_FILE)
        print(f"  Saved {len(fars_df):,} crash records to {CACHE_FILE}")
    else:
        raise RuntimeError("Could not download any FARS data!")

print("  FARS download complete.")
