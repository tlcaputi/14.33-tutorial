********************************************************************************
* 03_EVENT_STUDY.DO
* Purpose: Event study analysis to visualize the dynamic effects of the policy
*          and test the parallel trends assumption.
*
*          An event study replaces the single post_treated indicator with a
*          vector of leads and lags relative to adoption. If pre-period
*          coefficients are near zero (parallel trends), we have confidence
*          the post-period estimates reflect causal effects.
*
*          Specification:
*            log(fatal_crashes + 1)_st
*              = Σ_{k≠-1} β_k * 1(time_to_treat = k)_st
*                + log_pop_st + α_s + γ_t + ε_st
*
*          where k ranges from ≤-5 to ≥5 (endpoints binned), and k=-1 is the
*          omitted reference period.
*
* Input:   $build/output/analysis_panel.dta
* Output:  $analysis/output/figures/event_study.png
*          $analysis/output/figures/event_study.pdf
*          $analysis/output/tables/event_study_coefs.tex
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

gen log_fatal = log(fatal_crashes + 1)

label variable log_fatal "Log Fatal Crashes"
label variable log_pop   "Log of Population"

********************************************************************************
* CREATE EVENT-TIME DUMMIES
* time_to_treat = year - adoption_year for treated states.
* Never-treated states cannot be assigned an event time, so we give them -99
* (a placeholder that will never match any dummy). This is the standard approach
* — it keeps never-treated observations in the regression as a comparison group
* without them contributing to any event-time cell.
*
* Naming convention:
*   rel_m5, rel_m4, ... = 5, 4, ... years BEFORE adoption (m = "minus")
*   rel_0, rel_1, ...   = 0, 1, ... years AFTER adoption
********************************************************************************

gen time_to_treat = year - adoption_year
replace time_to_treat = -99 if missing(adoption_year)

* Generate one dummy per event-time period
forvalues t = -5/5 {
    if `t' < 0 {
        local name "m`= abs(`t')'"   // e.g., t=-3 → rel_m3
    }
    else {
        local name "`t'"              // e.g., t=2  → rel_2
    }
    gen rel_`name' = (time_to_treat == `t')
}

* Bin the endpoints so extreme event times are absorbed.
* rel_m5 = 1 if the state-year is 5+ years before adoption.
* rel_5  = 1 if the state-year is 5+ years after adoption.
* This avoids losing many observations to "not estimated" cells.
replace rel_m5 = (time_to_treat <= -5) & !missing(adoption_year)
replace rel_5  = (time_to_treat >=  5) & !missing(adoption_year)

********************************************************************************
* EVENT STUDY REGRESSION
* We omit rel_m1 (t = -1) by not including it in the varlist.
* Stata treats the omitted period as the reference, so all coefficients
* are estimated relative to the year before adoption.
*
* We include log_pop as a control for time-varying state size.
* State and year fixed effects absorbed by reghdfe.
********************************************************************************

reghdfe log_fatal rel_m5 rel_m4 rel_m3 rel_m2 ///
    rel_0 rel_1 rel_2 rel_3 rel_4 rel_5 log_pop, ///
    absorb(state_fips year) vce(cluster state_fips)

estimates store event_study

* Test for parallel pre-trends: joint significance of pre-period coefficients.
* A large p-value gives us confidence in the parallel trends assumption.
di as text _n "Pre-trend test (H0: all pre-period coefficients = 0):"
testparm rel_m5 rel_m4 rel_m3 rel_m2

********************************************************************************
* BUILD COEFFICIENT DATASET FOR PLOTTING
* We extract the coefficient vector and variance matrix from e(), then
* construct a new dataset where each row is one event-time period.
* We manually add the omitted period (t=-1, coef=0, se=0) so the plot
* has a continuous x-axis.
********************************************************************************

* Capture estimates before clearing memory
matrix b = e(b)
matrix V = e(V)

preserve
clear
set obs 11    // 10 estimated periods + 1 omitted period

