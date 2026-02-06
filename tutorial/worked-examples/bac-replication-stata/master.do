/*==============================================================================
    Master Do-File: BAC Replication (French & Gumus 2024)

    This script downloads all data automatically and produces all tables
    and figures from the tutorial. Run time: ~15-20 minutes.

    Instructions:
    1. Open this file in Stata
    2. Change the root path below if needed (or use the auto-detect)
    3. Run the entire do-file (Ctrl+D or do "master.do")
    4. Wait ~15-20 minutes for data download and analysis
    5. Find results in analysis/output/
==============================================================================*/

clear all
set more off
set varabbrev off

* ============ SET PROJECT ROOT ============
* Try to auto-detect from current working directory
* If this doesn't work, manually set the path below
capture cd "`c(pwd)'"

* Check if we're in the right directory
capture confirm file "master.do"
if _rc != 0 {
    di as error "Please navigate to the bac-replication-stata directory first"
    di as error "Use: cd /path/to/bac-replication-stata"
    exit 198
}

global root "`c(pwd)'"
* ==========================================

* Define paths (don't change these)
global build    "$root/build"
global analysis "$root/analysis"

di ""
di "BAC Replication Package (Stata)"
di "================================"
di "Root directory: $root"
di ""

* Create directories
capture mkdir "$build/input"
capture mkdir "$build/input/fars"
capture mkdir "$build/output"
capture mkdir "$analysis/output"
capture mkdir "$analysis/output/tables"
capture mkdir "$analysis/output/figures"

* Check for required packages and install if needed
capture which reghdfe
if _rc != 0 {
    di "Installing reghdfe..."
    ssc install reghdfe, replace
}

capture which ftools
if _rc != 0 {
    di "Installing ftools..."
    ssc install ftools, replace
}

capture which coefplot
if _rc != 0 {
    di "Installing coefplot..."
    ssc install coefplot, replace
}

capture which estout
if _rc != 0 {
    di "Installing estout..."
    ssc install estout, replace
}

* Run the build scripts (data preparation)
di ""
di "[1/8] Downloading FARS data (1982-2008)..."
do "$build/code/01_download_fars.do"

di ""
di "[2/8] Cleaning FARS data..."
do "$build/code/02_clean_fars.do"

di ""
di "[3/8] Merging policy controls..."
do "$build/code/03_merge_controls.do"

* Run the analysis
di ""
di "[4/8] Computing summary statistics..."
do "$analysis/code/01_summary_stats.do"

di ""
di "[5/8] Running TWFE regression..."
do "$analysis/code/02_twfe_regression.do"

di ""
di "[6/8] Running event study..."
do "$analysis/code/03_event_study.do"

di ""
di "[7/8] Creating tables..."
do "$analysis/code/04_tables.do"

di ""
di "[8/8] Creating figures..."
do "$analysis/code/05_figures.do"

di ""
di "================================"
di "Done! All results saved to:"
di "  Tables: $analysis/output/tables/"
di "  Figures: $analysis/output/figures/"
