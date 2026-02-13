* 01_event_study.do -- TWFE and event study regressions
* =============================================================================

local root "`c(pwd)'"

use "`root'/build/output/analysis_data.dta", clear

* Log transform outcome
gen ln_fatalities = ln(fatalities)

* ── Simple TWFE ──────────────────────────────────────────────
reghdfe ln_fatalities treated unemployment income, absorb(state year) cluster(state)
display "    TWFE coefficient on treated: " _b[treated] " (SE: " _se[treated] ")"

* ── Event study ──────────────────────────────────────────────
* Bin endpoints
gen event_time_binned = event_time
replace event_time_binned = -6 if event_time <= -6 & event_time != -1000
replace event_time_binned = 6 if event_time >= 6 & event_time != -1000

* Create dummies (excluding t=-1 as reference; never-treated get 0)
forvalues k = -6/6 {
    if `k' != -1 {
        local klab = cond(`k' < 0, "m" + string(abs(`k')), "p" + string(`k'))
        gen et_`klab' = (event_time_binned == `k') & (event_time != -1000)
    }
}

* Run event study
reghdfe ln_fatalities et_m6 et_m5 et_m4 et_m3 et_m2 ///
    et_p0 et_p1 et_p2 et_p3 et_p4 et_p5 et_p6 ///
    unemployment income, ///
    absorb(state year) cluster(state)

estimates store event_study

* ── Export coefficients to CSV ────────────────────────────────
* Write header
file open csvfile using "`root'/analysis/output/event_study_coefs.csv", write replace
file write csvfile "event_time,coefficient,std_error,ci_lower,ci_upper" _n

* Write each coefficient
foreach k in -6 -5 -4 -3 -2 0 1 2 3 4 5 6 {
    local klab = cond(`k' < 0, "m" + string(abs(`k')), "p" + string(`k'))
    local b = _b[et_`klab']
    local se = _se[et_`klab']
    local ci_lo = `b' - 1.96 * `se'
    local ci_hi = `b' + 1.96 * `se'
    file write csvfile "`k',`b',`se',`ci_lo',`ci_hi'" _n
}
file close csvfile

display "    Saved coefficients to `root'/analysis/output/event_study_coefs.csv"

* Print results table
display ""
display "    Event Study Coefficients:"
display "      Time       Coef         SE    CI Lower    CI Upper"
display "    " _dup(52) "-"
foreach k in -6 -5 -4 -3 -2 0 1 2 3 4 5 6 {
    local klab = cond(`k' < 0, "m" + string(abs(`k')), "p" + string(`k'))
    display "    " %6.0f `k' "  " %10.4f _b[et_`klab'] "  " %10.4f _se[et_`klab'] ///
            "  " %10.4f (_b[et_`klab'] - 1.96 * _se[et_`klab']) ///
            "  " %10.4f (_b[et_`klab'] + 1.96 * _se[et_`klab'])
}

* =============================================================================
* Alternative: Using xtevent for canonical event study
* =============================================================================
* xtevent simplifies event study estimation with automatic endpoint binning.
* Install: ssc install xtevent

* xtevent ln_fatalities unemployment income, ///
*     policyvar(treated) ///
*     panelvar(state) timevar(year) ///
*     window(6) ///
*     cluster(state)
* xteventplot, title("Event Study: Texting Bans (xtevent)")
