********************************************************************************
* MASTER DO FILE
* Project: Policy Impact Analysis - Stata Walkthrough
* Purpose: Run all build and analysis scripts in order
* Author: Project Walkthrough Package
********************************************************************************

clear all
set more off
set varabbrev off

* Set root directory (CHANGE THIS to your project path)
* global root "/path/to/your/pkg-stata"
global root "."

* Set subdirectories
global build "$root/build"
global analysis "$root/analysis"

* Check that we're in the right directory
cd "$root"

********************************************************************************
* BUILD STAGE
********************************************************************************

di as text _n "========================================" ///
           _n "RUNNING BUILD SCRIPTS" ///
           _n "========================================"

* 01: Collapse crash data to state-year level
di as text _n "Running 01_collapse_crashes.do..."
do "$build/code/01_collapse_crashes.do"

* 02: Merge all datasets together
di as text _n "Running 02_merge_datasets.do..."
do "$build/code/02_merge_datasets.do"

********************************************************************************
* ANALYSIS STAGE
********************************************************************************

di as text _n "========================================" ///
           _n "RUNNING ANALYSIS SCRIPTS" ///
           _n "========================================"

* 01: Create descriptive statistics table
di as text _n "Running 01_descriptive_table.do..."
do "$analysis/code/01_descriptive_table.do"

* 02: Difference-in-differences regression
di as text _n "Running 02_dd_regression.do..."
do "$analysis/code/02_dd_regression.do"

* 03: Event study analysis
di as text _n "Running 03_event_study.do..."
do "$analysis/code/03_event_study.do"

* 04: Instrumental variables analysis
di as text _n "Running 04_iv.do..."
do "$analysis/code/04_iv.do"

* 05: Regression discontinuity analysis
di as text _n "Running 05_rd.do..."
do "$analysis/code/05_rd.do"

********************************************************************************
* COMPLETE
********************************************************************************

di as text _n "========================================" ///
           _n "ALL SCRIPTS COMPLETED SUCCESSFULLY" ///
           _n "========================================"
