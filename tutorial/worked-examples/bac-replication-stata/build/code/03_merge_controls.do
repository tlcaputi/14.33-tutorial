* 03_merge_controls.do - Merge BAC dates, policy controls, and economic data

clear all

* =============================================================================
* Load crash data
* =============================================================================
di "  Loading crash data..."
use "$build/output/state_year_crashes.dta", clear

* =============================================================================
* BAC Adoption Dates (from APIS)
* =============================================================================
di "  Adding BAC adoption dates..."

gen adoption_year = .
replace adoption_year = 1995 if state_fips == "01"
replace adoption_year = 2001 if state_fips == "02"
replace adoption_year = 2001 if state_fips == "04"
replace adoption_year = 2001 if state_fips == "05"
replace adoption_year = 1990 if state_fips == "06"
replace adoption_year = 2004 if state_fips == "08"
replace adoption_year = 2002 if state_fips == "09"
replace adoption_year = 2004 if state_fips == "10"
replace adoption_year = 1994 if state_fips == "12"
replace adoption_year = 2001 if state_fips == "13"
replace adoption_year = 1995 if state_fips == "15"
replace adoption_year = 1997 if state_fips == "16"
replace adoption_year = 1997 if state_fips == "17"
replace adoption_year = 2001 if state_fips == "18"
replace adoption_year = 2003 if state_fips == "19"
replace adoption_year = 1993 if state_fips == "20"
replace adoption_year = 2000 if state_fips == "21"
replace adoption_year = 2003 if state_fips == "22"
replace adoption_year = 1988 if state_fips == "23"
replace adoption_year = 2001 if state_fips == "24"
replace adoption_year = 2003 if state_fips == "25"
replace adoption_year = 2003 if state_fips == "26"
replace adoption_year = 2005 if state_fips == "27"
replace adoption_year = 2002 if state_fips == "28"
replace adoption_year = 2001 if state_fips == "29"
replace adoption_year = 2003 if state_fips == "30"
replace adoption_year = 2001 if state_fips == "31"
replace adoption_year = 2003 if state_fips == "32"
replace adoption_year = 1994 if state_fips == "33"
replace adoption_year = 2004 if state_fips == "34"
replace adoption_year = 1994 if state_fips == "35"
replace adoption_year = 2003 if state_fips == "36"
replace adoption_year = 1993 if state_fips == "37"
replace adoption_year = 2003 if state_fips == "38"
replace adoption_year = 2003 if state_fips == "39"
replace adoption_year = 2001 if state_fips == "40"
replace adoption_year = 1983 if state_fips == "41"
replace adoption_year = 2003 if state_fips == "42"
replace adoption_year = 2000 if state_fips == "44"
replace adoption_year = 2003 if state_fips == "45"
replace adoption_year = 2002 if state_fips == "46"
replace adoption_year = 2003 if state_fips == "47"
replace adoption_year = 1999 if state_fips == "48"
replace adoption_year = 1983 if state_fips == "49"
replace adoption_year = 1991 if state_fips == "50"
replace adoption_year = 1994 if state_fips == "51"
replace adoption_year = 1999 if state_fips == "53"
replace adoption_year = 2004 if state_fips == "54"
replace adoption_year = 2003 if state_fips == "55"
replace adoption_year = 2002 if state_fips == "56"

* Create treatment indicators
gen event_time = year - adoption_year
gen treated = (event_time >= 0)

* =============================================================================
* Policy Controls - Fractional year coding
* Sources: NHTSA, IIHS, APIS
* =============================================================================
di "  Creating policy control variables..."

* Helper program for fractional value
capture program drop frac_value
program define frac_value
    args varname adopt_year adopt_month
    replace `varname' = 0 if year < `adopt_year'
    replace `varname' = (13 - `adopt_month') / 12 if year == `adopt_year'
    replace `varname' = 1 if year > `adopt_year'
end

* Initialize policy variables
gen alr = 0
gen zero_tolerance = 0
gen primary_seatbelt = 0
gen secondary_seatbelt_any = 0
gen mlda21 = 0
gen gdl = 0
gen speed_70 = 0
gen aggravated_dui = 0

