# 03_merge_controls.py - Merge BAC dates, policy controls, and economic data

import pandas as pd
import numpy as np

# =============================================================================
# BAC Adoption Dates (from APIS)
# =============================================================================
BAC_DATES = {
    '01': 1995, '02': 2001, '04': 2001, '05': 2001, '06': 1990, '08': 2004,
    '09': 2002, '10': 2004, '12': 1994, '13': 2001, '15': 1995, '16': 1997,
    '17': 1997, '18': 2001, '19': 2003, '20': 1993, '21': 2000, '22': 2003,
    '23': 1988, '24': 2001, '25': 2003, '26': 2003, '27': 2005, '28': 2002,
    '29': 2001, '30': 2003, '31': 2001, '32': 2003, '33': 1994, '34': 2004,
    '35': 1994, '36': 2003, '37': 1993, '38': 2003, '39': 2003, '40': 2001,
    '41': 1983, '42': 2003, '44': 2000, '45': 2003, '46': 2002, '47': 2003,
    '48': 1999, '49': 1983, '50': 1991, '51': 1994, '53': 1999, '54': 2004,
    '55': 2003, '56': 2002
}

# =============================================================================
# Policy Controls - Adoption dates (year, month)
# Sources: NHTSA, IIHS, APIS
# =============================================================================

# ALR (Administrative License Revocation)
ALR_ADOPTION = {
    '27': (1976, 1), '54': (1981, 1), '35': (1984, 1), '32': (1983, 7),
    '16': (1984, 7), '30': (1984, 10), '08': (1985, 7), '19': (1986, 1),
    '49': (1986, 7), '06': (1990, 1), '53': (1988, 1), '23': (1988, 1),
    '50': (1989, 7), '41': (1989, 1), '04': (1990, 1), '17': (1986, 1),
    '20': (1988, 7), '31': (1989, 1), '37': (1990, 10), '55': (1988, 1),
    '15': (1990, 1), '02': (1989, 1), '12': (1990, 1), '13': (1991, 7),
    '26': (1993, 10), '39': (1993, 7), '48': (1993, 9), '51': (1995, 7),
    '18': (1996, 7), '01': (1996, 7), '45': (1998, 7), '05': (1997, 8),
    '24': (1997, 10), '47': (1997, 7), '33': (1993, 1), '44': (1994, 7),
    '10': (1996, 1), '34': (1994, 1), '22': (1995, 8), '28': (1995, 7),
    '40': (1997, 11), '36': (1994, 11), '09': (1995, 10), '25': (1994, 1),
    '42': (1994, 7), '38': (1995, 8), '46': (1996, 7), '21': (1996, 7),
    '29': (1996, 7), '56': (1997, 7),
}

# Zero Tolerance (<0.02 BAC for under 21)
ZERO_TOLERANCE = {
    '23': (1983, 1), '49': (1983, 1), '27': (1991, 8), '04': (1992, 1),
    '35': (1993, 7), '39': (1993, 7), '31': (1993, 1), '06': (1994, 1),
    '24': (1994, 10), '26': (1994, 10), '54': (1994, 6), '08': (1995, 7),
    '09': (1995, 10), '10': (1995, 1), '16': (1995, 7), '17': (1995, 1),
    '19': (1995, 5), '25': (1995, 1), '28': (1995, 7), '30': (1995, 10),
    '32': (1995, 10), '33': (1995, 1), '34': (1995, 1), '37': (1995, 12),
    '38': (1995, 8), '41': (1995, 10), '42': (1995, 2), '44': (1995, 7),
    '46': (1995, 7), '47': (1995, 7), '50': (1995, 7), '53': (1995, 1),
    '55': (1995, 1), '56': (1995, 7), '05': (1995, 7), '01': (1996, 10),
    '02': (1996, 9), '12': (1996, 1), '15': (1996, 6), '20': (1996, 7),
    '21': (1996, 7), '29': (1996, 1), '36': (1996, 11), '40': (1996, 9),
    '51': (1996, 7), '13': (1997, 7), '22': (1997, 8), '48': (1997, 9),
    '18': (1998, 7), '45': (1998, 7),
}

# Primary Seatbelt Law
PRIMARY_SEATBELT = {
    '01': (1999, 12), '02': (2006, 5), '06': (1993, 1), '09': (1986, 1),
    '10': (2003, 6), '13': (1996, 7), '15': (1985, 12), '17': (2003, 7),
    '18': (1998, 7), '19': (1986, 7), '21': (2006, 7), '22': (1995, 9),
    '23': (2007, 9), '24': (1997, 10), '26': (2000, 4), '28': (2006, 5),
    '34': (2000, 5), '35': (1986, 1), '36': (1984, 12), '37': (2006, 12),
    '40': (1997, 11), '41': (1990, 12), '45': (2005, 12), '47': (2004, 7),
    '48': (1985, 9), '53': (2002, 7),
}

