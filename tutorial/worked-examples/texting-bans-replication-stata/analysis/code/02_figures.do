* 02_figures.do -- Event study plot
* =============================================================================

local root "`c(pwd)'"

* Load coefficients from CSV
import delimited "`root'/analysis/output/event_study_coefs.csv", clear varnames(1)

* Add reference period (t = -1)
local newobs = _N + 1
set obs `newobs'
replace event_time = -1 in `newobs'
replace coefficient = 0 in `newobs'
replace std_error = 0 in `newobs'
replace ci_lower = 0 in `newobs'
replace ci_upper = 0 in `newobs'

sort event_time

* Create event study plot
twoway ///
    (rcap ci_lower ci_upper event_time, lcolor(navy) lwidth(medthin)) ///
    (scatter coefficient event_time, msymbol(D) mcolor(navy) msize(medium)), ///
    yline(0, lcolor(red) lpattern(dash) lwidth(thin)) ///
    xline(-0.5, lcolor(gs10) lpattern(dash) lwidth(thin)) ///
    xlabel(-6(1)6) ///
    xtitle("Years Relative to Texting Ban") ///
    ytitle("Effect on Log Fatalities") ///
    title("Event Study: Texting Bans and Traffic Fatalities") ///
    note("Coefficients relative to t=-1. 95% CIs shown. Clustered SEs at state level.") ///
    legend(off) ///
    graphregion(color(white)) bgcolor(white) ///
    scheme(s2color)

graph export "`root'/analysis/output/event_study.png", replace width(1200)

display "    Saved plot to `root'/analysis/output/event_study.png"