* ALR (Administrative License Revocation)
frac_value alr 1976 1 if state_fips == "27"
frac_value alr 1981 1 if state_fips == "54"
frac_value alr 1984 1 if state_fips == "35"
frac_value alr 1983 7 if state_fips == "32"
frac_value alr 1984 7 if state_fips == "16"
frac_value alr 1984 10 if state_fips == "30"
frac_value alr 1985 7 if state_fips == "08"
frac_value alr 1986 1 if state_fips == "19"
frac_value alr 1986 7 if state_fips == "49"
frac_value alr 1990 1 if state_fips == "06"
frac_value alr 1988 1 if state_fips == "53"
frac_value alr 1988 1 if state_fips == "23"
frac_value alr 1989 7 if state_fips == "50"
frac_value alr 1989 1 if state_fips == "41"
frac_value alr 1990 1 if state_fips == "04"
frac_value alr 1986 1 if state_fips == "17"
frac_value alr 1988 7 if state_fips == "20"
frac_value alr 1989 1 if state_fips == "31"
frac_value alr 1990 10 if state_fips == "37"
frac_value alr 1988 1 if state_fips == "55"
frac_value alr 1990 1 if state_fips == "15"
frac_value alr 1989 1 if state_fips == "02"
frac_value alr 1990 1 if state_fips == "12"
frac_value alr 1991 7 if state_fips == "13"
frac_value alr 1993 10 if state_fips == "26"
frac_value alr 1993 7 if state_fips == "39"
frac_value alr 1993 9 if state_fips == "48"
frac_value alr 1995 7 if state_fips == "51"
frac_value alr 1996 7 if state_fips == "18"
frac_value alr 1996 7 if state_fips == "01"
frac_value alr 1998 7 if state_fips == "45"
frac_value alr 1997 8 if state_fips == "05"
frac_value alr 1997 10 if state_fips == "24"
frac_value alr 1997 7 if state_fips == "47"
frac_value alr 1993 1 if state_fips == "33"
frac_value alr 1994 7 if state_fips == "44"
frac_value alr 1996 1 if state_fips == "10"
frac_value alr 1994 1 if state_fips == "34"
frac_value alr 1995 8 if state_fips == "22"
frac_value alr 1995 7 if state_fips == "28"
frac_value alr 1997 11 if state_fips == "40"
frac_value alr 1994 11 if state_fips == "36"
frac_value alr 1995 10 if state_fips == "09"
frac_value alr 1994 1 if state_fips == "25"
frac_value alr 1994 7 if state_fips == "42"
frac_value alr 1995 8 if state_fips == "38"
frac_value alr 1996 7 if state_fips == "46"
frac_value alr 1996 7 if state_fips == "21"
frac_value alr 1996 7 if state_fips == "29"
frac_value alr 1997 7 if state_fips == "56"

