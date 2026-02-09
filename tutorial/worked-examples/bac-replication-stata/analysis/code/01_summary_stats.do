* 01_summary_stats.do - Summary statistics

use "$build/output/analysis_data.dta", clear

* Summary statistics table
* Include controls if available
capture confirm variable unemployment
local has_unemp = (_rc == 0)
capture confirm variable income
local has_income = (_rc == 0)

local extra_vars ""
if `has_unemp' local extra_vars "`extra_vars' unemployment"
if `has_income' local extra_vars "`extra_vars' income"

estpost summarize total_fatalities hr_fatalities nhr_fatalities ln_hr ln_nhr treated `extra_vars'

esttab using "$analysis/output/tables/summary_stats.csv", ///
    cells("count mean sd min max") replace plain

* Summary by treatment status
preserve
collapse (count) n_obs=year (mean) mean_hr=hr_fatalities mean_nhr=nhr_fatalities ///
         mean_ln_hr=ln_hr mean_ln_nhr=ln_nhr, by(treated)
export delimited "$analysis/output/tables/summary_by_treatment.csv", replace
restore

di "  Summary statistics saved"