# Secondary Seatbelt Law (any seatbelt law - used for non-primary)
SECONDARY_SEATBELT = {
    '01': (1991, 7), '02': (1990, 9), '04': (1991, 1), '05': (1991, 7),
    '06': (1986, 1), '08': (1987, 7), '10': (1992, 1), '12': (1986, 7),
    '13': (1988, 9), '16': (1986, 7), '17': (1988, 1), '18': (1987, 7),
    '20': (1986, 7), '21': (1994, 7), '22': (1986, 7), '23': (1995, 12),
    '24': (1986, 7), '25': (1994, 2), '26': (1985, 7), '27': (1986, 8),
    '28': (1994, 7), '29': (1985, 9), '30': (1987, 10), '31': (1993, 1),
    '32': (1987, 7), '34': (1985, 3), '37': (1985, 10), '38': (1994, 7),
    '39': (1986, 5), '40': (1987, 2), '42': (1987, 11), '44': (1991, 6),
    '45': (1989, 7), '46': (1995, 1), '47': (1986, 4), '49': (1986, 4),
    '50': (1994, 1), '51': (1988, 1), '53': (1986, 6), '54': (1993, 9),
    '55': (1987, 12), '56': (1989, 6),
}

# MLDA 21
MLDA21 = {
    '26': (1978, 12), '17': (1980, 1), '24': (1982, 7), '34': (1983, 1),
    '40': (1983, 9), '02': (1984, 1), '05': (1984, 1), '10': (1984, 1),
    '06': (1984, 1), '18': (1984, 7), '25': (1984, 6), '32': (1984, 7),
    '35': (1984, 7), '41': (1984, 4), '42': (1984, 1), '44': (1984, 7),
    '47': (1984, 8), '53': (1984, 1), '01': (1985, 9), '04': (1985, 8),
    '09': (1985, 10), '12': (1985, 7), '13': (1985, 9), '20': (1985, 7),
    '23': (1985, 1), '29': (1985, 7), '31': (1985, 1), '33': (1985, 6),
    '36': (1985, 12), '49': (1985, 7), '51': (1985, 7), '15': (1986, 9),
    '19': (1986, 4), '21': (1986, 7), '27': (1986, 9), '28': (1986, 10),
    '37': (1986, 9), '45': (1986, 9), '48': (1986, 9), '50': (1986, 7),
    '54': (1986, 7), '55': (1986, 9), '08': (1987, 7), '16': (1987, 4),
    '22': (1987, 9), '30': (1987, 4), '39': (1987, 7), '46': (1988, 4),
    '56': (1988, 7),
}

# GDL (Graduated Driver Licensing)
GDL = {
    '12': (1996, 7), '26': (1997, 4), '37': (1997, 12), '13': (1997, 7),
    '06': (1998, 7), '22': (1998, 7), '45': (1998, 7), '25': (1998, 3),
    '08': (1999, 7), '10': (1999, 7), '18': (1999, 7), '24': (1999, 7),
    '39': (1999, 7), '48': (1999, 7), '51': (1999, 7), '17': (1999, 7),
    '04': (2000, 7), '20': (2000, 7), '35': (2000, 7), '36': (2000, 9),
    '41': (2000, 7), '55': (2000, 9), '28': (2000, 7), '15': (2000, 7),
    '16': (2000, 7), '19': (2000, 7), '21': (2000, 7), '23': (2000, 7),
    '27': (2000, 7), '30': (2000, 7), '05': (2001, 7), '29': (2001, 7),
    '34': (2001, 7), '47': (2001, 7), '53': (2001, 7), '01': (2002, 7),
    '31': (2000, 7), '32': (2001, 7), '33': (2001, 7), '38': (2001, 7),
    '40': (2001, 7), '42': (2001, 7), '44': (2001, 7), '46': (2001, 7),
    '49': (2001, 7), '50': (2001, 7), '54': (2001, 7), '56': (2001, 7),
    '02': (2001, 7), '09': (2001, 7),
}

# Speed Limit >= 70 mph
SPEED_70 = {
    '04': (1987, 12), '16': (1987, 5), '32': (1987, 12), '48': (1987, 12),
    '49': (1987, 1), '56': (1987, 1), '01': (1996, 3), '05': (1996, 5),
    '06': (1996, 1), '08': (1996, 5), '12': (1996, 3), '13': (1996, 7),
    '18': (1996, 7), '19': (1996, 4), '20': (1996, 4), '21': (1996, 6),
    '26': (1996, 2), '28': (1996, 5), '29': (1996, 5), '31': (1996, 4),
    '35': (1996, 5), '37': (1996, 8), '38': (1996, 8), '40': (1996, 5),
    '46': (1996, 4), '51': (1996, 7), '53': (1996, 6), '22': (1997, 6),
    '27': (1997, 6), '54': (1997, 6), '47': (1998, 1), '30': (1999, 5),
    '45': (1999, 6),
}