* Zero Tolerance (<0.02 BAC for under 21)
frac_value zero_tolerance 1983 1 if state_fips == "23"
frac_value zero_tolerance 1983 1 if state_fips == "49"
frac_value zero_tolerance 1991 8 if state_fips == "27"
frac_value zero_tolerance 1992 1 if state_fips == "04"
frac_value zero_tolerance 1993 7 if state_fips == "35"
frac_value zero_tolerance 1993 7 if state_fips == "39"
frac_value zero_tolerance 1993 1 if state_fips == "31"
frac_value zero_tolerance 1994 1 if state_fips == "06"
frac_value zero_tolerance 1994 10 if state_fips == "24"
frac_value zero_tolerance 1994 10 if state_fips == "26"
frac_value zero_tolerance 1994 6 if state_fips == "54"
frac_value zero_tolerance 1995 7 if state_fips == "08"
frac_value zero_tolerance 1995 10 if state_fips == "09"
frac_value zero_tolerance 1995 1 if state_fips == "10"
frac_value zero_tolerance 1995 7 if state_fips == "16"
frac_value zero_tolerance 1995 1 if state_fips == "17"
frac_value zero_tolerance 1995 5 if state_fips == "19"
frac_value zero_tolerance 1995 1 if state_fips == "25"
frac_value zero_tolerance 1995 7 if state_fips == "28"
frac_value zero_tolerance 1995 10 if state_fips == "30"
frac_value zero_tolerance 1995 10 if state_fips == "32"
frac_value zero_tolerance 1995 1 if state_fips == "33"
frac_value zero_tolerance 1995 1 if state_fips == "34"
frac_value zero_tolerance 1995 12 if state_fips == "37"
frac_value zero_tolerance 1995 8 if state_fips == "38"
frac_value zero_tolerance 1995 10 if state_fips == "41"
frac_value zero_tolerance 1995 2 if state_fips == "42"
frac_value zero_tolerance 1995 7 if state_fips == "44"
frac_value zero_tolerance 1995 7 if state_fips == "46"
frac_value zero_tolerance 1995 7 if state_fips == "47"
frac_value zero_tolerance 1995 7 if state_fips == "50"
frac_value zero_tolerance 1995 1 if state_fips == "53"
frac_value zero_tolerance 1995 1 if state_fips == "55"
frac_value zero_tolerance 1995 7 if state_fips == "56"
frac_value zero_tolerance 1995 7 if state_fips == "05"
frac_value zero_tolerance 1996 10 if state_fips == "01"
frac_value zero_tolerance 1996 9 if state_fips == "02"
frac_value zero_tolerance 1996 1 if state_fips == "12"
frac_value zero_tolerance 1996 6 if state_fips == "15"
frac_value zero_tolerance 1996 7 if state_fips == "20"
frac_value zero_tolerance 1996 7 if state_fips == "21"
frac_value zero_tolerance 1996 1 if state_fips == "29"
frac_value zero_tolerance 1996 11 if state_fips == "36"
frac_value zero_tolerance 1996 9 if state_fips == "40"
frac_value zero_tolerance 1996 7 if state_fips == "51"
frac_value zero_tolerance 1997 7 if state_fips == "13"
frac_value zero_tolerance 1997 8 if state_fips == "22"
frac_value zero_tolerance 1997 9 if state_fips == "48"
frac_value zero_tolerance 1998 7 if state_fips == "18"
frac_value zero_tolerance 1998 7 if state_fips == "45"

* MLDA 21
frac_value mlda21 1978 12 if state_fips == "26"
frac_value mlda21 1980 1 if state_fips == "17"
frac_value mlda21 1982 7 if state_fips == "24"
frac_value mlda21 1983 1 if state_fips == "34"
frac_value mlda21 1983 9 if state_fips == "40"
frac_value mlda21 1984 1 if state_fips == "02"
frac_value mlda21 1984 1 if state_fips == "05"
frac_value mlda21 1984 1 if state_fips == "10"
frac_value mlda21 1984 1 if state_fips == "06"
frac_value mlda21 1984 7 if state_fips == "18"
frac_value mlda21 1984 6 if state_fips == "25"
frac_value mlda21 1984 7 if state_fips == "32"
frac_value mlda21 1984 7 if state_fips == "35"
frac_value mlda21 1984 4 if state_fips == "41"
frac_value mlda21 1984 1 if state_fips == "42"
frac_value mlda21 1984 7 if state_fips == "44"
frac_value mlda21 1984 8 if state_fips == "47"
frac_value mlda21 1984 1 if state_fips == "53"
frac_value mlda21 1985 9 if state_fips == "01"
frac_value mlda21 1985 8 if state_fips == "04"
frac_value mlda21 1985 10 if state_fips == "09"
frac_value mlda21 1985 7 if state_fips == "12"
frac_value mlda21 1985 9 if state_fips == "13"
frac_value mlda21 1985 7 if state_fips == "20"
frac_value mlda21 1985 1 if state_fips == "23"
frac_value mlda21 1985 7 if state_fips == "29"
frac_value mlda21 1985 1 if state_fips == "31"
frac_value mlda21 1985 6 if state_fips == "33"
frac_value mlda21 1985 12 if state_fips == "36"
frac_value mlda21 1985 7 if state_fips == "49"
frac_value mlda21 1985 7 if state_fips == "51"
frac_value mlda21 1986 9 if state_fips == "15"
frac_value mlda21 1986 4 if state_fips == "19"
frac_value mlda21 1986 7 if state_fips == "21"
frac_value mlda21 1986 9 if state_fips == "27"
frac_value mlda21 1986 10 if state_fips == "28"
frac_value mlda21 1986 9 if state_fips == "37"
frac_value mlda21 1986 9 if state_fips == "45"
frac_value mlda21 1986 9 if state_fips == "48"
frac_value mlda21 1986 7 if state_fips == "50"
frac_value mlda21 1986 7 if state_fips == "54"
frac_value mlda21 1986 9 if state_fips == "55"
frac_value mlda21 1987 7 if state_fips == "08"
frac_value mlda21 1987 4 if state_fips == "16"
frac_value mlda21 1987 9 if state_fips == "22"
frac_value mlda21 1987 4 if state_fips == "30"
frac_value mlda21 1987 7 if state_fips == "39"
frac_value mlda21 1988 4 if state_fips == "46"
frac_value mlda21 1988 7 if state_fips == "56"

