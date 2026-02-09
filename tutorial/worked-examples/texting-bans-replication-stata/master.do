* =============================================================================
* Replication Package: Texting Bans and Traffic Fatalities
* =============================================================================
* Event study analysis of state texting-while-driving bans
* using FARS data (2007-2022).
*
* Requirements:
*   ssc install reghdfe
*   ssc install ftools
*
* Usage:
*   do master.do
* =============================================================================

clear all
set more off
set maxvar 10000

* Set root directory to location of this do-file
local root "`c(pwd)'"

* Create output directories
capture mkdir "`root'/build/output"
capture mkdir "`root'/build/output/fars_csvs"
capture mkdir "`root'/analysis/output"

display "============================================================"
display "Texting Bans and Traffic Fatalities -- Replication Package"
display "============================================================"

* ── Phase 1: Build data ─────────────────────────────────────
display ""
display "-- Phase 1: Building data --"

display ""
display "  [1/3] Running 01_download_fars.do..."
do "`root'/build/code/01_download_fars.do"

display ""
display "  [2/3] Running 02_clean_fars.do..."
do "`root'/build/code/02_clean_fars.do"

display ""
display "  [3/3] Running 03_merge_controls.do..."
do "`root'/build/code/03_merge_controls.do"

* ── Phase 2: Analysis ───────────────────────────────────────
display ""
display "-- Phase 2: Running analysis --"

display ""
display "  [1/2] Running 01_event_study.do..."
do "`root'/analysis/code/01_event_study.do"

display ""
display "  [2/2] Running 02_figures.do..."
do "`root'/analysis/code/02_figures.do"

* ── Summary ──────────────────────────────────────────────────
display ""
display "============================================================"
display "Complete! Output files:"
display "  `root'/analysis/output/event_study_coefs.csv"
display "  `root'/analysis/output/event_study.png"
display "============================================================"
