********************************************************************************
* 04_DD_TABLE.DO
* Purpose: Produce a professional multi-column DD results table demonstrating
*          robustness across specifications, subsamples, and outcomes.
*
*          This script shows how to organize results in a journal-style table:
*            - Multiple model specifications in parallel columns
*            - Clear dependent-variable groupings with \cmidrule
*            - Subsample variation (South vs. Non-South)
*            - Alternative outcome (serious crashes)
*
*          All models use levels (not logs) of crash outcomes so that
*          coefficients can be interpreted as crash counts.
*
* Models:
*   m1 — Fatal crashes, no controls
*   m2 — Fatal crashes, with controls (log_pop, median_income)
*   m3 — Fatal crashes, South states only
*   m4 — Fatal crashes, Non-South states only
*   m5 — Serious crashes, with controls
*
* Input:   $build/output/analysis_panel.dta
* Output:  $analysis/output/tables/dd_table.tex
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
* VARIABLE LABELS
* Labels appear in the esttab output as row headers.
* Use LaTeX math mode for symbols: \$ escapes the $ in Stata strings.
********************************************************************************

label variable post_treated   "Post \$\times\$ Treated"
label variable log_pop        "Log Population"
label variable median_income  "Median Income"

* Create numeric south indicator (reghdfe cannot filter on string variables)
gen south = (region == "South")

********************************************************************************
* MODEL 1: FATAL CRASHES — NO CONTROLS
* The parsimonious specification absorbs all time-invariant state differences
* (state FE) and all aggregate time trends (year FE). The coefficient on
* post_treated is identified from within-state, over-time variation.
********************************************************************************

reghdfe fatal_crashes post_treated, ///
    absorb(state_fips year) vce(cluster state_fips)

estadd local state_fe "Yes"
estadd local year_fe  "Yes"
estimates store m1

********************************************************************************
* MODEL 2: FATAL CRASHES — WITH CONTROLS
* Adding time-varying controls (population size, income) can reduce residual
* variance and improve precision, especially if controls are correlated with
* both treatment timing and outcomes.
********************************************************************************

reghdfe fatal_crashes post_treated log_pop median_income, ///
    absorb(state_fips year) vce(cluster state_fips)

estadd local state_fe "Yes"
estadd local year_fe  "Yes"
estimates store m2

********************************************************************************
* MODEL 3: FATAL CRASHES — SOUTH STATES ONLY
* Regional subsamples test whether the treatment effect is concentrated in
* particular areas. The South adopted distracted driving laws at different
* rates and may have different baseline driving behavior.
********************************************************************************

reghdfe fatal_crashes post_treated log_pop ///
    if south == 1, ///
    absorb(state_fips year) vce(cluster state_fips)

estadd local state_fe "Yes"
estadd local year_fe  "Yes"
estimates store m3

********************************************************************************
* MODEL 4: FATAL CRASHES — NON-SOUTH STATES ONLY
* Comparing m3 and m4 shows whether the effect is driven by Southern states
* or is broadly consistent across regions.
********************************************************************************

reghdfe fatal_crashes post_treated log_pop ///
    if south == 0, ///
    absorb(state_fips year) vce(cluster state_fips)

estadd local state_fe "Yes"
estadd local year_fe  "Yes"
estimates store m4

********************************************************************************
* MODEL 5: SERIOUS CRASHES — ALTERNATIVE OUTCOME
* Using a different severity measure (serious rather than fatal) tests whether
* the policy also reduced non-fatal but severe crashes. Consistent results
* across outcomes strengthen the causal interpretation.
********************************************************************************

reghdfe serious_crashes post_treated log_pop, ///
    absorb(state_fips year) vce(cluster state_fips)

estadd local state_fe "Yes"
estadd local year_fe  "Yes"
estimates store m5

********************************************************************************
* EXPORT PROFESSIONAL TABLE
* The prehead builds a header with:
*   - A "Dependent Variables" row using \multicolumn to group columns
*   - \cmidrule to draw partial horizontal rules under each group
*   - A "Sample" row identifying the estimation sample
*   - A "Model" row with column numbers (1) through (5)
*
* Column layout: l*{5}{c} = left-aligned row label + 5 centered columns
********************************************************************************

esttab m1 m2 m3 m4 m5 ///
    using "$analysis/output/tables/dd_table.tex", replace ///
    se(%9.3f) b(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nomtitles nonumbers ///
    label fragment ///
    prehead("\begin{tabular}{l*{5}{c}}" ///
            "\midrule \midrule" ///
            "Dependent Variables:" ///
            "& \multicolumn{4}{c}{Fatal Crashes}" ///
            "& \multicolumn{1}{c}{Serious Crashes}\\" ///
            "\cmidrule(lr){2-5} \cmidrule(lr){6-6}" ///
            "Sample: & All & All & South & Non-South & All\\" ///
            "Model:  & (1) & (2) & (3)   & (4)       & (5)\\" ///
            "\midrule" ///
            "\emph{Variables} \\") ///
    posthead("") ///
    prefoot("\midrule" ///
            "\emph{Fixed-effects} \\") ///
    stats(state_fe year_fe N r2, ///
        labels("State FE" "Year FE" ///
               "\midrule \emph{Fit statistics} \\ Observations" ///
               "R\$^2\$") ///
        fmt(%s %s %9.0fc %9.3f)) ///
    postfoot("\midrule \midrule" ///
             "\multicolumn{6}{l}{\emph{Clustered (state) standard-errors in parentheses}}\\" ///
             "\multicolumn{6}{l}{\emph{Signif. Codes: ***: 0.01, **: 0.05, *: 0.1}}\\" ///
             "\end{tabular}")

di as text _n "Multi-column DD table complete."
di as text    "Output: $analysis/output/tables/dd_table.tex"