* GDL (Graduated Driver Licensing)
frac_value gdl 1996 7 if state_fips == "12"
frac_value gdl 1997 4 if state_fips == "26"
frac_value gdl 1997 12 if state_fips == "37"
frac_value gdl 1997 7 if state_fips == "13"
frac_value gdl 1998 7 if state_fips == "06"
frac_value gdl 1998 7 if state_fips == "22"
frac_value gdl 1998 7 if state_fips == "45"
frac_value gdl 1998 3 if state_fips == "25"
frac_value gdl 1999 7 if state_fips == "08"
frac_value gdl 1999 7 if state_fips == "10"
frac_value gdl 1999 7 if state_fips == "18"
frac_value gdl 1999 7 if state_fips == "24"
frac_value gdl 1999 7 if state_fips == "39"
frac_value gdl 1999 7 if state_fips == "48"
frac_value gdl 1999 7 if state_fips == "51"
frac_value gdl 1999 7 if state_fips == "17"
frac_value gdl 2000 7 if state_fips == "04"
frac_value gdl 2000 7 if state_fips == "20"
frac_value gdl 2000 7 if state_fips == "35"
frac_value gdl 2000 9 if state_fips == "36"
frac_value gdl 2000 7 if state_fips == "41"
frac_value gdl 2000 9 if state_fips == "55"
frac_value gdl 2000 7 if state_fips == "28"
frac_value gdl 2000 7 if state_fips == "15"
frac_value gdl 2000 7 if state_fips == "16"
frac_value gdl 2000 7 if state_fips == "19"
frac_value gdl 2000 7 if state_fips == "21"
frac_value gdl 2000 7 if state_fips == "23"
frac_value gdl 2000 7 if state_fips == "27"
frac_value gdl 2000 7 if state_fips == "30"
frac_value gdl 2001 7 if state_fips == "05"
frac_value gdl 2001 7 if state_fips == "29"
frac_value gdl 2001 7 if state_fips == "34"
frac_value gdl 2001 7 if state_fips == "47"
frac_value gdl 2001 7 if state_fips == "53"
frac_value gdl 2002 7 if state_fips == "01"
frac_value gdl 2000 7 if state_fips == "31"
frac_value gdl 2001 7 if state_fips == "32"
frac_value gdl 2001 7 if state_fips == "33"
frac_value gdl 2001 7 if state_fips == "38"
frac_value gdl 2001 7 if state_fips == "40"
frac_value gdl 2001 7 if state_fips == "42"
frac_value gdl 2001 7 if state_fips == "44"
frac_value gdl 2001 7 if state_fips == "46"
frac_value gdl 2001 7 if state_fips == "49"
frac_value gdl 2001 7 if state_fips == "50"
frac_value gdl 2001 7 if state_fips == "54"
frac_value gdl 2001 7 if state_fips == "56"
frac_value gdl 2001 7 if state_fips == "02"
frac_value gdl 2001 7 if state_fips == "09"

