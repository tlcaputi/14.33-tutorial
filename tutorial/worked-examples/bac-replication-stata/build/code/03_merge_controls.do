* 03_merge_controls.do - Merge BAC dates, policy controls, and economic data

clear

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
    syntax varlist(min=1 max=1) [if], adopt_year(integer) adopt_month(integer)
    local varname `varlist'
    marksample touse
    replace `varname' = 0 if year < `adopt_year' & `touse'
    replace `varname' = (`adopt_month' - 1) / 12 if year == `adopt_year' & `touse'
    replace `varname' = 1 if year > `adopt_year' & `touse'
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
frac_value alr if state_fips == "27", adopt_year(1976) adopt_month(1)
frac_value alr if state_fips == "54", adopt_year(1981) adopt_month(1)
frac_value alr if state_fips == "35", adopt_year(1984) adopt_month(1)
frac_value alr if state_fips == "32", adopt_year(1983) adopt_month(7)
frac_value alr if state_fips == "16", adopt_year(1984) adopt_month(7)
frac_value alr if state_fips == "30", adopt_year(1984) adopt_month(10)
frac_value alr if state_fips == "08", adopt_year(1985) adopt_month(7)
frac_value alr if state_fips == "19", adopt_year(1986) adopt_month(1)
frac_value alr if state_fips == "49", adopt_year(1986) adopt_month(7)
frac_value alr if state_fips == "06", adopt_year(1990) adopt_month(1)
frac_value alr if state_fips == "53", adopt_year(1988) adopt_month(1)
frac_value alr if state_fips == "23", adopt_year(1988) adopt_month(1)
frac_value alr if state_fips == "50", adopt_year(1989) adopt_month(7)
frac_value alr if state_fips == "41", adopt_year(1989) adopt_month(1)
frac_value alr if state_fips == "04", adopt_year(1990) adopt_month(1)
frac_value alr if state_fips == "17", adopt_year(1986) adopt_month(1)
frac_value alr if state_fips == "20", adopt_year(1988) adopt_month(7)
frac_value alr if state_fips == "31", adopt_year(1989) adopt_month(1)
frac_value alr if state_fips == "37", adopt_year(1990) adopt_month(10)
frac_value alr if state_fips == "55", adopt_year(1988) adopt_month(1)
frac_value alr if state_fips == "15", adopt_year(1990) adopt_month(1)
frac_value alr if state_fips == "02", adopt_year(1989) adopt_month(1)
frac_value alr if state_fips == "12", adopt_year(1990) adopt_month(1)
frac_value alr if state_fips == "13", adopt_year(1991) adopt_month(7)
frac_value alr if state_fips == "26", adopt_year(1993) adopt_month(10)
frac_value alr if state_fips == "39", adopt_year(1993) adopt_month(7)
frac_value alr if state_fips == "48", adopt_year(1993) adopt_month(9)
frac_value alr if state_fips == "51", adopt_year(1995) adopt_month(7)
frac_value alr if state_fips == "18", adopt_year(1996) adopt_month(7)
frac_value alr if state_fips == "01", adopt_year(1996) adopt_month(7)
frac_value alr if state_fips == "45", adopt_year(1998) adopt_month(7)
frac_value alr if state_fips == "05", adopt_year(1997) adopt_month(8)
frac_value alr if state_fips == "24", adopt_year(1997) adopt_month(10)
frac_value alr if state_fips == "47", adopt_year(1997) adopt_month(7)
frac_value alr if state_fips == "33", adopt_year(1993) adopt_month(1)
frac_value alr if state_fips == "44", adopt_year(1994) adopt_month(7)
frac_value alr if state_fips == "10", adopt_year(1996) adopt_month(1)
frac_value alr if state_fips == "34", adopt_year(1994) adopt_month(1)
frac_value alr if state_fips == "22", adopt_year(1995) adopt_month(8)
frac_value alr if state_fips == "28", adopt_year(1995) adopt_month(7)
frac_value alr if state_fips == "40", adopt_year(1997) adopt_month(11)
frac_value alr if state_fips == "36", adopt_year(1994) adopt_month(11)
frac_value alr if state_fips == "09", adopt_year(1995) adopt_month(10)
frac_value alr if state_fips == "25", adopt_year(1994) adopt_month(1)
frac_value alr if state_fips == "42", adopt_year(1994) adopt_month(7)
frac_value alr if state_fips == "38", adopt_year(1995) adopt_month(8)
frac_value alr if state_fips == "46", adopt_year(1996) adopt_month(7)
frac_value alr if state_fips == "21", adopt_year(1996) adopt_month(7)
frac_value alr if state_fips == "29", adopt_year(1996) adopt_month(7)
frac_value alr if state_fips == "56", adopt_year(1997) adopt_month(7)