# Aggravated DUI
AGGRAVATED_DUI = {
    '06': (1982, 1), '49': (1983, 1), '23': (1988, 1), '50': (1991, 1),
    '31': (1993, 1), '35': (1993, 7), '37': (1993, 12), '39': (1993, 7),
    '08': (1994, 7), '33': (1994, 7), '48': (1995, 9), '16': (1997, 7),
    '17': (1998, 1), '27': (1998, 8), '26': (1999, 10), '41': (1999, 10),
    '53': (1999, 7), '42': (2000, 2), '44': (2000, 7), '04': (2001, 9),
    '13': (2001, 7), '20': (2001, 7), '24': (2001, 10), '29': (2001, 7),
    '45': (2001, 6), '12': (2002, 1), '19': (2002, 7), '28': (2002, 7),
    '40': (2002, 7), '32': (2003, 10), '38': (2003, 8), '47': (2003, 7),
    '54': (2003, 7), '55': (2003, 12), '56': (2003, 7), '51': (2004, 7),
    '36': (2006, 11),
}

def frac_value(year, adopt_year, adopt_month=7):
    """Calculate fractional value based on adoption timing."""
    if year < adopt_year:
        return 0.0
    elif year == adopt_year:
        return (13 - adopt_month) / 12
    else:
        return 1.0

# Load crash data
print("  Loading crash data...")
state_year = pd.read_parquet(BUILD / "output" / "state_year_crashes.parquet")

# Add BAC adoption dates
print("  Adding BAC adoption dates...")
state_year['adoption_year'] = state_year['state_fips'].map(BAC_DATES)
state_year['event_time'] = state_year['year'] - state_year['adoption_year']
state_year['treated'] = (state_year['event_time'] >= 0).astype(int)

# Add policy controls
print("  Creating policy control variables...")
state_fips_list = state_year['state_fips'].unique()
years = state_year['year'].unique()

policy_data = []
for fips in state_fips_list:
    for year in years:
        alr_info = ALR_ADOPTION.get(fips, (2020, 1))
        zt_info = ZERO_TOLERANCE.get(fips, (2020, 1))
        ps_info = PRIMARY_SEATBELT.get(fips, (2020, 1))
        ss_info = SECONDARY_SEATBELT.get(fips, (2020, 1))
        mlda_info = MLDA21.get(fips, (2020, 1))
        gdl_info = GDL.get(fips, (2020, 1))
        speed_info = SPEED_70.get(fips, (2020, 1))
        agg_info = AGGRAVATED_DUI.get(fips, (2020, 1))

        primary_val = frac_value(year, ps_info[0], ps_info[1])
        any_seatbelt_val = frac_value(year, ss_info[0], ss_info[1])
        secondary_val = max(0, any_seatbelt_val - primary_val)

        policy_data.append({
            'state_fips': fips,
            'year': year,
            'alr': frac_value(year, alr_info[0], alr_info[1]),
            'zero_tolerance': frac_value(year, zt_info[0], zt_info[1]),
            'primary_seatbelt': primary_val,
            'secondary_seatbelt': secondary_val,
            'mlda21': frac_value(year, mlda_info[0], mlda_info[1]),
            'gdl': frac_value(year, gdl_info[0], gdl_info[1]),
            'speed_70': frac_value(year, speed_info[0], speed_info[1]),
            'aggravated_dui': frac_value(year, agg_info[0], agg_info[1]),
        })

policy_df = pd.DataFrame(policy_data)
state_year = state_year.merge(policy_df, on=['state_fips', 'year'], how='left')

# Try to download economic data from FRED
print("  Downloading economic data from FRED...")
STATE_UNEMP_CODES = {
    '01': 'ALUR', '02': 'AKUR', '04': 'AZUR', '05': 'ARUR', '06': 'CAUR',
    '08': 'COUR', '09': 'CTUR', '10': 'DEUR', '12': 'FLUR', '13': 'GAUR',
    '15': 'HIUR', '16': 'IDUR', '17': 'ILUR', '18': 'INUR', '19': 'IAUR',
    '20': 'KSUR', '21': 'KYUR', '22': 'LAUR', '23': 'MEUR', '24': 'MDUR',
    '25': 'MAUR', '26': 'MIUR', '27': 'MNUR', '28': 'MSUR', '29': 'MOUR',
    '30': 'MTUR', '31': 'NEUR', '32': 'NVUR', '33': 'NHUR', '34': 'NJUR',
    '35': 'NMUR', '36': 'NYUR', '37': 'NCUR', '38': 'NDUR', '39': 'OHUR',
    '40': 'OKUR', '41': 'ORUR', '42': 'PAUR', '44': 'RIUR', '45': 'SCUR',
    '46': 'SDUR', '47': 'TNUR', '48': 'TXUR', '49': 'UTUR', '50': 'VTUR',
    '51': 'VAUR', '53': 'WAUR', '54': 'WVUR', '55': 'WIUR', '56': 'WYUR'
}

