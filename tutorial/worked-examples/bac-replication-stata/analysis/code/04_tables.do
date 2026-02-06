* 04_tables.do - Publication tables

use "$build/output/analysis_data.dta", clear

* Run both specifications
reghdfe ln_hr treated unemployment, absorb(state_id year) cluster(state_id)
est store hr_model

reghdfe ln_nhr treated unemployment, absorb(state_id year) cluster(state_id)
est store nhr_model

* Export to LaTeX
esttab hr_model nhr_model using "$analysis/output/tables/table2_regression.tex", ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2_a, fmt(%9.0fc %9.3f) labels("Observations" "R-squared")) ///
    mtitles("Hit-Run" "Non-Hit-Run") ///
    title("Effect of 0.08 BAC Laws on Traffic Fatalities") ///
    addnotes("Standard errors clustered by state in parentheses.") ///
    replace

* Create event study table from saved coefficients
import delimited "$analysis/output/tables/es_coefficients_hr.csv", clear
rename (coefficient std_error) (hr_coef hr_se)
tempfile hr_coefs
save `hr_coefs', replace

import delimited "$analysis/output/tables/es_coefficients_nhr.csv", clear
rename (coefficient std_error) (nhr_coef nhr_se)

merge 1:1 event_time using `hr_coefs', nogen

* Export combined event study table
export delimited "$analysis/output/tables/table3_event_study.csv", replace

di "  Created LaTeX tables:"
di "    - table2_regression.tex"
di "    - table3_event_study.csv"