* Zero Tolerance (<0.02 BAC for under 21)
frac_value zero_tolerance if state_fips == "23", adopt_year(1983) adopt_month(1)
frac_value zero_tolerance if state_fips == "49", adopt_year(1983) adopt_month(1)
frac_value zero_tolerance if state_fips == "27", adopt_year(1991) adopt_month(8)
frac_value zero_tolerance if state_fips == "04", adopt_year(1992) adopt_month(1)
frac_value zero_tolerance if state_fips == "35", adopt_year(1993) adopt_month(7)
frac_value zero_tolerance if state_fips == "39", adopt_year(1993) adopt_month(7)
frac_value zero_tolerance if state_fips == "31", adopt_year(1993) adopt_month(1)
frac_value zero_tolerance if state_fips == "06", adopt_year(1994) adopt_month(1)
frac_value zero_tolerance if state_fips == "24", adopt_year(1994) adopt_month(10)
frac_value zero_tolerance if state_fips == "26", adopt_year(1994) adopt_month(10)
frac_value zero_tolerance if state_fips == "54", adopt_year(1994) adopt_month(6)
frac_value zero_tolerance if state_fips == "08", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "09", adopt_year(1995) adopt_month(10)
frac_value zero_tolerance if state_fips == "10", adopt_year(1995) adopt_month(1)
frac_value zero_tolerance if state_fips == "16", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "17", adopt_year(1995) adopt_month(1)
frac_value zero_tolerance if state_fips == "19", adopt_year(1995) adopt_month(5)
frac_value zero_tolerance if state_fips == "25", adopt_year(1995) adopt_month(1)
frac_value zero_tolerance if state_fips == "28", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "30", adopt_year(1995) adopt_month(10)
frac_value zero_tolerance if state_fips == "32", adopt_year(1995) adopt_month(10)
frac_value zero_tolerance if state_fips == "33", adopt_year(1995) adopt_month(1)
frac_value zero_tolerance if state_fips == "34", adopt_year(1995) adopt_month(1)
frac_value zero_tolerance if state_fips == "37", adopt_year(1995) adopt_month(12)
frac_value zero_tolerance if state_fips == "38", adopt_year(1995) adopt_month(8)
frac_value zero_tolerance if state_fips == "41", adopt_year(1995) adopt_month(10)
frac_value zero_tolerance if state_fips == "42", adopt_year(1995) adopt_month(2)
frac_value zero_tolerance if state_fips == "44", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "46", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "47", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "50", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "53", adopt_year(1995) adopt_month(1)
frac_value zero_tolerance if state_fips == "55", adopt_year(1995) adopt_month(1)
frac_value zero_tolerance if state_fips == "56", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "05", adopt_year(1995) adopt_month(7)
frac_value zero_tolerance if state_fips == "01", adopt_year(1996) adopt_month(10)
frac_value zero_tolerance if state_fips == "02", adopt_year(1996) adopt_month(9)
frac_value zero_tolerance if state_fips == "12", adopt_year(1996) adopt_month(1)
frac_value zero_tolerance if state_fips == "15", adopt_year(1996) adopt_month(6)
frac_value zero_tolerance if state_fips == "20", adopt_year(1996) adopt_month(7)
frac_value zero_tolerance if state_fips == "21", adopt_year(1996) adopt_month(7)
frac_value zero_tolerance if state_fips == "29", adopt_year(1996) adopt_month(1)
frac_value zero_tolerance if state_fips == "36", adopt_year(1996) adopt_month(11)
frac_value zero_tolerance if state_fips == "40", adopt_year(1996) adopt_month(9)
frac_value zero_tolerance if state_fips == "51", adopt_year(1996) adopt_month(7)
frac_value zero_tolerance if state_fips == "13", adopt_year(1997) adopt_month(7)
frac_value zero_tolerance if state_fips == "22", adopt_year(1997) adopt_month(8)
frac_value zero_tolerance if state_fips == "48", adopt_year(1997) adopt_month(9)
frac_value zero_tolerance if state_fips == "18", adopt_year(1998) adopt_month(7)
frac_value zero_tolerance if state_fips == "45", adopt_year(1998) adopt_month(7)