* Speed Limit >= 70 mph
frac_value speed_70 1987 12 if state_fips == "04"
frac_value speed_70 1987 5 if state_fips == "16"
frac_value speed_70 1987 12 if state_fips == "32"
frac_value speed_70 1987 12 if state_fips == "48"
frac_value speed_70 1987 1 if state_fips == "49"
frac_value speed_70 1987 1 if state_fips == "56"
frac_value speed_70 1996 3 if state_fips == "01"
frac_value speed_70 1996 5 if state_fips == "05"
frac_value speed_70 1996 1 if state_fips == "06"
frac_value speed_70 1996 5 if state_fips == "08"
frac_value speed_70 1996 3 if state_fips == "12"
frac_value speed_70 1996 7 if state_fips == "13"
frac_value speed_70 1996 7 if state_fips == "18"
frac_value speed_70 1996 4 if state_fips == "19"
frac_value speed_70 1996 4 if state_fips == "20"
frac_value speed_70 1996 6 if state_fips == "21"
frac_value speed_70 1996 2 if state_fips == "26"
frac_value speed_70 1996 5 if state_fips == "28"
frac_value speed_70 1996 5 if state_fips == "29"
frac_value speed_70 1996 4 if state_fips == "31"
frac_value speed_70 1996 5 if state_fips == "35"
frac_value speed_70 1996 8 if state_fips == "37"
frac_value speed_70 1996 8 if state_fips == "38"
frac_value speed_70 1996 5 if state_fips == "40"
frac_value speed_70 1996 4 if state_fips == "46"
frac_value speed_70 1996 7 if state_fips == "51"
frac_value speed_70 1996 6 if state_fips == "53"
frac_value speed_70 1997 6 if state_fips == "22"
frac_value speed_70 1997 6 if state_fips == "27"
frac_value speed_70 1997 6 if state_fips == "54"
frac_value speed_70 1998 1 if state_fips == "47"
frac_value speed_70 1999 5 if state_fips == "30"
frac_value speed_70 1999 6 if state_fips == "45"

* Aggravated DUI
frac_value aggravated_dui 1982 1 if state_fips == "06"
frac_value aggravated_dui 1983 1 if state_fips == "49"
frac_value aggravated_dui 1988 1 if state_fips == "23"
frac_value aggravated_dui 1991 1 if state_fips == "50"
frac_value aggravated_dui 1993 1 if state_fips == "31"
frac_value aggravated_dui 1993 7 if state_fips == "35"
frac_value aggravated_dui 1993 12 if state_fips == "37"
frac_value aggravated_dui 1993 7 if state_fips == "39"
frac_value aggravated_dui 1994 7 if state_fips == "08"
frac_value aggravated_dui 1994 7 if state_fips == "33"
frac_value aggravated_dui 1995 9 if state_fips == "48"
frac_value aggravated_dui 1997 7 if state_fips == "16"
frac_value aggravated_dui 1998 1 if state_fips == "17"
frac_value aggravated_dui 1998 8 if state_fips == "27"
frac_value aggravated_dui 1999 10 if state_fips == "26"
frac_value aggravated_dui 1999 10 if state_fips == "41"
frac_value aggravated_dui 1999 7 if state_fips == "53"
frac_value aggravated_dui 2000 2 if state_fips == "42"
frac_value aggravated_dui 2000 7 if state_fips == "44"
frac_value aggravated_dui 2001 9 if state_fips == "04"
frac_value aggravated_dui 2001 7 if state_fips == "13"
frac_value aggravated_dui 2001 7 if state_fips == "20"
frac_value aggravated_dui 2001 10 if state_fips == "24"
frac_value aggravated_dui 2001 7 if state_fips == "29"
frac_value aggravated_dui 2001 6 if state_fips == "45"
frac_value aggravated_dui 2002 1 if state_fips == "12"
frac_value aggravated_dui 2002 7 if state_fips == "19"
frac_value aggravated_dui 2002 7 if state_fips == "28"
frac_value aggravated_dui 2002 7 if state_fips == "40"
frac_value aggravated_dui 2003 10 if state_fips == "32"
frac_value aggravated_dui 2003 8 if state_fips == "38"
frac_value aggravated_dui 2003 7 if state_fips == "47"
frac_value aggravated_dui 2003 7 if state_fips == "54"
frac_value aggravated_dui 2003 12 if state_fips == "55"
frac_value aggravated_dui 2003 7 if state_fips == "56"
frac_value aggravated_dui 2004 7 if state_fips == "51"
frac_value aggravated_dui 2006 11 if state_fips == "36"

