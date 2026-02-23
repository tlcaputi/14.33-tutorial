* ===========================================================================
* 03_reshape_crashes.do
* Reshape crash counts from long to wide (one row per state-year)
* ===========================================================================
*
* Input:  build/output/crashes_collapsed.dta
* Output: build/output/crashes_state_year.dta
*
* The collapsed crash data is in long format: one row per (state, year,
* severity). For merging with other datasets we need wide format: one row
* per (state, year) with separate columns for fatal and serious crash
* counts. This script also computes total crashes and the fatal share.
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
* 1. Load collapsed crash data (long format)
* ---------------------------------------------------------------------------

use "$build/output/crashes_collapsed.dta", clear

di "Long-format rows (state x year x severity): " _N


* ---------------------------------------------------------------------------
* 2. Reshape to wide format
* ---------------------------------------------------------------------------
* After reshape, each row is one (state_fips, year) pair with columns:
*   n_crashesfatal   — number of fatal crashes
*   n_crashesserious — number of serious crashes

reshape wide n_crashes, i(state_fips year) j(severity) string

di "Wide-format rows (state x year): " _N


* ---------------------------------------------------------------------------
* 3. Rename reshaped columns to clean names
* ---------------------------------------------------------------------------

rename n_crashesfatal   fatal_crashes
rename n_crashesserious serious_crashes


* ---------------------------------------------------------------------------
* 4. Fill missing values with 0
* ---------------------------------------------------------------------------
* Some state-year cells may have zero crashes of a given severity, which
* means those cells were missing after the reshape. Replace with 0.

replace fatal_crashes   = 0 if missing(fatal_crashes)
replace serious_crashes = 0 if missing(serious_crashes)


* ---------------------------------------------------------------------------
* 5. Compute derived variables
* ---------------------------------------------------------------------------

* Total crashes = fatal + serious
gen total_crashes = fatal_crashes + serious_crashes

* Fatal share = fatal crashes as a fraction of total crashes
* Set to missing when total is zero to avoid division by zero
gen fatal_share = fatal_crashes / total_crashes if total_crashes > 0

* Quick distributional check
summarize fatal_crashes serious_crashes total_crashes fatal_share


* ---------------------------------------------------------------------------
* 6. Label variables
* ---------------------------------------------------------------------------

label variable state_fips      "State FIPS code"
label variable year            "Year"
label variable fatal_crashes   "Number of fatal crashes"
label variable serious_crashes "Number of serious crashes"
label variable total_crashes   "Total crashes (fatal + serious)"
label variable fatal_share     "Fatal crashes as share of total crashes"


* ---------------------------------------------------------------------------
* 7. Sort and save
* ---------------------------------------------------------------------------

sort state_fips year

save "$build/output/crashes_state_year.dta", replace

di "Saved: $build/output/crashes_state_year.dta"