* MLDA 21
frac_value mlda21 if state_fips == "26", adopt_year(1978) adopt_month(12)
frac_value mlda21 if state_fips == "17", adopt_year(1980) adopt_month(1)
frac_value mlda21 if state_fips == "24", adopt_year(1982) adopt_month(7)
frac_value mlda21 if state_fips == "34", adopt_year(1983) adopt_month(1)
frac_value mlda21 if state_fips == "40", adopt_year(1983) adopt_month(9)
frac_value mlda21 if state_fips == "02", adopt_year(1984) adopt_month(1)
frac_value mlda21 if state_fips == "05", adopt_year(1984) adopt_month(1)
frac_value mlda21 if state_fips == "10", adopt_year(1984) adopt_month(1)
frac_value mlda21 if state_fips == "06", adopt_year(1984) adopt_month(1)
frac_value mlda21 if state_fips == "18", adopt_year(1984) adopt_month(7)
frac_value mlda21 if state_fips == "25", adopt_year(1984) adopt_month(6)
frac_value mlda21 if state_fips == "32", adopt_year(1984) adopt_month(7)
frac_value mlda21 if state_fips == "35", adopt_year(1984) adopt_month(7)
frac_value mlda21 if state_fips == "41", adopt_year(1984) adopt_month(4)
frac_value mlda21 if state_fips == "42", adopt_year(1984) adopt_month(1)
frac_value mlda21 if state_fips == "44", adopt_year(1984) adopt_month(7)
frac_value mlda21 if state_fips == "47", adopt_year(1984) adopt_month(8)
frac_value mlda21 if state_fips == "53", adopt_year(1984) adopt_month(1)
frac_value mlda21 if state_fips == "01", adopt_year(1985) adopt_month(9)
frac_value mlda21 if state_fips == "04", adopt_year(1985) adopt_month(8)
frac_value mlda21 if state_fips == "09", adopt_year(1985) adopt_month(10)
frac_value mlda21 if state_fips == "12", adopt_year(1985) adopt_month(7)
frac_value mlda21 if state_fips == "13", adopt_year(1985) adopt_month(9)
frac_value mlda21 if state_fips == "20", adopt_year(1985) adopt_month(7)
frac_value mlda21 if state_fips == "23", adopt_year(1985) adopt_month(1)
frac_value mlda21 if state_fips == "29", adopt_year(1985) adopt_month(7)
frac_value mlda21 if state_fips == "31", adopt_year(1985) adopt_month(1)
frac_value mlda21 if state_fips == "33", adopt_year(1985) adopt_month(6)
frac_value mlda21 if state_fips == "36", adopt_year(1985) adopt_month(12)
frac_value mlda21 if state_fips == "49", adopt_year(1985) adopt_month(7)
frac_value mlda21 if state_fips == "51", adopt_year(1985) adopt_month(7)
frac_value mlda21 if state_fips == "15", adopt_year(1986) adopt_month(9)
frac_value mlda21 if state_fips == "19", adopt_year(1986) adopt_month(4)
frac_value mlda21 if state_fips == "21", adopt_year(1986) adopt_month(7)
frac_value mlda21 if state_fips == "27", adopt_year(1986) adopt_month(9)
frac_value mlda21 if state_fips == "28", adopt_year(1986) adopt_month(10)
frac_value mlda21 if state_fips == "37", adopt_year(1986) adopt_month(9)
frac_value mlda21 if state_fips == "45", adopt_year(1986) adopt_month(9)
frac_value mlda21 if state_fips == "48", adopt_year(1986) adopt_month(9)
frac_value mlda21 if state_fips == "50", adopt_year(1986) adopt_month(7)
frac_value mlda21 if state_fips == "54", adopt_year(1986) adopt_month(7)
frac_value mlda21 if state_fips == "55", adopt_year(1986) adopt_month(9)
frac_value mlda21 if state_fips == "08", adopt_year(1987) adopt_month(7)
frac_value mlda21 if state_fips == "16", adopt_year(1987) adopt_month(4)
frac_value mlda21 if state_fips == "22", adopt_year(1987) adopt_month(9)
frac_value mlda21 if state_fips == "30", adopt_year(1987) adopt_month(4)
frac_value mlda21 if state_fips == "39", adopt_year(1987) adopt_month(7)
frac_value mlda21 if state_fips == "46", adopt_year(1988) adopt_month(4)
frac_value mlda21 if state_fips == "56", adopt_year(1988) adopt_month(7)

