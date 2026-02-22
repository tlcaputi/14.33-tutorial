********************************************************************************
* 02_DD_REGRESSION.DO
* Purpose: Core difference-in-differences analysis of the policy's effect on
*          fatal crashes.
*
*          Specification:
*            log(fatal_crashes + 1)_st = β * post_treated_st
*                                       + α_s + γ_t + ε_st
*
*          where α_s are state fixed effects, γ_t are year fixed effects,
*          and post_treated = 1 for treated states in post-adoption years.
*
*          We estimate two models:
*            m1 — no controls (parsimonious, FE only)
*            m2 — with controls (log population, median income, pct urban)
*
* Input:   $build/output/analysis_panel.dta
* Output:  $analysis/output/tables/dd_results.tex
*          $analysis/output/tables/dd_results.csv
********************************************************************************

* Setup — master.do sets these; uncomment below if running standalone
* cd "/path/to/pkg-stata"
if `"${root}"' == "" {
    clear all
    set more off
    global root "."
    global build "$root/build"
    global analysis "$root/analysis"
}

use "$build/output/analysis_panel.dta", clear

********************************************************************************
* OUTCOME VARIABLE
* We use log(fatal_crashes + 1) as the dependent variable. The "+1" avoids
* taking the log of zero in state-years with no fatal crashes. The log
* transformation makes the coefficient interpretable as a percent change.
********************************************************************************

gen log_fatal = log(fatal_crashes + 1)

********************************************************************************
* VARIABLE LABELS
* esttab uses variable labels for the table rows — always label everything.
* The LaTeX string for the treatment indicator uses math mode for the × symbol.
********************************************************************************

label variable post_treated   "Post \$\times\$ Treated"
label variable log_pop        "Log Population"
label variable median_income  "Median Income"
label variable pct_urban      "Pct. Urban"
label variable log_fatal      "Log Fatal Crashes"

********************************************************************************
* REGRESSIONS
* reghdfe absorbs fixed effects and handles the within-transformation more
* efficiently than areg or xtreg for two-way FE models.
* vce(cluster state_fips) allows arbitrary serial correlation within states.
********************************************************************************

* Model 1: Treatment indicator only (state + year FE)
reghdfe log_fatal post_treated, ///
    absorb(state_fips year) vce(cluster state_fips)

estadd local state_fe "Yes"
estadd local year_fe  "Yes"
estimates store m1

* Model 2: Add time-varying state-level controls
* Controls: log population (size), median income (economic conditions),
*           pct urban (urbanization trends that affect crash rates)
reghdfe log_fatal post_treated log_pop median_income pct_urban, ///
    absorb(state_fips year) vce(cluster state_fips)

estadd local state_fe "Yes"
estadd local year_fe  "Yes"
estimates store m2

********************************************************************************
* EXPORT RESULTS TABLE
* esttab produces a LaTeX fragment directly. The prehead/postfoot options
* construct the full tabular environment so the output is a self-contained
* LaTeX fragment ready for \input{}.
*
* Table structure:
*   Row 1 (prehead): Dependent variable header spanning all columns
*   Row 2 (prehead): Sample description
*   Row 3 (prehead): Column numbers
*   Body:            Coefficients with standard errors
*   Prefoot:         Fixed effects rows (from estadd locals)
*   Postfoot:        N, R², closing rules, notes
********************************************************************************

esttab m1 m2 ///
    using "$analysis/output/tables/dd_results.tex", replace ///
    se(%9.3f) b(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nomtitles nonumbers ///
    label fragment ///
    prehead("\begin{tabular}{l*{2}{c}}" ///
            "\midrule \midrule" ///
            "Dependent Variable: & \multicolumn{2}{c}{Log Fatal Crashes}\\" ///
            "\cmidrule(lr){2-3}" ///
            "Sample: & All & All\\" ///
            "Model: & (1) & (2)\\" ///
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
             "\multicolumn{3}{l}{\emph{Clustered (state) standard-errors in parentheses}}\\" ///
             "\multicolumn{3}{l}{\emph{Signif. Codes: ***: 0.01, **: 0.05, *: 0.1}}\\" ///
             "\end{tabular}")

* Also export a CSV version for easy inspection
esttab m1 m2 ///
    using "$analysis/output/tables/dd_results.csv", replace ///
    label se(%9.3f) b(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(state_fe year_fe N r2, fmt(%s %s %9.0fc %9.3f))

di as text _n "DD regression analysis complete."
di as text    "Output: $analysis/output/tables/dd_results.tex"
