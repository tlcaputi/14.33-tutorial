********************************************************************************
* 03_EVENT_STUDY.DO
* Purpose: Event study analysis to test parallel trends and dynamic effects
*          Uses shaded confidence bands (ribbons) instead of error bars
* Input: build/output/analysis_panel.dta
* Output: analysis/output/event_study.png, event_study_coefs.tex
********************************************************************************

clear all

use "$build/output/analysis_panel.dta", clear

label variable fatal_crashes "Fatal Crashes"
label variable log_pop "Log of Population"

********************************************************************************
* CREATE EVENT TIME DUMMIES
********************************************************************************

* Time to treatment (never-treated get a far-away value)
gen time_to_treat = year - adoption_year
replace time_to_treat = -99 if missing(adoption_year)

* Create dummies with intuitive names: rel_m5 ... rel_m1, rel_0 ... rel_5
forvalues t = -5/5 {
    if `t' < 0 {
        local name "m`= abs(`t')'"
    }
    else {
        local name "`t'"
    }
    gen rel_`name' = (time_to_treat == `t')
}

* Bin endpoints
replace rel_m5 = (time_to_treat <= -5) & !missing(adoption_year)
replace rel_5  = (time_to_treat >= 5)  & !missing(adoption_year)

********************************************************************************
* EVENT STUDY REGRESSION (omit t = -1)
********************************************************************************

reghdfe fatal_crashes rel_m5 rel_m4 rel_m3 rel_m2 ///
    rel_0 rel_1 rel_2 rel_3 rel_4 rel_5 log_pop, ///
    absorb(state_fips year) vce(cluster state_fips)

estimates store event_study

* Test pre-trends
testparm rel_m5 rel_m4 rel_m3 rel_m2

********************************************************************************
* EVENT STUDY PLOT — SHADED CONFIDENCE BANDS (RIBBONS)
********************************************************************************

* Extract coefficients and SEs into matrices
matrix b = e(b)
matrix V = e(V)

preserve
clear
set obs 11

* Map coefficients to event time
gen t = .
gen coef = .
gen se = .

local coefs "rel_m5 rel_m4 rel_m3 rel_m2 rel_0 rel_1 rel_2 rel_3 rel_4 rel_5"
local i = 1
foreach v of local coefs {
    if `i' <= 4 {
        replace t = `i' - 6 in `i'
    }
    else {
        replace t = `i' - 5 in `i'
    }
    replace coef = b[1, `i'] in `i'
    replace se = sqrt(V[`i', `i']) in `i'
    local i = `i' + 1
}

* Add omitted period (t = -1, coefficient = 0)
replace t = -1 in 11
replace coef = 0 in 11
replace se = 0 in 11

* 95% confidence interval
gen ub = coef + 1.96 * se
gen lb = coef - 1.96 * se

sort t

* Plot with shaded confidence bands
twoway (rarea ub lb t, color("44 95 138%20") lwidth(none)) ///
       (connected coef t, mcolor("44 95 138") lcolor("44 95 138") ///
            msize(small) msymbol(O) lwidth(medthin)), ///
    yline(0, lcolor(gs12) lwidth(vthin)) ///
    xline(-0.5, lcolor(gs12) lwidth(vthin) lpattern(dash)) ///
    xtitle("Years Relative to Policy Adoption", ///
           size(large) margin(t=3) color(gs5)) ///
    ytitle("") ///
    ylabel(, labsize(large) labcolor(gs5) grid glcolor(gs14) glwidth(vthin)) ///
    xlabel(-5(1)5, labsize(large) labcolor(gs5)) ///
    title("Effect on Fatal Crashes", ///
          position(11) size(large) color(gs5)) ///
    legend(off) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(small))

graph export "$analysis/output/event_study.png", replace width(2400) height(1800)
graph export "$analysis/output/event_study.pdf", replace

restore

********************************************************************************
* EXPORT COEFFICIENTS TABLE
********************************************************************************

esttab event_study using "$analysis/output/event_study_coefs.tex", ///
    replace ///
    keep(rel_*) ///
    coeflabels( ///
        rel_m5 "t = -5 (binned)" rel_m4 "t = -4" ///
        rel_m3 "t = -3" rel_m2 "t = -2" ///
        rel_0 "t = 0" rel_1 "t = 1" rel_2 "t = 2" ///
        rel_3 "t = 3" rel_4 "t = 4" ///
        rel_5 "t = 5 (binned)" ///
    ) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0fc %9.3f)) ///
    title("Event Study Coefficients") ///
    addnotes("Reference period: t = -1 (omitted)" ///
             "State and year fixed effects included" ///
             "Standard errors clustered at state level")

di as text _n "Event study analysis complete."