* GDL (Graduated Driver Licensing)
frac_value gdl if state_fips == "12", adopt_year(1996) adopt_month(7)
frac_value gdl if state_fips == "26", adopt_year(1997) adopt_month(4)
frac_value gdl if state_fips == "37", adopt_year(1997) adopt_month(12)
frac_value gdl if state_fips == "13", adopt_year(1997) adopt_month(7)
frac_value gdl if state_fips == "06", adopt_year(1998) adopt_month(7)
frac_value gdl if state_fips == "22", adopt_year(1998) adopt_month(7)
frac_value gdl if state_fips == "45", adopt_year(1998) adopt_month(7)
frac_value gdl if state_fips == "25", adopt_year(1998) adopt_month(3)
frac_value gdl if state_fips == "08", adopt_year(1999) adopt_month(7)
frac_value gdl if state_fips == "10", adopt_year(1999) adopt_month(7)
frac_value gdl if state_fips == "18", adopt_year(1999) adopt_month(7)
frac_value gdl if state_fips == "24", adopt_year(1999) adopt_month(7)
frac_value gdl if state_fips == "39", adopt_year(1999) adopt_month(7)
frac_value gdl if state_fips == "48", adopt_year(1999) adopt_month(7)
frac_value gdl if state_fips == "51", adopt_year(1999) adopt_month(7)
frac_value gdl if state_fips == "17", adopt_year(1999) adopt_month(7)
frac_value gdl if state_fips == "04", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "20", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "35", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "36", adopt_year(2000) adopt_month(9)
frac_value gdl if state_fips == "41", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "55", adopt_year(2000) adopt_month(9)
frac_value gdl if state_fips == "28", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "15", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "16", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "19", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "21", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "23", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "27", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "30", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "05", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "29", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "34", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "47", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "53", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "01", adopt_year(2002) adopt_month(7)
frac_value gdl if state_fips == "31", adopt_year(2000) adopt_month(7)
frac_value gdl if state_fips == "32", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "33", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "38", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "40", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "42", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "44", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "46", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "49", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "50", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "54", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "56", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "02", adopt_year(2001) adopt_month(7)
frac_value gdl if state_fips == "09", adopt_year(2001) adopt_month(7)

