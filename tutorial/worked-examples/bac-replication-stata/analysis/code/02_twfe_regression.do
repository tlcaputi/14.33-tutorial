* 02_twfe_regression.do - Two-Way Fixed Effects regression

use "$build/output/analysis_data.dta", clear

* Check if unemployment data is available
capture confirm variable unemployment
local has_unemp = (_rc == 0)

* TWFE regression: Hit-and-run fatalities
di "  Running TWFE regression for hit-run fatalities..."
if `has_unemp' {
    reghdfe ln_hr treated unemployment, absorb(state_id year) cluster(state_id)
}
else {
    reghdfe ln_hr treated, absorb(state_id year) cluster(state_id)
}
est store hr_model

* Store results
local hr_coef = _b[treated]
local hr_se = _se[treated]
local hr_t = _b[treated] / _se[treated]
local hr_pval = 2 * ttail(e(df_r), abs(`hr_t'))
local hr_nobs = e(N)
local hr_r2 = e(r2_a)

* TWFE regression: Non-hit-and-run fatalities (placebo)
di "  Running TWFE regression for non-hit-run fatalities..."
if `has_unemp' {
    reghdfe ln_nhr treated unemployment, absorb(state_id year) cluster(state_id)
}
else {
    reghdfe ln_nhr treated, absorb(state_id year) cluster(state_id)
}
est store nhr_model

* Store results
local nhr_coef = _b[treated]
local nhr_se = _se[treated]
local nhr_t = _b[treated] / _se[treated]
local nhr_pval = 2 * ttail(e(df_r), abs(`nhr_t'))
local nhr_nobs = e(N)
local nhr_r2 = e(r2_a)

* Save results to CSV
preserve
clear
set obs 2
gen outcome = ""
gen coefficient = .
gen std_error = .
gen pvalue = .
gen n_obs = .
gen r2 = .

replace outcome = "Hit-Run" in 1
replace coefficient = `hr_coef' in 1
replace std_error = `hr_se' in 1
replace pvalue = `hr_pval' in 1
replace n_obs = `hr_nobs' in 1
replace r2 = `hr_r2' in 1

replace outcome = "Non-Hit-Run" in 2
replace coefficient = `nhr_coef' in 2
replace std_error = `nhr_se' in 2
replace pvalue = `nhr_pval' in 2
replace n_obs = `nhr_nobs' in 2
replace r2 = `nhr_r2' in 2

export delimited "$analysis/output/tables/twfe_results.csv", replace
restore

* Print results
di ""
di "  TWFE Results:"
di "  ============================================================"
di "                           Coefficient    Std Error     p-value"
di "  ------------------------------------------------------------"
di "  Hit-Run:             " %12.4f `hr_coef' "  " %12.4f `hr_se' "  " %10.4f `hr_pval'
di "  Non-Hit-Run:         " %12.4f `nhr_coef' "  " %12.4f `nhr_se' "  " %10.4f `nhr_pval'
di "  ============================================================"