try:
    all_unemp = []
    for fips, code in STATE_UNEMP_CODES.items():
        try:
            url = f"https://fred.stlouisfed.org/graph/fredgraph.csv?id={code}"
            df = pd.read_csv(url)
            df.columns = ['date', 'unemployment']
            df['date'] = pd.to_datetime(df['date'])
            df['year'] = df['date'].dt.year
            df = df[(df['year'] >= 1982) & (df['year'] <= 2008)]
            annual = df.groupby('year')['unemployment'].mean().reset_index()
            annual['state_fips'] = fips
            all_unemp.append(annual)
        except:
            pass

    if all_unemp:
        unemp_df = pd.concat(all_unemp, ignore_index=True)
        state_year = state_year.merge(unemp_df, on=['state_fips', 'year'], how='left')
        print(f"    Added unemployment data for {len(all_unemp)} states")
except Exception as e:
    print(f"    Could not download unemployment data: {e}")

# Try to download per capita income data from FRED
print("  Downloading per capita income data from FRED...")
STATE_INCOME_CODES = {
    '01': 'ALPCPI', '02': 'AKPCPI', '04': 'AZPCPI', '05': 'ARPCPI', '06': 'CAPCPI',
    '08': 'COPCPI', '09': 'CTPCPI', '10': 'DEPCPI', '12': 'FLPCPI', '13': 'GAPCPI',
    '15': 'HIPCPI', '16': 'IDPCPI', '17': 'ILPCPI', '18': 'INPCPI', '19': 'IAPCPI',
    '20': 'KSPCPI', '21': 'KYPCPI', '22': 'LAPCPI', '23': 'MEPCPI', '24': 'MDPCPI',
    '25': 'MAPCPI', '26': 'MIPCPI', '27': 'MNPCPI', '28': 'MSPCPI', '29': 'MOPCPI',
    '30': 'MTPCPI', '31': 'NEPCPI', '32': 'NVPCPI', '33': 'NHPCPI', '34': 'NJPCPI',
    '35': 'NMPCPI', '36': 'NYPCPI', '37': 'NCPCPI', '38': 'NDPCPI', '39': 'OHPCPI',
    '40': 'OKPCPI', '41': 'ORPCPI', '42': 'PAPCPI', '44': 'RIPCPI', '45': 'SCPCPI',
    '46': 'SDPCPI', '47': 'TNPCPI', '48': 'TXPCPI', '49': 'UTPCPI', '50': 'VTPCPI',
    '51': 'VAPCPI', '53': 'WAPCPI', '54': 'WVPCPI', '55': 'WIPCPI', '56': 'WYPCPI'
}

try:
    all_income = []
    for fips, code in STATE_INCOME_CODES.items():
        try:
            url = f"https://fred.stlouisfed.org/graph/fredgraph.csv?id={code}"
            df = pd.read_csv(url)
            df.columns = ['date', 'income']
            df['date'] = pd.to_datetime(df['date'])
            df['year'] = df['date'].dt.year
            df = df[(df['year'] >= 1982) & (df['year'] <= 2008)]
            annual = df.groupby('year')['income'].mean().reset_index()
            annual['state_fips'] = fips
            all_income.append(annual)
        except:
            pass

    if all_income:
        income_df = pd.concat(all_income, ignore_index=True)
        state_year = state_year.merge(income_df, on=['state_fips', 'year'], how='left')
        print(f"    Added income data for {len(all_income)} states")
except Exception as e:
    print(f"    Could not download income data: {e}")

# Create log outcome variables
state_year['ln_hr'] = np.log(state_year['hr_fatalities'] + 1)
state_year['ln_nhr'] = np.log(state_year['nhr_fatalities'] + 1)
state_year['ln_total'] = np.log(state_year['total_fatalities'] + 1)

# Save final analysis dataset
state_year.to_parquet(BUILD / "output" / "analysis_data.parquet")
state_year.to_csv(BUILD / "output" / "analysis_data.csv", index=False)

print(f"  Final dataset: {len(state_year)} observations")
print(f"  Columns: {list(state_year.columns)}")
print("  Saved to build/output/analysis_data.parquet")
