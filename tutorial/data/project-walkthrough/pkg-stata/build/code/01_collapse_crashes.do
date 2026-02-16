********************************************************************************
* 01_COLLAPSE_CRASHES.DO
* Purpose: Import crash-level data, filter, collapse, and reshape to state-year
* Input: build/input/crash_data.csv
* Output: build/output/crashes_state_year.dta
********************************************************************************

clear all

* Import crash-level data
import delimited "$build/input/crash_data.csv", clear

* Verify required variables exist
ds
foreach var in state_fips year severity {
    capture confirm variable `var'
    if _rc {
        di as error "Required variable `var' not found in crash_data.csv"
        exit 111
    }
}

* --- FILTER: Keep only fatal and serious crashes ---
* We drop minor crashes to focus on severe incidents
drop if severity == "minor"
di as text "After dropping minor crashes: " _N " observations"

* --- COLLAPSE: Count crashes by state-year-severity (long format) ---
gen one = 1
collapse (sum) n_crashes = one, by(state_fips year severity)

* --- RESHAPE: Wide so each severity type becomes its own column ---
reshape wide n_crashes, i(state_fips year) j(severity) string

* Rename for clarity
rename n_crashesfatal fatal_crashes
rename n_crashesserious serious_crashes

* Compute total and fatal share
gen total_crashes = fatal_crashes + serious_crashes
gen fatal_share = fatal_crashes / total_crashes

* Label variables
label variable state_fips "State FIPS code"
label variable year "Year"
label variable total_crashes "Total number of crashes"
label variable fatal_crashes "Number of fatal crashes"
label variable serious_crashes "Number of serious injury crashes"
label variable fatal_share "Share of crashes that are fatal"

* Sort and verify
sort state_fips year
describe
summarize

* Save collapsed dataset
save "$build/output/crashes_state_year.dta", replace

di as text _n "Successfully collapsed crash data to state-year level" ///
           _n "Output: crashes_state_year.dta" ///
           _n "Observations: " _N
