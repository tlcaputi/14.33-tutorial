* ===========================================================================
* 06_merge_datasets.do
* Merge crash, demographics, policy, and state name data into analysis panel
* ===========================================================================
*
* Inputs:
*   build/output/crashes_state_year.dta       (from 03_reshape_crashes.do)
*   build/output/demographics_state_year.dta  (from 05_collapse_demographics.do)
*   build/input/policy_adoptions.csv
*   build/input/state_names.csv
*
* Output: build/output/analysis_panel.dta
*
* Merge logic:
*   crashes    ← 1:1 merge ← demographics      (match on state_fips year)
*   panel      ← m:1 merge ← policy_adoptions  (match on state_fips)
*   panel      ← m:1 merge ← state_names       (match on state_fips)
*
* After merging we construct the treatment indicators and derived variables
* needed for the difference-in-differences and other analyses.
* ===========================================================================

* Setup — master.do sets these globals. To run this script standalone,
* set `root` to the full path of the project folder (pkg-stata/).
if `"${root}"' == "" {
    clear all
    set more off
    global root "/path/to/pkg-stata"
    global build "$root/build"
    global analysis "$root/analysis"
    cd "$root"
}

* ---------------------------------------------------------------------------
* 1. Convert CSV crosswalk files to .dta
* ---------------------------------------------------------------------------
* policy_adoptions.csv: one row per state with the year it adopted the policy
*   (or missing if it never adopted).
* state_names.csv: maps state_fips to state name and region.

import delimited "$build/input/policy_adoptions.csv", clear varnames(1)
save "$build/output/policy_adoptions.dta", replace

import delimited "$build/input/state_names.csv", clear varnames(1)
save "$build/output/state_names.dta", replace


* ---------------------------------------------------------------------------
* 2. Load crash panel (base dataset for merges)
* ---------------------------------------------------------------------------

use "$build/output/crashes_state_year.dta", clear

di "Crash panel observations: " _N


* ---------------------------------------------------------------------------
* 3. Merge in demographics (1:1 on state_fips year)
* ---------------------------------------------------------------------------
* Both datasets should be at the same state-year level, so we expect a 1:1
* match. We keep only matched observations (keep(match)) to restrict to
* the state-years where we have complete data.

merge 1:1 state_fips year using "$build/output/demographics_state_year.dta", ///
    keep(match) nogen

di "After demographics merge: " _N " observations"


* ---------------------------------------------------------------------------
* 4. Merge in policy adoptions (m:1 on state_fips)
* ---------------------------------------------------------------------------
* policy_adoptions has one row per state. Many crash-panel rows (one per
* year) map to that single state row, so this is m:1. We use keep(master
* match) so states that never adopted the policy (and thus have no row in
* policy_adoptions) remain in the dataset with adoption_year == missing.

merge m:1 state_fips using "$build/output/policy_adoptions.dta", ///
    keep(master match) nogen

di "After policy merge: " _N " observations"


* ---------------------------------------------------------------------------
* 5. Merge in state names (m:1 on state_fips)
* ---------------------------------------------------------------------------
* All states in the panel should appear in state_names, so keep(match)
* is appropriate. This drops any phantom FIPS codes not in state_names.

merge m:1 state_fips using "$build/output/state_names.dta", ///
    keep(match) nogen

di "After state names merge: " _N " observations"


* ---------------------------------------------------------------------------
* 6. Construct treatment indicators
* ---------------------------------------------------------------------------

* ever_treated: 1 if the state ever adopted the policy, 0 otherwise
gen ever_treated = !missing(adoption_year)

* post_treated: 1 in years at or after adoption, for adopting states only
* This is the DiD interaction term (Treated × Post).
gen post_treated = (year >= adoption_year & ever_treated == 1)

tab ever_treated
tab post_treated


* ---------------------------------------------------------------------------
* 7. Construct derived variables
* ---------------------------------------------------------------------------

* Log population (used as a control and for per-capita outcomes)
gen log_pop = ln(population)


* ---------------------------------------------------------------------------
* 8. Label all variables
* ---------------------------------------------------------------------------

label variable state_fips      "State FIPS code"
label variable year            "Year"
label variable state_name      "State name"
label variable fatal_crashes   "Number of fatal crashes"
label variable serious_crashes "Number of serious crashes"
label variable total_crashes   "Total crashes (fatal + serious)"
label variable fatal_share     "Fatal crashes as share of total crashes"
label variable population      "Population (survey-weighted count)"
label variable median_income   "Median household income"
label variable pct_urban       "Share of population in urban area"
label variable adoption_year   "Year state adopted the policy (. = never)"
label variable ever_treated    "Ever-treated state (1 = adopted policy)"
label variable post_treated    "Post $\times$ Treated"
label variable log_pop         "Log population"


* ---------------------------------------------------------------------------
* 9. Order variables and save
* ---------------------------------------------------------------------------

order state_fips state_name year ///
    ever_treated adoption_year post_treated   ///
    fatal_crashes serious_crashes total_crashes fatal_share ///
    population log_pop median_income pct_urban

sort state_fips year

save "$build/output/analysis_panel.dta", replace

di "Saved: $build/output/analysis_panel.dta"
di "Final panel: " _N " observations"

* Clean up intermediate crosswalk .dta files
erase "$build/output/policy_adoptions.dta"
erase "$build/output/state_names.dta"
