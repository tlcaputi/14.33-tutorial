* ===========================================================================
* 02_collapse_crashes.do
* Collapse crash records to counts by state, year, and severity
* ===========================================================================
*
* Input:  build/output/crashes_filtered.dta
* Output: build/output/crashes_collapsed.dta
*
* The filtered crash data is at the individual-crash level (one row per
* crash event). This script aggregates it to a state-year-severity panel
* by counting the number of crashes in each cell. The result is a long
* dataset with one row per (state_fips, year, severity) combination.
* ===========================================================================

* Setup — master.do sets these; uncomment below if running standalone
* cd "/path/to/pkg-stata"
if `"${root}"' == "" {
    clear all
    set more off
    global root "."
    global build "$root/build"
    global analysis "$root/analysis"
}

* ---------------------------------------------------------------------------
* 1. Load filtered crash data
* ---------------------------------------------------------------------------

use "$build/output/crashes_filtered.dta", clear

di "Crash records loaded: " _N


* ---------------------------------------------------------------------------
* 2. Count crashes by state, year, and severity
* ---------------------------------------------------------------------------
* We generate a constant equal to 1, then collapse by summing it. This is
* a clean idiom for counting rows within groups. The result is one row per
* (state_fips, year, severity) cell with n_crashes = number of crashes.

gen one = 1

collapse (sum) n_crashes = one, by(state_fips year severity)

di "State-year-severity cells: " _N

* Sanity check: each severity should appear for most state-years
tab severity


* ---------------------------------------------------------------------------
* 3. Save
* ---------------------------------------------------------------------------

save "$build/output/crashes_collapsed.dta", replace

di "Saved: $build/output/crashes_collapsed.dta"