* Primary Seatbelt Law
frac_value primary_seatbelt 1999 12 if state_fips == "01"
frac_value primary_seatbelt 2006 5 if state_fips == "02"
frac_value primary_seatbelt 1993 1 if state_fips == "06"
frac_value primary_seatbelt 1986 1 if state_fips == "09"
frac_value primary_seatbelt 2003 6 if state_fips == "10"
frac_value primary_seatbelt 1996 7 if state_fips == "13"
frac_value primary_seatbelt 1985 12 if state_fips == "15"
frac_value primary_seatbelt 2003 7 if state_fips == "17"
frac_value primary_seatbelt 1998 7 if state_fips == "18"
frac_value primary_seatbelt 1986 7 if state_fips == "19"
frac_value primary_seatbelt 2006 7 if state_fips == "21"
frac_value primary_seatbelt 1995 9 if state_fips == "22"
frac_value primary_seatbelt 2007 9 if state_fips == "23"
frac_value primary_seatbelt 1997 10 if state_fips == "24"
frac_value primary_seatbelt 2000 4 if state_fips == "26"
frac_value primary_seatbelt 2006 5 if state_fips == "28"
frac_value primary_seatbelt 2000 5 if state_fips == "34"
frac_value primary_seatbelt 1986 1 if state_fips == "35"
frac_value primary_seatbelt 1984 12 if state_fips == "36"
frac_value primary_seatbelt 2006 12 if state_fips == "37"
frac_value primary_seatbelt 1997 11 if state_fips == "40"
frac_value primary_seatbelt 1990 12 if state_fips == "41"
frac_value primary_seatbelt 2005 12 if state_fips == "45"
frac_value primary_seatbelt 2004 7 if state_fips == "47"
frac_value primary_seatbelt 1985 9 if state_fips == "48"
frac_value primary_seatbelt 2002 7 if state_fips == "53"

* Secondary Seatbelt Law (any seatbelt law - used for non-primary)
frac_value secondary_seatbelt_any 1991 7 if state_fips == "01"
frac_value secondary_seatbelt_any 1990 9 if state_fips == "02"
frac_value secondary_seatbelt_any 1991 1 if state_fips == "04"
frac_value secondary_seatbelt_any 1991 7 if state_fips == "05"
frac_value secondary_seatbelt_any 1986 1 if state_fips == "06"
frac_value secondary_seatbelt_any 1987 7 if state_fips == "08"
frac_value secondary_seatbelt_any 1992 1 if state_fips == "10"
frac_value secondary_seatbelt_any 1986 7 if state_fips == "12"
frac_value secondary_seatbelt_any 1988 9 if state_fips == "13"
frac_value secondary_seatbelt_any 1986 7 if state_fips == "16"
frac_value secondary_seatbelt_any 1988 1 if state_fips == "17"
frac_value secondary_seatbelt_any 1987 7 if state_fips == "18"
frac_value secondary_seatbelt_any 1986 7 if state_fips == "20"
frac_value secondary_seatbelt_any 1994 7 if state_fips == "21"
frac_value secondary_seatbelt_any 1986 7 if state_fips == "22"
frac_value secondary_seatbelt_any 1995 12 if state_fips == "23"
frac_value secondary_seatbelt_any 1986 7 if state_fips == "24"
frac_value secondary_seatbelt_any 1994 2 if state_fips == "25"
frac_value secondary_seatbelt_any 1985 7 if state_fips == "26"
frac_value secondary_seatbelt_any 1986 8 if state_fips == "27"
frac_value secondary_seatbelt_any 1994 7 if state_fips == "28"
frac_value secondary_seatbelt_any 1985 9 if state_fips == "29"
frac_value secondary_seatbelt_any 1987 10 if state_fips == "30"
frac_value secondary_seatbelt_any 1993 1 if state_fips == "31"
frac_value secondary_seatbelt_any 1987 7 if state_fips == "32"
frac_value secondary_seatbelt_any 1985 3 if state_fips == "34"
frac_value secondary_seatbelt_any 1985 10 if state_fips == "37"
frac_value secondary_seatbelt_any 1994 7 if state_fips == "38"
frac_value secondary_seatbelt_any 1986 5 if state_fips == "39"
frac_value secondary_seatbelt_any 1987 2 if state_fips == "40"
frac_value secondary_seatbelt_any 1987 11 if state_fips == "42"
frac_value secondary_seatbelt_any 1991 6 if state_fips == "44"
frac_value secondary_seatbelt_any 1989 7 if state_fips == "45"
frac_value secondary_seatbelt_any 1995 1 if state_fips == "46"
frac_value secondary_seatbelt_any 1986 4 if state_fips == "47"
frac_value secondary_seatbelt_any 1986 4 if state_fips == "49"
frac_value secondary_seatbelt_any 1994 1 if state_fips == "50"
frac_value secondary_seatbelt_any 1988 1 if state_fips == "51"
frac_value secondary_seatbelt_any 1986 6 if state_fips == "53"
frac_value secondary_seatbelt_any 1993 9 if state_fips == "54"
frac_value secondary_seatbelt_any 1987 12 if state_fips == "55"
frac_value secondary_seatbelt_any 1989 6 if state_fips == "56"