* Speed Limit >= 70 mph
frac_value speed_70 if state_fips == "04", adopt_year(1987) adopt_month(12)
frac_value speed_70 if state_fips == "16", adopt_year(1987) adopt_month(5)
frac_value speed_70 if state_fips == "32", adopt_year(1987) adopt_month(12)
frac_value speed_70 if state_fips == "48", adopt_year(1987) adopt_month(12)
frac_value speed_70 if state_fips == "49", adopt_year(1987) adopt_month(1)
frac_value speed_70 if state_fips == "56", adopt_year(1987) adopt_month(1)
frac_value speed_70 if state_fips == "01", adopt_year(1996) adopt_month(3)
frac_value speed_70 if state_fips == "05", adopt_year(1996) adopt_month(5)
frac_value speed_70 if state_fips == "06", adopt_year(1996) adopt_month(1)
frac_value speed_70 if state_fips == "08", adopt_year(1996) adopt_month(5)
frac_value speed_70 if state_fips == "12", adopt_year(1996) adopt_month(3)
frac_value speed_70 if state_fips == "13", adopt_year(1996) adopt_month(7)
frac_value speed_70 if state_fips == "18", adopt_year(1996) adopt_month(7)
frac_value speed_70 if state_fips == "19", adopt_year(1996) adopt_month(4)
frac_value speed_70 if state_fips == "20", adopt_year(1996) adopt_month(4)
frac_value speed_70 if state_fips == "21", adopt_year(1996) adopt_month(6)
frac_value speed_70 if state_fips == "26", adopt_year(1996) adopt_month(2)
frac_value speed_70 if state_fips == "28", adopt_year(1996) adopt_month(5)
frac_value speed_70 if state_fips == "29", adopt_year(1996) adopt_month(5)
frac_value speed_70 if state_fips == "31", adopt_year(1996) adopt_month(4)
frac_value speed_70 if state_fips == "35", adopt_year(1996) adopt_month(5)
frac_value speed_70 if state_fips == "37", adopt_year(1996) adopt_month(8)
frac_value speed_70 if state_fips == "38", adopt_year(1996) adopt_month(8)
frac_value speed_70 if state_fips == "40", adopt_year(1996) adopt_month(5)
frac_value speed_70 if state_fips == "46", adopt_year(1996) adopt_month(4)
frac_value speed_70 if state_fips == "51", adopt_year(1996) adopt_month(7)
frac_value speed_70 if state_fips == "53", adopt_year(1996) adopt_month(6)
frac_value speed_70 if state_fips == "22", adopt_year(1997) adopt_month(6)
frac_value speed_70 if state_fips == "27", adopt_year(1997) adopt_month(6)
frac_value speed_70 if state_fips == "54", adopt_year(1997) adopt_month(6)
frac_value speed_70 if state_fips == "47", adopt_year(1998) adopt_month(1)
frac_value speed_70 if state_fips == "30", adopt_year(1999) adopt_month(5)
frac_value speed_70 if state_fips == "45", adopt_year(1999) adopt_month(6)

