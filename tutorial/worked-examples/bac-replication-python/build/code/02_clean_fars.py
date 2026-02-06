# 02_clean_fars.py - Clean and aggregate FARS data to state-year level

import pandas as pd
import numpy as np

# State FIPS to name mapping
STATE_NAMES = {
    '01': 'Alabama', '02': 'Alaska', '04': 'Arizona', '05': 'Arkansas',
    '06': 'California', '08': 'Colorado', '09': 'Connecticut', '10': 'Delaware',
    '12': 'Florida', '13': 'Georgia', '15': 'Hawaii', '16': 'Idaho',
    '17': 'Illinois', '18': 'Indiana', '19': 'Iowa', '20': 'Kansas',
    '21': 'Kentucky', '22': 'Louisiana', '23': 'Maine', '24': 'Maryland',
    '25': 'Massachusetts', '26': 'Michigan', '27': 'Minnesota', '28': 'Mississippi',
    '29': 'Missouri', '30': 'Montana', '31': 'Nebraska', '32': 'Nevada',
    '33': 'New Hampshire', '34': 'New Jersey', '35': 'New Mexico', '36': 'New York',
    '37': 'North Carolina', '38': 'North Dakota', '39': 'Ohio', '40': 'Oklahoma',
    '41': 'Oregon', '42': 'Pennsylvania', '44': 'Rhode Island', '45': 'South Carolina',
    '46': 'South Dakota', '47': 'Tennessee', '48': 'Texas', '49': 'Utah',
    '50': 'Vermont', '51': 'Virginia', '53': 'Washington', '54': 'West Virginia',
    '55': 'Wisconsin', '56': 'Wyoming'
}

print("  Loading raw FARS data...")
fars_df = pd.read_parquet(BUILD / "output" / "fars_raw.parquet")
fars_df['state_fips'] = fars_df['state_fips'].astype(str).str.zfill(2)

print("  Aggregating to state-year level...")

# Aggregate: count fatalities and hit-run fatalities by state-year
# HR fatalities = sum of fatalities in crashes where hit_run=1
state_year = fars_df.groupby(['state_fips', 'year']).apply(
    lambda x: pd.Series({
        'total_fatalities': x['fatalities'].sum(),
        'hr_fatalities': (x['fatalities'] * x['hit_run']).sum()
    })
).reset_index()

state_year['nhr_fatalities'] = state_year['total_fatalities'] - state_year['hr_fatalities']
state_year['state_name'] = state_year['state_fips'].map(STATE_NAMES)

# Keep only 50 states (exclude DC, territories)
state_year = state_year[state_year['state_fips'].isin(STATE_NAMES.keys())].copy()

# Create complete panel (ensure all state-years are present)
all_states = list(STATE_NAMES.keys())
all_years = list(range(1982, 2009))
complete_panel = pd.DataFrame([(s, y) for s in all_states for y in all_years],
                              columns=['state_fips', 'year'])
complete_panel['state_name'] = complete_panel['state_fips'].map(STATE_NAMES)

# Merge and fill zeros for missing state-years
state_year = complete_panel.merge(state_year, on=['state_fips', 'year', 'state_name'], how='left')
state_year = state_year.fillna({'total_fatalities': 0, 'hr_fatalities': 0, 'nhr_fatalities': 0})

# Convert to int
for col in ['total_fatalities', 'hr_fatalities', 'nhr_fatalities']:
    state_year[col] = state_year[col].astype(int)

# Sort
state_year = state_year.sort_values(['state_fips', 'year']).reset_index(drop=True)

# Save
state_year.to_parquet(BUILD / "output" / "state_year_crashes.parquet")
print(f"  Created state-year panel: {len(state_year)} observations")
print(f"  Total fatalities: {state_year['total_fatalities'].sum():,}")
print(f"  HR fatalities: {state_year['hr_fatalities'].sum():,} ({state_year['hr_fatalities'].sum()/state_year['total_fatalities'].sum()*100:.1f}%)")
