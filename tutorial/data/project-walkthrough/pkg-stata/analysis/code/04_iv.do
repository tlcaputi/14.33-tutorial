********************************************************************************
* 04_IV.DO
* Purpose: Instrumental variables analysis of class size on test scores
*          Inspired by Angrist & Lavy (1999) / Maimonides' Rule
* Input: analysis/code/iv_data.csv
* Output: IV regression results comparing OLS vs 2SLS
********************************************************************************

clear all

********************************************************************************
* IMPORT DATA
********************************************************************************

import delimited "$analysis/code/iv_data.csv", clear

* Verify required variables
ds
foreach var in school_id class_size test_score enrollment pct_disadvantaged {
    capture confirm variable `var'
    if _rc {
        di as error "Required variable `var' not found in iv_data.csv"
        exit 111
    }
}

* Label variables
label variable class_size "Class Size"
label variable test_score "Test Score"
label variable enrollment "Enrollment"
label variable pct_disadvantaged "Pct. Disadvantaged"

* Display summary statistics
describe
summarize

********************************************************************************
* FIRST STAGE: CLASS SIZE ON ENROLLMENT
********************************************************************************

regress class_size enrollment pct_disadvantaged, vce(robust)

estimates store first_stage

* Extract F-statistic for weak instrument test
test enrollment

********************************************************************************
* REDUCED FORM: TEST SCORE ON ENROLLMENT
********************************************************************************

regress test_score enrollment pct_disadvantaged, vce(robust)

estimates store reduced_form

********************************************************************************
* OLS REGRESSION (BIASED ESTIMATE)
********************************************************************************

regress test_score class_size pct_disadvantaged, vce(robust)

estimates store ols

********************************************************************************
* 2SLS INSTRUMENTAL VARIABLES REGRESSION
********************************************************************************

ivregress 2sls test_score pct_disadvantaged (class_size = enrollment), ///
    vce(robust) first

estimates store iv_2sls

********************************************************************************
* EXPORT RESULTS TABLE
********************************************************************************

* Check if esttab is installed
capture which esttab
if !_rc {
    esttab ols first_stage reduced_form iv_2sls ///
        using "$analysis/output/iv_results.tex", ///
        replace ///
        label fragment ///
        order(class_size enrollment pct_disadvantaged) ///
        b(%9.3f) se(%9.3f) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        nomtitles nonumbers ///
        prehead("\begin{tabular}{l*{4}{c}}" ///
                "\midrule \midrule" ///
                "Dependent Variable: & Test Score & Class Size & \multicolumn{2}{c}{Test Score}\\" ///
                "\cmidrule(lr){2-2} \cmidrule(lr){3-3} \cmidrule(lr){4-5}" ///
                "Model: & OLS & First Stage & Reduced Form & 2SLS\\" ///
                "& (1) & (2) & (3) & (4)\\" ///
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
}

di as text _n "IV analysis complete."