gen t    = .
gen coef = .
gen se   = .

* The column order in e(b) matches the varlist order:
*   1=rel_m5, 2=rel_m4, 3=rel_m3, 4=rel_m2, 5=rel_0, ..., 10=rel_5
local coefs "rel_m5 rel_m4 rel_m3 rel_m2 rel_0 rel_1 rel_2 rel_3 rel_4 rel_5"
local i = 1
foreach v of local coefs {
    * Map to the correct t value
    if `i' <= 4 {
        replace t = `i' - 6 in `i'    // positions 1-4 → t = -5,-4,-3,-2
    }
    else {
        replace t = `i' - 5 in `i'    // positions 5-10 → t = 0,1,2,3,4,5
    }
    replace coef = b[1, `i']          in `i'
    replace se   = sqrt(V[`i', `i'])  in `i'
    local i = `i' + 1
}

* Add the omitted reference period at t = -1
replace t    = -1 in 11
replace coef =  0 in 11
replace se   =  0 in 11

* Compute 95% confidence interval bounds
gen ub = coef + 1.96 * se
gen lb = coef - 1.96 * se

sort t

********************************************************************************
* EVENT STUDY PLOT
* Key design decisions:
*   - rarea creates the shaded confidence band (ribbon), which is easier to
*     read than whiskers, especially with overlapping periods.
*   - connected draws the point estimates with connecting lines.
*   - The vertical dashed line at x = -0.5 marks the adoption threshold.
*   - yline(0) provides a visual reference for zero effect.
*   - Color "44 95 138" is a professional muted blue (dark teal) that
*     reads well in both color and grayscale printing.
********************************************************************************

twoway (rarea ub lb t, color("44 95 138%20") lwidth(none)) ///
       (connected coef t, ///
            mcolor("44 95 138") lcolor("44 95 138") ///
            msize(small) msymbol(O) lwidth(medthin)), ///
    yline(0, lcolor(gs8) lwidth(thin)) ///
    xline(-0.5, lcolor(gs8) lwidth(thin) lpattern(dash)) ///
    xtitle("Years Relative to Policy Adoption", ///
           size(large) margin(t=3) color(gs5)) ///
    ytitle("") ///
    ylabel(, labsize(large) labcolor(gs5) grid glcolor(gs14) glwidth(vthin)) ///
    xlabel(-5(1)5, labsize(large) labcolor(gs5)) ///
    title("Effect on Log Fatal Crashes", ///
          position(11) size(large) color(gs5)) ///
    legend(off) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(small))

graph export "$analysis/output/figures/event_study.png", replace width(2400) height(1800)
graph export "$analysis/output/figures/event_study.pdf", replace

restore    // return to full panel dataset

********************************************************************************
* EXPORT COEFFICIENTS TABLE
* This gives readers the exact point estimates and standard errors from the
* plot in tabular form, which is standard practice for event studies.
********************************************************************************

esttab event_study using "$analysis/output/tables/event_study_coefs.tex", ///
    replace ///
    keep(rel_*) ///
    coeflabels( ///
        rel_m5 "t = -5 (binned)" ///
        rel_m4 "t = -4" ///
        rel_m3 "t = -3" ///
        rel_m2 "t = -2" ///
        rel_0  "t = 0"  ///
        rel_1  "t = 1"  ///
        rel_2  "t = 2"  ///
        rel_3  "t = 3"  ///
        rel_4  "t = 4"  ///
        rel_5  "t = 5 (binned)" ///
    ) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0fc %9.3f)) ///
    title("Event Study Coefficients") ///
    addnotes("Reference period: t = -1 (omitted)" ///
             "State and year fixed effects included" ///
             "Standard errors clustered at state level")

di as text _n "Event study analysis complete."
di as text    "Figure: $analysis/output/figures/event_study.png"
di as text    "Table:  $analysis/output/tables/event_study_coefs.tex"
