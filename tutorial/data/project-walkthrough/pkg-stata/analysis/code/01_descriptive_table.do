********************************************************************************
* 01_DESCRIPTIVE_TABLE.DO
* Purpose: Create descriptive statistics table comparing three groups:
*          (1) Treated states after policy adoption
*          (2) Treated states before policy adoption
*          (3) Never-treated (control) states
*
*          Uses dtable (Stata 18+) which formats cells as "mean (sd)"
*          automatically. We export a LaTeX tabular fragment — no \begin{table}
*          wrapper — so it can be \input{} directly into a paper.
*
* Input:   $build/output/analysis_panel.dta
* Output:  $analysis/output/tables/descriptive_table.tex
********************************************************************************

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

use "$build/output/analysis_panel.dta", clear

********************************************************************************
* CREATE GROUP VARIABLE
* We classify each state-year observation into one of three groups based on
* whether the state ever adopted the policy, and if so, whether the observation
* is before or after adoption.
********************************************************************************

gen group = 3 if missing(adoption_year)           // Never-treated states
replace group = 1 if !missing(adoption_year) & year >= adoption_year  // Post-adoption
replace group = 2 if !missing(adoption_year) & year <  adoption_year  // Pre-adoption

label define grp 1 "Treated After" 2 "Treated Before" 3 "Untreated"
label values group grp

* dtable needs factor variables, not strings — encode the region variable
encode region, gen(census_region)
label variable census_region "Census Region"

********************************************************************************
* VARIABLE LABELS
* dtable uses variable labels as row headers, so labels must be clean and
* human-readable. Never let raw variable names appear in the table.
********************************************************************************

label variable fatal_crashes   "Fatal Crashes"
label variable serious_crashes "Serious Crashes"
label variable total_crashes   "Total Crashes"
label variable fatal_share     "Fatal Share"
label variable population      "Population"
label variable median_income   "Median Income"
label variable pct_urban       "Pct. Urban"

********************************************************************************
* CREATE DESCRIPTIVE TABLE
* dtable syntax:
*   varlist        — variables to summarize (rows)
*   by(group)      — create separate columns per group; adds an "All" column
*   nformat(...)   — number format for mean and sd
*   sample(...)    — add a sample size row; place() controls where it appears
********************************************************************************

dtable fatal_crashes serious_crashes total_crashes ///
    fatal_share population median_income pct_urban, ///
    by(group) ///
    nformat(%14.2fc mean sd) ///
    sample(, statistics(freq) place(seplabels))

* Rename the automatically-generated "Total" column to "All"
collect label levels group .m "All", modify

* The "group" variable label would otherwise appear as a header above the
* column grouping — hide it so only the value labels appear.
collect style header group, title(hide)

********************************************************************************
* EXPORT LATEX FRAGMENT
* We first export the raw output (which includes \begin{table}...\end{table}),
* then use filefilter to strip the wrapper, leaving a pure tabular fragment
* suitable for \input{} in a paper.
********************************************************************************

collect export "$analysis/output/tables/descriptive_table_raw.tex", tableonly replace

* Strip \begin{table}[!h]
filefilter "$analysis/output/tables/descriptive_table_raw.tex" ///
    "$analysis/output/tables/descriptive_table_s1.tex", ///
    from("\BSbegin{table}[!h]") to("") replace

* Strip \centering
filefilter "$analysis/output/tables/descriptive_table_s1.tex" ///
    "$analysis/output/tables/descriptive_table_s2.tex", ///
    from("\BScentering") to("") replace

* Strip \end{table}
filefilter "$analysis/output/tables/descriptive_table_s2.tex" ///
    "$analysis/output/tables/descriptive_table.tex", ///
    from("\BSend{table}") to("") replace

* Remove intermediate temp files
erase "$analysis/output/tables/descriptive_table_raw.tex"
erase "$analysis/output/tables/descriptive_table_s1.tex"
erase "$analysis/output/tables/descriptive_table_s2.tex"

di as text _n "Descriptive table complete."
di as text    "Output: $analysis/output/tables/descriptive_table.tex"