* Aggravated DUI
frac_value aggravated_dui if state_fips == "06", adopt_year(1982) adopt_month(1)
frac_value aggravated_dui if state_fips == "49", adopt_year(1983) adopt_month(1)
frac_value aggravated_dui if state_fips == "23", adopt_year(1988) adopt_month(1)
frac_value aggravated_dui if state_fips == "50", adopt_year(1991) adopt_month(1)
frac_value aggravated_dui if state_fips == "31", adopt_year(1993) adopt_month(1)
frac_value aggravated_dui if state_fips == "35", adopt_year(1993) adopt_month(7)
frac_value aggravated_dui if state_fips == "37", adopt_year(1993) adopt_month(12)
frac_value aggravated_dui if state_fips == "39", adopt_year(1993) adopt_month(7)
frac_value aggravated_dui if state_fips == "08", adopt_year(1994) adopt_month(7)
frac_value aggravated_dui if state_fips == "33", adopt_year(1994) adopt_month(7)
frac_value aggravated_dui if state_fips == "48", adopt_year(1995) adopt_month(9)
frac_value aggravated_dui if state_fips == "16", adopt_year(1997) adopt_month(7)
frac_value aggravated_dui if state_fips == "17", adopt_year(1998) adopt_month(1)
frac_value aggravated_dui if state_fips == "27", adopt_year(1998) adopt_month(8)
frac_value aggravated_dui if state_fips == "26", adopt_year(1999) adopt_month(10)
frac_value aggravated_dui if state_fips == "41", adopt_year(1999) adopt_month(10)
frac_value aggravated_dui if state_fips == "53", adopt_year(1999) adopt_month(7)
frac_value aggravated_dui if state_fips == "42", adopt_year(2000) adopt_month(2)
frac_value aggravated_dui if state_fips == "44", adopt_year(2000) adopt_month(7)
frac_value aggravated_dui if state_fips == "04", adopt_year(2001) adopt_month(9)
frac_value aggravated_dui if state_fips == "13", adopt_year(2001) adopt_month(7)
frac_value aggravated_dui if state_fips == "20", adopt_year(2001) adopt_month(7)
frac_value aggravated_dui if state_fips == "24", adopt_year(2001) adopt_month(10)
frac_value aggravated_dui if state_fips == "29", adopt_year(2001) adopt_month(7)
frac_value aggravated_dui if state_fips == "45", adopt_year(2001) adopt_month(6)
frac_value aggravated_dui if state_fips == "12", adopt_year(2002) adopt_month(1)
frac_value aggravated_dui if state_fips == "19", adopt_year(2002) adopt_month(7)
frac_value aggravated_dui if state_fips == "28", adopt_year(2002) adopt_month(7)
frac_value aggravated_dui if state_fips == "40", adopt_year(2002) adopt_month(7)
frac_value aggravated_dui if state_fips == "32", adopt_year(2003) adopt_month(10)
frac_value aggravated_dui if state_fips == "38", adopt_year(2003) adopt_month(8)
frac_value aggravated_dui if state_fips == "47", adopt_year(2003) adopt_month(7)
frac_value aggravated_dui if state_fips == "54", adopt_year(2003) adopt_month(7)
frac_value aggravated_dui if state_fips == "55", adopt_year(2003) adopt_month(12)
frac_value aggravated_dui if state_fips == "56", adopt_year(2003) adopt_month(7)
frac_value aggravated_dui if state_fips == "51", adopt_year(2004) adopt_month(7)
frac_value aggravated_dui if state_fips == "36", adopt_year(2006) adopt_month(11)

