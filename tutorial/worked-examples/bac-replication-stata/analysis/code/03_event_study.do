* 03_event_study.do - Event study specification

use "$build/output/analysis_data.dta", clear

* Bin event time at endpoints (-5 to +10)
gen event_time_binned = event_time
replace event_time_binned = -5 if event_time < -5
replace event_time_binned = 10 if event_time > 10

* Create event time dummies
* Shift to positive values for factor variable (add 6 so -5 becomes 1)
gen et_shifted = event_time_binned + 6

* Check if control variables are available
capture confirm variable unemployment
local has_unemp = (_rc == 0)
capture confirm variable income
local has_income = (_rc == 0)

* Policy controls are always present (created in build script)
local controls "alr zero_tolerance primary_seatbelt secondary_seatbelt mlda21 gdl speed_70 aggravated_dui"
if `has_unemp' local controls "`controls' unemployment"
if `has_income' local controls "`controls' income"

* Event study regression for hit-run
* Reference category is t=-1, which is et_shifted=5
di "  Running event study: ln_hr ~ event_time_dummies + FE"
reghdfe ln_hr ib5.et_shifted `controls', absorb(state_id year) cluster(state_id)
est store hr_es

* Extract coefficients for hit-run
preserve
clear
set obs 16  // -5 to +10 = 16 periods
gen event_time = _n - 6  // Convert back: 1->-5, 2->-4, ..., 16->10
gen coefficient = .
gen std_error = .
gen pvalue = .
gen ci_lower = .
gen ci_upper = .

* Fill in coefficients (reference period t=-1 is 0 by construction)
forvalues i = 1/16 {
    local et = `i' - 6
    if `et' != -1 {
        capture {
            replace coefficient = _b[`i'.et_shifted] if event_time == `et'
            replace std_error = _se[`i'.et_shifted] if event_time == `et'
            local t = _b[`i'.et_shifted] / _se[`i'.et_shifted]
            replace pvalue = 2 * ttail(e(df_r), abs(`t')) if event_time == `et'
            replace ci_lower = _b[`i'.et_shifted] - 1.96 * _se[`i'.et_shifted] if event_time == `et'
            replace ci_upper = _b[`i'.et_shifted] + 1.96 * _se[`i'.et_shifted] if event_time == `et'
        }
    }
}

* Set reference period to 0
replace coefficient = 0 if event_time == -1
replace std_error = 0 if event_time == -1
replace ci_lower = 0 if event_time == -1
replace ci_upper = 0 if event_time == -1

export delimited "$analysis/output/tables/es_coefficients_hr.csv", replace
restore

* Print hit-run results
di "  Event study coefficients (Hit-Run):"
forvalues et = -5/10 {
    local i = `et' + 6
    if `et' != -1 {
        capture {
            local coef = _b[`i'.et_shifted]
            local se = _se[`i'.et_shifted]
            local sig = ""
            if abs(`coef' / `se') > 1.96 local sig = "*"
            di "    t=" %3.0f `et' ": " %7.4f `coef' " (" %6.4f `se' ")" "`sig'"
        }
    }
    else {
        di "    t=" %3.0f `et' ":  0.0000 (0.0000) [reference]"
    }
}

* Event study regression for non-hit-run
di ""
di "  Running event study: ln_nhr ~ event_time_dummies + FE"
reghdfe ln_nhr ib5.et_shifted `controls', absorb(state_id year) cluster(state_id)
est store nhr_es

* Extract coefficients for non-hit-run
preserve
clear
set obs 16
gen event_time = _n - 6
gen coefficient = .
gen std_error = .
gen pvalue = .
gen ci_lower = .
gen ci_upper = .

forvalues i = 1/16 {
    local et = `i' - 6
    if `et' != -1 {
        capture {
            replace coefficient = _b[`i'.et_shifted] if event_time == `et'
            replace std_error = _se[`i'.et_shifted] if event_time == `et'
            local t = _b[`i'.et_shifted] / _se[`i'.et_shifted]
            replace pvalue = 2 * ttail(e(df_r), abs(`t')) if event_time == `et'
            replace ci_lower = _b[`i'.et_shifted] - 1.96 * _se[`i'.et_shifted] if event_time == `et'
            replace ci_upper = _b[`i'.et_shifted] + 1.96 * _se[`i'.et_shifted] if event_time == `et'
        }
    }
}

replace coefficient = 0 if event_time == -1
replace std_error = 0 if event_time == -1
replace ci_lower = 0 if event_time == -1
replace ci_upper = 0 if event_time == -1

export delimited "$analysis/output/tables/es_coefficients_nhr.csv", replace
restore

di "  Saved event study coefficients"

* =============================================================================
* Alternative: Using xtevent for canonical event study
* =============================================================================
* xtevent simplifies event study estimation.
* Install: ssc install xtevent

* xtevent ln_hr `controls', ///
*     policyvar(treated) ///
*     panelvar(state_id) timevar(year) ///
*     window(5 10) ///
*     cluster(state_id)
* xteventplot, title("Event Study: Hit-Run (xtevent)")

* xtevent ln_nhr `controls', ///
*     policyvar(treated) ///
*     panelvar(state_id) timevar(year) ///
*     window(5 10) ///
*     cluster(state_id)
* xteventplot, title("Event Study: Non-Hit-Run (xtevent)")
