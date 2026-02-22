********************************************************************************
* 05_IV.DO
* Purpose: Instrumental variables analysis of class size on test scores.
*          Inspired by Angrist & Lavy (1999) who used Maimonides' Rule
*          (the Talmudic cap of 40 students per class) as an instrument.
*
*          The core problem with OLS: class size is endogenous. Parents who
*          care more about education may sort into smaller-class schools, and
*          schools may respond to lower-performing students by reducing class
*          size. Both create bias in OLS.
*
*          Strategy: Use school enrollment as an instrument for class size.
*          Enrollment shifts class size mechanically (more students → larger
*          classes) but is arguably unrelated to the error term in the
*          test-score equation conditional on student disadvantage rates.
*
*          We report four models to tell the full IV story:
*            (1) First Stage: Does enrollment predict class size?
*            (2) Reduced Form: Does enrollment affect test scores?
*            (3) 2SLS: IV estimate (LATE — local average treatment effect)
*            (4) OLS: Naive estimate (biased if endogenous)
*
* Input:   $analysis/code/iv_data.csv
* Output:  $analysis/output/tables/iv_results.tex
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

********************************************************************************
* IMPORT DATA
********************************************************************************

import delimited "$analysis/code/iv_data.csv", clear

* Verify that all required variables are present before proceeding
ds
foreach var in school_id class_size test_score enrollment pct_disadvantaged {
    capture confirm variable `var'
    if _rc {
        di as error "Required variable `var' not found in iv_data.csv"
        exit 111
    }
}

label variable class_size       "Class Size"
label variable test_score       "Test Score"
label variable enrollment       "Enrollment"
label variable pct_disadvantaged "Pct. Disadvantaged"

describe
summarize

********************************************************************************
* FIRST STAGE
* Regress the endogenous variable (class_size) on the instrument (enrollment)
* and controls. A strong first stage requires a large F-statistic (rule of
* thumb: F > 10). A weak first stage leads to biased 2SLS estimates that
* can be worse than OLS.
********************************************************************************

regress class_size enrollment pct_disadvantaged, vce(robust)

estimates store first_stage

* Report the F-statistic for the instrument (weak instrument test)
di as text _n "First stage F-test for instrument (enrollment):"
test enrollment

********************************************************************************
* REDUCED FORM
* Regress the outcome (test_score) directly on the instrument (enrollment).
* The reduced form shows the intent-to-treat effect of the instrument.
* The ratio of the reduced form to the first stage gives the IV estimate.
* If the reduced form is zero, 2SLS will be zero regardless of the first stage.
********************************************************************************

regress test_score enrollment pct_disadvantaged, vce(robust)

estimates store reduced_form

********************************************************************************
* OLS (BIASED BENCHMARK)
* We report OLS not as the answer, but as a benchmark to compare against 2SLS.
* If OLS > 2SLS in absolute value, this suggests upward omitted-variable bias
* (e.g., motivated parents choose small classes AND have higher-scoring kids).
* If OLS < 2SLS, this suggests downward bias (schools put struggling students
* in smaller remedial classes).
********************************************************************************

regress test_score class_size pct_disadvantaged, vce(robust)

estimates store ols

********************************************************************************
* 2SLS INSTRUMENTAL VARIABLES
* ivregress 2sls syntax:
*   depvar [exogenous vars] (endogenous = instruments), options
*
* The parentheses specify the first-stage equation:
*   class_size is instrumented by enrollment
*   pct_disadvantaged appears outside — it is exogenous
*
* We use ivregress 2sls (Stata's built-in IV command) rather than ivreg2
* (user-written) for portability. Both give identical 2SLS estimates.
********************************************************************************

ivregress 2sls test_score pct_disadvantaged ///
    (class_size = enrollment), ///
    vce(robust) first

estimates store iv_2sls

********************************************************************************
* EXPORT RESULTS TABLE
* Column order: First Stage | Reduced Form | 2SLS | OLS
* This ordering tells the causal story: instrument → endogenous → outcome.
* OLS goes last so readers can see the contrast with 2SLS.
********************************************************************************

esttab first_stage reduced_form iv_2sls ols ///
    using "$analysis/output/tables/iv_results.tex", ///
    replace ///
    label fragment ///
    order(class_size enrollment pct_disadvantaged) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nomtitles nonumbers ///
    prehead("\begin{tabular}{l*{4}{c}}" ///
            "\midrule \midrule" ///
            "Dependent Variable: & Class Size & \multicolumn{3}{c}{Test Score}\\" ///
            "\cmidrule(lr){2-2} \cmidrule(lr){3-5}" ///
            "Model: & First Stage & Reduced Form & 2SLS & OLS\\" ///
            "       & (1)         & (2)          & (3)  & (4)\\" ///
            "\midrule" ///
            "\emph{Variables} \\") ///
    posthead("") ///
    prefoot("\midrule" ///
            "\emph{Fit statistics} \\") ///
    stats(N r2, fmt(%9.0fc %9.3f) ///
          labels("Observations" "R\$^2\$")) ///
    postfoot("\midrule \midrule" ///
             "\multicolumn{5}{l}{\emph{Heteroskedasticity-robust standard-errors in parentheses}}\\" ///
             "\multicolumn{5}{l}{\emph{Instrument: School enrollment}}\\" ///
             "\multicolumn{5}{l}{\emph{Signif. Codes: ***: 0.01, **: 0.05, *: 0.1}}\\" ///
             "\end{tabular}")

di as text _n "IV analysis complete."
di as text    "Output: $analysis/output/tables/iv_results.tex"
