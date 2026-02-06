* 01_summary_stats.do - Summary statistics

use "$build/output/analysis_data.dta", clear

* Summary statistics table
estpost summarize total_fatalities hr_fatalities nhr_fatalities ln_hr ln_nhr treated

esttab using "$analysis/output/tables/summary_stats.csv", ///
    cells("count mean sd min max") replace plain

* Summary by treatment status
preserve
collapse (count) n_obs=year (mean) mean_hr=hr_fatalities mean_nhr=nhr_fatalities ///
         mean_ln_hr=ln_hr mean_ln_nhr=ln_nhr, by(treated)
export delimited "$analysis/output/tables/summary_by_treatment.csv", replace
restore

di "  Summary statistics saved"
