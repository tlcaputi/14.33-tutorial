* ===========================================================================
* 01_filter_crashes.do
* Filter raw crash records to keep only fatal and serious crashes
* ===========================================================================
*
* Input:  build/input/crash_data.csv
* Output: build/output/crashes_filtered.dta
*
* This is the first step in the build pipeline. The raw crash data includes
* minor crashes, which we do not need for this analysis. We drop those here
* so that downstream scripts work with a cleaner, smaller dataset.
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
* 1. Import raw crash data
* ---------------------------------------------------------------------------

import delimited "$build/input/crash_data.csv", clear varnames(1)

* Quick check: how many raw records and what severities exist?
di "Raw crash records: " _N
tab severity


* ---------------------------------------------------------------------------
* 2. Keep only fatal and serious crashes
* ---------------------------------------------------------------------------
* Minor crashes are noise for our analysis of traffic safety policy effects.
* We keep only "fatal" and "serious" severity categories.

keep if inlist(severity, "fatal", "serious")

di "Records after filter: " _N


* ---------------------------------------------------------------------------
* 3. Save
* ---------------------------------------------------------------------------

save "$build/output/crashes_filtered.dta", replace

di "Saved: $build/output/crashes_filtered.dta"
