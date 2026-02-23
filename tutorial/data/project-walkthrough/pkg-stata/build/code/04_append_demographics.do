* ===========================================================================
* 04_append_demographics.do
* Append annual demographic survey files into a single combined dataset
* ===========================================================================
*
* Input:  build/input/demographic_survey/demographic_survey_YYYY.csv
*         (one file per year, 1995–2015)
* Output: build/output/demographics_combined.dta
*
* The demographic survey data arrives as separate CSV files, one per year.
* We first convert each CSV to a temporary .dta file (adding a year
* variable), then append all years into one long dataset and clean up the
* temporary files.
*
* Key concept: the append pattern (save each piece → append all) is safer
* than appending inside the loop because it avoids accidentally overwriting
* data mid-loop if something goes wrong.
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
* 1. Import each annual CSV and save as a temporary .dta file
* ---------------------------------------------------------------------------
* We loop over years, import the CSV, stamp a year variable, and save.
* This gives us a stable intermediate file for each year that the append
* loop can safely load without clobbering the in-memory dataset.

forvalues y = 1995/2015 {
    import delimited ///
        "$build/input/demographic_survey/demographic_survey_`y'.csv", ///
        clear varnames(1)
    gen year = `y'
    save "$build/output/survey_`y'.dta", replace
    di "Saved survey `y': " _N " observations"
}


* ---------------------------------------------------------------------------
* 2. Append all years into one dataset
* ---------------------------------------------------------------------------

clear

forvalues y = 1995/2015 {
    append using "$build/output/survey_`y'.dta"
}

di "Combined records across all years: " _N

* Quick check: verify all years are present
tab year


* ---------------------------------------------------------------------------
* 3. Save combined dataset
* ---------------------------------------------------------------------------

save "$build/output/demographics_combined.dta", replace

di "Saved: $build/output/demographics_combined.dta"


* ---------------------------------------------------------------------------
* 4. Clean up temporary per-year files
* ---------------------------------------------------------------------------
* Once the combined file is safely saved, remove the intermediate .dta
* files to keep the output folder tidy.

forvalues y = 1995/2015 {
    erase "$build/output/survey_`y'.dta"
}

di "Temporary per-year files erased."