* Calculate secondary seatbelt (any seatbelt minus primary)
gen secondary_seatbelt = max(0, secondary_seatbelt_any - primary_seatbelt)
drop secondary_seatbelt_any

* =============================================================================
* Download unemployment data from FRED
* =============================================================================
di "  Downloading economic data from FRED..."

* Save current data
tempfile main_data
save `main_data', replace

* Create empty unemployment dataset
clear
gen state_fips = ""
gen year = .
gen unemployment = .
tempfile unemp_data
save `unemp_data', replace

* State FIPS codes and corresponding FRED series codes
local fips_list 01 02 04 05 06 08 09 10 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56
local code_list ALUR AKUR AZUR ARUR CAUR COUR CTUR DEUR FLUR GAUR HIUR IDUR ILUR INUR IAUR KSUR KYUR LAUR MEUR MDUR MAUR MIUR MNUR MSUR MOUR MTUR NEUR NVUR NHUR NJUR NMUR NYUR NCUR NDUR OHUR OKUR ORUR PAUR RIUR SCUR SDUR TNUR TXUR UTUR VTUR VAUR WAUR WVUR WIUR WYUR

local states_downloaded = 0
local n : word count `fips_list'

* Create temp directory path
tempfile temppath
local tempdir = substr("`temppath'", 1, strrpos("`temppath'", "/"))

forvalues i = 1/`n' {
    local fips : word `i' of `fips_list'
    local code : word `i' of `code_list'

    quietly di "    Downloading `code' for state `fips'..."

    * Try up to 3 times for each state
    local success = 0
    forvalues try = 1/3 {
        if `success' == 0 {
            capture noisily {
                * Download using copy command
                local tempcsv "`tempdir'fred_`code'.csv"
                copy "https://fred.stlouisfed.org/graph/fredgraph.csv?id=`code'" "`tempcsv'", replace
                import delimited "`tempcsv'", clear varnames(1)
                capture erase "`tempcsv'"

                * Parse date and extract year (FRED uses observation_date as column name)
                gen year = real(substr(observation_date, 1, 4))
                local lccode = lower("`code'")
                rename `lccode' unemployment_val

                * Keep only years 1982-2008
                keep if year >= 1982 & year <= 2008

                * Calculate annual average
                collapse (mean) unemployment = unemployment_val, by(year)

                * Add state fips
                gen state_fips = "`fips'"

                * Append to unemployment data
                append using `unemp_data'
                save `unemp_data', replace

                local states_downloaded = `states_downloaded' + 1
                local success = 1
            }
            if _rc != 0 & `try' < 3 {
                sleep 1000  // Wait 1 second before retry
            }
        }
    }
    if `success' == 0 {
        di "      Could not download `code' after 3 attempts"
    }
}

di "    Downloaded unemployment data for `states_downloaded' states"

* Merge unemployment data back to main data
use `main_data', clear
merge m:1 state_fips year using `unemp_data', nogen keep(master match)

* =============================================================================
* Create log outcome variables
* =============================================================================
gen ln_hr = ln(hr_fatalities + 1)
gen ln_nhr = ln(nhr_fatalities + 1)
gen ln_total = ln(total_fatalities + 1)

* =============================================================================
* Encode state for fixed effects
* =============================================================================
encode state_fips, gen(state_id)

* =============================================================================
* Save final analysis dataset
* =============================================================================
order state_fips state_id state_name year total_fatalities hr_fatalities nhr_fatalities ///
      ln_hr ln_nhr ln_total adoption_year event_time treated ///
      alr zero_tolerance primary_seatbelt secondary_seatbelt mlda21 gdl speed_70 aggravated_dui

save "$build/output/analysis_data.dta", replace
export delimited "$build/output/analysis_data.csv", replace

local n_obs = _N
di "  Final dataset: `n_obs' observations"
di "  Saved to build/output/analysis_data.dta"
