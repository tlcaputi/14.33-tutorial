* ===========================================================================
* master.do
* Master script — runs the full project pipeline from raw data to outputs
* ===========================================================================
*
* Usage:
*   1. Set the `root` path below to the location of this folder (pkg-stata/).
*   2. Run: do master.do
*
* Pipeline:
*   Build
*     01_filter_crashes.do         Filter raw crashes to fatal/serious only
*     02_collapse_crashes.do       Count crashes by state, year, severity
*     03_reshape_crashes.do        Reshape to wide (one row per state-year)
*     04_append_demographics.do    Stack annual demographic CSVs
*     05_collapse_demographics.do  Collapse survey data to state-year level
*     06_merge_datasets.do         Merge all sources into analysis panel
*
*   Analysis
*     01_descriptive_table.do      Summary statistics table
*     02_dd_regression.do          Difference-in-differences regression
*     03_event_study.do            Event study plot
*     04_dd_table.do               DiD results table
*     05_iv.do                     Instrumental variables regression
*     06_rd.do                     Regression discontinuity
* ===========================================================================

clear all
set more off
set varabbrev off

* ---------------------------------------------------------------------------
* Define global macros for directory paths
* ---------------------------------------------------------------------------
* All scripts reference $build and $analysis so that paths never need to
* be edited in individual scripts when the project is moved.

* >>> CHANGE THIS PATH to wherever you unzipped the project <<<
global root "/path/to/pkg-stata"

global build    "$root/build"
global analysis "$root/analysis"

cd "$root"


* ===========================================================================
* BUILD
* ===========================================================================

* Step 1: Filter raw crash records to fatal and serious only
do "$build/code/01_filter_crashes.do"

* Step 2: Collapse to crash counts by state, year, and severity
do "$build/code/02_collapse_crashes.do"

* Step 3: Reshape from long (state x year x severity) to wide (state x year)
do "$build/code/03_reshape_crashes.do"

* Step 4: Append annual demographic survey CSVs into one combined file
do "$build/code/04_append_demographics.do"

* Step 5: Clean and collapse survey microdata to state-year aggregates
do "$build/code/05_collapse_demographics.do"

* Step 6: Merge crashes, demographics, policy adoptions, and state names
do "$build/code/06_merge_datasets.do"


* ===========================================================================
* ANALYSIS
* ===========================================================================

* Step 1: Descriptive statistics table
do "$analysis/code/01_descriptive_table.do"

* Step 2: Difference-in-differences regression
do "$analysis/code/02_dd_regression.do"

* Step 3: Event study plot
do "$analysis/code/03_event_study.do"

* Step 4: DiD results table
do "$analysis/code/04_dd_table.do"

* Step 5: Instrumental variables
do "$analysis/code/05_iv.do"

* Step 6: Regression discontinuity
do "$analysis/code/06_rd.do"

di ""
di "============================================="
di " master.do complete -- all scripts finished."
di "============================================="
