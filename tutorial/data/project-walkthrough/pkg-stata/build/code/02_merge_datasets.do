********************************************************************************
* 02_MERGE_DATASETS.DO
* Purpose: Merge crash data with demographics, policy adoptions, and state names
* Input: build/output/crashes_state_year.dta
*        build/input/state_demographics.dta
*        build/input/policy_adoptions.csv
*        build/input/state_names.csv
* Output: build/output/analysis_panel.dta
********************************************************************************

clear all

* Convert CSVs to .dta for merging
import delimited "$build/input/policy_adoptions.csv", clear
save "$build/output/policy_adoptions.dta", replace

import delimited "$build/input/state_names.csv", clear
save "$build/output/state_names.dta", replace

* Load the main dataset and merge everything sequentially
use "$build/output/crashes_state_year.dta", clear

di as text _n "Starting with crashes_state_year.dta: " _N " observations"

********************************************************************************
* MERGE 1: State demographics (1:1 on state_fips and year)
********************************************************************************

di as text _n "Merging with state_demographics.dta..."

merge 1:1 state_fips year using "$build/input/state_demographics.dta", ///
    keep(match) nogen

di as text "After demographics merge: " _N " observations"

********************************************************************************
* MERGE 2: Policy adoptions (m:1 on state_fips)
********************************************************************************

di as text _n "Merging with policy_adoptions..."

merge m:1 state_fips using "$build/output/policy_adoptions.dta", ///
    keep(master match) nogen

di as text "After policy merge: " _N " observations"

********************************************************************************
* MERGE 3: State names (m:1 on state_fips)
********************************************************************************

di as text _n "Merging with state_names..."

merge m:1 state_fips using "$build/output/state_names.dta", ///
    keep(match) nogen

di as text "After state names merge: " _N " observations"

********************************************************************************
* CREATE ANALYSIS VARIABLES
********************************************************************************

* Create treatment indicator
gen treated = (year >= adoption_year & !missing(adoption_year))
label variable treated "Treatment indicator (post-adoption)"

* Create log population
gen log_pop = ln(population)
label variable log_pop "Log of population"

********************************************************************************
* LABEL AND ORGANIZE
********************************************************************************

* Label all variables
label variable fatal_crashes "Fatal Crashes"
label variable serious_crashes "Serious Crashes"
label variable total_crashes "Total Crashes"
label variable fatal_share "Fatal Share"
label variable population "Population"
label variable median_income "Median Income"
label variable pct_urban "Pct. Urban"
label variable state_fips "State FIPS"
label variable state_name "State Name"
label variable region "Census Region"
label variable year "Year"
label variable adoption_year "Policy Adoption Year"
label variable policy_adopted "Policy Adopted"

order state_fips state_name region year ///
      adoption_year treated ///
      total_crashes fatal_crashes serious_crashes fatal_share ///
      population log_pop median_income pct_urban

sort state_fips year

********************************************************************************
* VERIFICATION
********************************************************************************

di as text _n "=== FINAL DATASET SUMMARY ==="
describe
summarize

di as text _n "=== TREATMENT STATUS ==="
tab treated, missing

********************************************************************************
* SAVE
********************************************************************************

save "$build/output/analysis_panel.dta", replace

di as text _n "Successfully created analysis panel dataset" ///
           _n "Observations: " _N