* Primary Seatbelt Law
frac_value primary_seatbelt if state_fips == "01", adopt_year(1999) adopt_month(12)
frac_value primary_seatbelt if state_fips == "02", adopt_year(2006) adopt_month(5)
frac_value primary_seatbelt if state_fips == "06", adopt_year(1993) adopt_month(1)
frac_value primary_seatbelt if state_fips == "09", adopt_year(1986) adopt_month(1)
frac_value primary_seatbelt if state_fips == "10", adopt_year(2003) adopt_month(6)
frac_value primary_seatbelt if state_fips == "13", adopt_year(1996) adopt_month(7)
frac_value primary_seatbelt if state_fips == "15", adopt_year(1985) adopt_month(12)
frac_value primary_seatbelt if state_fips == "17", adopt_year(2003) adopt_month(7)
frac_value primary_seatbelt if state_fips == "18", adopt_year(1998) adopt_month(7)
frac_value primary_seatbelt if state_fips == "19", adopt_year(1986) adopt_month(7)
frac_value primary_seatbelt if state_fips == "21", adopt_year(2006) adopt_month(7)
frac_value primary_seatbelt if state_fips == "22", adopt_year(1995) adopt_month(9)
frac_value primary_seatbelt if state_fips == "23", adopt_year(2007) adopt_month(9)
frac_value primary_seatbelt if state_fips == "24", adopt_year(1997) adopt_month(10)
frac_value primary_seatbelt if state_fips == "26", adopt_year(2000) adopt_month(4)
frac_value primary_seatbelt if state_fips == "28", adopt_year(2006) adopt_month(5)
frac_value primary_seatbelt if state_fips == "34", adopt_year(2000) adopt_month(5)
frac_value primary_seatbelt if state_fips == "35", adopt_year(1986) adopt_month(1)
frac_value primary_seatbelt if state_fips == "36", adopt_year(1984) adopt_month(12)
frac_value primary_seatbelt if state_fips == "37", adopt_year(2006) adopt_month(12)
frac_value primary_seatbelt if state_fips == "40", adopt_year(1997) adopt_month(11)
frac_value primary_seatbelt if state_fips == "41", adopt_year(1990) adopt_month(12)
frac_value primary_seatbelt if state_fips == "45", adopt_year(2005) adopt_month(12)
frac_value primary_seatbelt if state_fips == "47", adopt_year(2004) adopt_month(7)
frac_value primary_seatbelt if state_fips == "48", adopt_year(1985) adopt_month(9)
frac_value primary_seatbelt if state_fips == "53", adopt_year(2002) adopt_month(7)

* Secondary Seatbelt Law (any seatbelt law - used for non-primary)
frac_value secondary_seatbelt_any if state_fips == "01", adopt_year(1991) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "02", adopt_year(1990) adopt_month(9)
frac_value secondary_seatbelt_any if state_fips == "04", adopt_year(1991) adopt_month(1)
frac_value secondary_seatbelt_any if state_fips == "05", adopt_year(1991) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "06", adopt_year(1986) adopt_month(1)
frac_value secondary_seatbelt_any if state_fips == "08", adopt_year(1987) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "10", adopt_year(1992) adopt_month(1)
frac_value secondary_seatbelt_any if state_fips == "12", adopt_year(1986) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "13", adopt_year(1988) adopt_month(9)
frac_value secondary_seatbelt_any if state_fips == "16", adopt_year(1986) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "17", adopt_year(1988) adopt_month(1)
frac_value secondary_seatbelt_any if state_fips == "18", adopt_year(1987) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "20", adopt_year(1986) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "21", adopt_year(1994) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "22", adopt_year(1986) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "23", adopt_year(1995) adopt_month(12)
frac_value secondary_seatbelt_any if state_fips == "24", adopt_year(1986) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "25", adopt_year(1994) adopt_month(2)
frac_value secondary_seatbelt_any if state_fips == "26", adopt_year(1985) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "27", adopt_year(1986) adopt_month(8)
frac_value secondary_seatbelt_any if state_fips == "28", adopt_year(1994) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "29", adopt_year(1985) adopt_month(9)
frac_value secondary_seatbelt_any if state_fips == "30", adopt_year(1987) adopt_month(10)
frac_value secondary_seatbelt_any if state_fips == "31", adopt_year(1993) adopt_month(1)
frac_value secondary_seatbelt_any if state_fips == "32", adopt_year(1987) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "34", adopt_year(1985) adopt_month(3)
frac_value secondary_seatbelt_any if state_fips == "37", adopt_year(1985) adopt_month(10)
frac_value secondary_seatbelt_any if state_fips == "38", adopt_year(1994) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "39", adopt_year(1986) adopt_month(5)
frac_value secondary_seatbelt_any if state_fips == "40", adopt_year(1987) adopt_month(2)
frac_value secondary_seatbelt_any if state_fips == "42", adopt_year(1987) adopt_month(11)
frac_value secondary_seatbelt_any if state_fips == "44", adopt_year(1991) adopt_month(6)
frac_value secondary_seatbelt_any if state_fips == "45", adopt_year(1989) adopt_month(7)
frac_value secondary_seatbelt_any if state_fips == "46", adopt_year(1995) adopt_month(1)
frac_value secondary_seatbelt_any if state_fips == "47", adopt_year(1986) adopt_month(4)
frac_value secondary_seatbelt_any if state_fips == "49", adopt_year(1986) adopt_month(4)
frac_value secondary_seatbelt_any if state_fips == "50", adopt_year(1994) adopt_month(1)
frac_value secondary_seatbelt_any if state_fips == "51", adopt_year(1988) adopt_month(1)
frac_value secondary_seatbelt_any if state_fips == "53", adopt_year(1986) adopt_month(6)
frac_value secondary_seatbelt_any if state_fips == "54", adopt_year(1993) adopt_month(9)
frac_value secondary_seatbelt_any if state_fips == "55", adopt_year(1987) adopt_month(12)
frac_value secondary_seatbelt_any if state_fips == "56", adopt_year(1989) adopt_month(6)

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
* Download per capita income data from FRED
* =============================================================================
di "  Downloading per capita income data from FRED..."

