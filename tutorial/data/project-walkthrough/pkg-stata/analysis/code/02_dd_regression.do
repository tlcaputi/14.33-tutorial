********************************************************************************
* 02_DD_REGRESSION.DO
* Purpose: Difference-in-differences analysis of policy impact
* Input: build/output/analysis_panel.dta
* Output: analysis/output/dd_results.tex
********************************************************************************

clear all

use "$build/output/analysis_panel.dta", clear

* Label variables
label variable treated "Treated"
label variable log_pop "Log Population"
label variable median_income "Median Income"
label variable fatal_crashes "Fatal Crashes"
label variable serious_crashes "Serious Crashes"

********************************************************************************
* REGRESSIONS
********************************************************************************

* Col 1: Main result
reghdfe fatal_crashes treated, absorb(state_fips year) vce(cluster state_fips)
estadd local state_fe "Yes"
estadd local year_fe "Yes"
estimates store m1

* Col 2: With controls
reghdfe fatal_crashes treated log_pop median_income, ///
    absorb(state_fips year) vce(cluster state_fips)
estadd local state_fe "Yes"
estadd local year_fe "Yes"
estimates store m2

* Col 3: South only
reghdfe fatal_crashes treated log_pop if region == "South", ///
    absorb(state_fips year) vce(cluster state_fips)
estadd local state_fe "Yes"
estadd local year_fe "Yes"
estimates store m3

* Col 4: Non-South
reghdfe fatal_crashes treated log_pop if region != "South", ///
    absorb(state_fips year) vce(cluster state_fips)
estadd local state_fe "Yes"
estadd local year_fe "Yes"
estimates store m4

* Col 5: Serious crashes as outcome
reghdfe serious_crashes treated log_pop, ///
    absorb(state_fips year) vce(cluster state_fips)
estadd local state_fe "Yes"
estadd local year_fe "Yes"
estimates store m5

********************************************************************************
* EXPORT TABLE
********************************************************************************

esttab m1 m2 m3 m4 m5 ///
    using "$analysis/output/dd_results.tex", replace ///
    se(%9.3f) b(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nomtitles nonumbers ///
    label fragment ///
    prehead("\begin{tabular}{l*{5}{c}}" ///
            "\midrule \midrule" ///
            "Dependent Variables: &\multicolumn{4}{c}{Fatal Crashes} &Serious\\" ///
            "\cmidrule(lr){2-5} \cmidrule(lr){6-6}" ///
            "Sample: & All & All & South & Non-South & All \\" ///
            "Model: & (1) & (2) & (3) & (4) & (5) \\" ///
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

esttab m1 m2 m3 m4 m5 ///
    using "$analysis/output/dd_results.csv", replace ///
    label se(%9.3f) b(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(state_fe year_fe N r2, fmt(%s %s %9.0fc %9.3f))

di as text _n "DD regression analysis complete."
