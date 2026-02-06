* 05_figures.do - Publication figures

* Load hit-run coefficients
import delimited "$analysis/output/tables/es_coefficients_hr.csv", clear

* Figure 1: Hit-and-Run Event Study
twoway (rcap ci_lower ci_upper event_time, lcolor(steelblue)) ///
       (connected coefficient event_time, mcolor(steelblue) lcolor(steelblue) msymbol(O)), ///
       yline(0, lcolor(gray) lpattern(dash)) ///
       xline(-0.5, lcolor(red) lpattern(dash)) ///
       title("Event Study: Hit-and-Run Fatalities", size(medium)) ///
       xtitle("Years Since 0.08 BAC Law Adoption") ///
       ytitle("Coefficient (log HR fatalities)") ///
       legend(off) ///
       graphregion(color(white)) ///
       name(es_hr, replace)

graph export "$analysis/output/figures/event_study_hr.png", replace width(1200)

* Load non-hit-run coefficients
import delimited "$analysis/output/tables/es_coefficients_nhr.csv", clear

* Figure 2: Non-Hit-and-Run Event Study (placebo)
twoway (rcap ci_lower ci_upper event_time, lcolor(dkgreen)) ///
       (connected coefficient event_time, mcolor(dkgreen) lcolor(dkgreen) msymbol(O)), ///
       yline(0, lcolor(gray) lpattern(dash)) ///
       xline(-0.5, lcolor(red) lpattern(dash)) ///
       title("Event Study: Non-Hit-and-Run Fatalities (Placebo)", size(medium)) ///
       xtitle("Years Since 0.08 BAC Law Adoption") ///
       ytitle("Coefficient (log non-HR fatalities)") ///
       legend(off) ///
       graphregion(color(white)) ///
       name(es_nhr, replace)

graph export "$analysis/output/figures/event_study_nhr.png", replace width(1200)

* Figure 3: Combined Event Study
graph combine es_hr es_nhr, ///
       title("Event Study: Effect of 0.08 BAC Laws on Fatalities", size(medium)) ///
       rows(1) ///
       graphregion(color(white)) ///
       name(es_combined, replace)

graph export "$analysis/output/figures/event_study_combined.png", replace width(1600)

di "  Created figures:"
di "    - event_study_hr.png"
di "    - event_study_nhr.png"
di "    - event_study_combined.png"