* Save current data
tempfile main_data2
save `main_data2', replace

* Create empty income dataset
clear
gen state_fips = ""
gen year = .
gen income = .
tempfile income_data
save `income_data', replace

local income_list ALPCPI AKPCPI AZPCPI ARPCPI CAPCPI COPCPI CTPCPI DEPCPI FLPCPI GAPCPI HIPCPI IDPCPI ILPCPI INPCPI IAPCPI KSPCPI KYPCPI LAPCPI MEPCPI MDPCPI MAPCPI MIPCPI MNPCPI MSPCPI MOPCPI MTPCPI NEPCPI NVPCPI NHPCPI NJPCPI NMPCPI NYPCPI NCPCPI NDPCPI OHPCPI OKPCPI ORPCPI PAPCPI RIPCPI SCPCPI SDPCPI TNPCPI TXPCPI UTPCPI VTPCPI VAPCPI WAPCPI WVPCPI WIPCPI WYPCPI

local inc_downloaded = 0

forvalues i = 1/`n' {
    local fips : word `i' of `fips_list'
    local code : word `i' of `income_list'

    quietly di "    Downloading `code' for state `fips'..."

    local success = 0
    forvalues try = 1/3 {
        if `success' == 0 {
            capture noisily {
                local tempcsv "`tempdir'fred_`code'.csv"
                copy "https://fred.stlouisfed.org/graph/fredgraph.csv?id=`code'" "`tempcsv'", replace
                import delimited "`tempcsv'", clear varnames(1)
                capture erase "`tempcsv'"

                gen year = real(substr(observation_date, 1, 4))
                local lccode = lower("`code'")
                rename `lccode' income_val

                keep if year >= 1982 & year <= 2008
                collapse (mean) income = income_val, by(year)

                gen state_fips = "`fips'"

                append using `income_data'
                save `income_data', replace

                local inc_downloaded = `inc_downloaded' + 1
                local success = 1
            }
            if _rc != 0 & `try' < 3 {
                sleep 1000
            }
        }
    }
    if `success' == 0 {
        di "      Could not download `code' after 3 attempts"
    }
}

di "    Downloaded income data for `inc_downloaded' states"

* Merge income data back to main data
use `main_data2', clear
merge m:1 state_fips year using `income_data', nogen keep(master match)

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
      alr zero_tolerance primary_seatbelt secondary_seatbelt mlda21 gdl speed_70 aggravated_dui ///
      unemployment income

save "$build/output/analysis_data.dta", replace
export delimited "$build/output/analysis_data.csv", replace

local n_obs = _N
di "  Final dataset: `n_obs' observations"
di "  Saved to build/output/analysis_data.dta"
