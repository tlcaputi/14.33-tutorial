********************************************************************************
* 05_RD.DO
* Purpose: Regression discontinuity analysis of the minimum legal drinking age
*          (MLDA) on mortality, inspired by Carpenter & Dobkin (2009)
* Input: analysis/code/rd_data.csv
* Output: RD plots and regression results
********************************************************************************

clear all

********************************************************************************
* IMPORT DATA
********************************************************************************

import delimited "$analysis/code/rd_data.csv", clear

* Verify required variables
ds
foreach var in person_id days_from_21 over_21 mortality_rate {
    capture confirm variable `var'
    if _rc {
        di as error "Required variable `var' not found in rd_data.csv"
        exit 111
    }
}

* Label variables
label variable mortality_rate "Mortality Rate"
label variable over_21 "Over 21"
label variable days_from_21 "Days from 21st Birthday"

* Display summary statistics
describe
summarize

********************************************************************************
* DEFINE RD PARAMETERS
********************************************************************************

* Running variable is already centered at threshold (days_from_21)
label variable days_from_21 "Days from 21st birthday"

* Check discontinuity in treatment
tab over_21 if abs(days_from_21) < 30

* Summary around threshold
sum mortality_rate over_21 if abs(days_from_21) < 30

********************************************************************************
* VISUALIZE RD DESIGN
********************************************************************************

* Create manual RD plot with bins
preserve

* Create bins
local bin_width = 30
gen bin = floor(days_from_21 / `bin_width') * `bin_width' + `bin_width' / 2

* Calculate means within bins
collapse (mean) mortality_rate days_from_21, by(bin)

* Plot
twoway (scatter mortality_rate bin if bin < 0, ///
            mcolor("44 95 138") msize(small) msymbol(O)) ///
       (scatter mortality_rate bin if bin >= 0, ///
            mcolor("178 34 34") msize(small) msymbol(O)) ///
       (lfit mortality_rate bin if bin < 0, ///
            lcolor("44 95 138") lpattern(solid) lwidth(medthin)) ///
       (lfit mortality_rate bin if bin >= 0, ///
            lcolor("178 34 34") lpattern(solid) lwidth(medthin)), ///
    xline(0, lcolor(gs12) lwidth(vthin) lpattern(dash)) ///
    xtitle("Days from 21st Birthday", size(large) margin(t=3)) ///
    ytitle("Mortality Rate", size(large) margin(r=3)) ///
    xlabel(, labsize(large) labcolor(gs5)) ///
    ylabel(, labsize(large) labcolor(gs5) grid glcolor(gs14) glwidth(vthin)) ///
    legend(order(1 "Below 21" 2 "Above 21") ///
           position(11) ring(0) rows(2) size(small) ///
           region(lcolor(white) fcolor(white%80))) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(zero))

graph export "$analysis/output/rd_plot.png", replace width(2400) height(1800)
graph export "$analysis/output/rd_plot.pdf", replace

* Cubic polynomial fit RD plot
gen days_sq_bin = bin^2
gen days_cu_bin = bin^3

twoway (scatter mortality_rate bin if bin < 0, ///
            mcolor("44 95 138") msize(small) msymbol(O)) ///
       (scatter mortality_rate bin if bin >= 0, ///
            mcolor("178 34 34") msize(small) msymbol(O)) ///
       (qfit mortality_rate bin if bin < 0, ///
            lcolor("44 95 138") lpattern(solid) lwidth(medthin)) ///
       (qfit mortality_rate bin if bin >= 0, ///
            lcolor("178 34 34") lpattern(solid) lwidth(medthin)), ///
    xline(0, lcolor(gs12) lwidth(vthin) lpattern(dash)) ///
    xtitle("Days from 21st Birthday", size(large) margin(t=3)) ///
    ytitle("Mortality Rate", size(large) margin(r=3)) ///
    xlabel(, labsize(large) labcolor(gs5)) ///
    ylabel(, labsize(large) labcolor(gs5) grid glcolor(gs14) glwidth(vthin)) ///
    legend(order(1 "Below 21" 2 "Above 21") ///
           position(11) ring(0) rows(2) size(small) ///
           region(lcolor(white) fcolor(white%80))) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(zero))

graph export "$analysis/output/rd_plot_poly.png", replace width(2400) height(1800)
graph export "$analysis/output/rd_plot_poly.pdf", replace

restore

********************************************************************************
* LINEAR RD REGRESSION (WITHIN BANDWIDTH)
********************************************************************************

* Use bandwidth of +/- 365 days (1 year)
local bandwidth = 365

* Create interaction terms
gen days_x_over21 = days_from_21 * over_21

* Linear RD regression
regress mortality_rate over_21 days_from_21 days_x_over21 ///
    if abs(days_from_21) <= `bandwidth', ///
    vce(robust)

estimates store rd_linear

* Test for different slopes
test days_x_over21

********************************************************************************
* POLYNOMIAL RD REGRESSION
********************************************************************************

* Create polynomial terms
gen days_sq = days_from_21^2
gen days_cu = days_from_21^3
gen days_sq_x_over21 = days_sq * over_21
gen days_cu_x_over21 = days_cu * over_21

* Quadratic RD
regress mortality_rate over_21 days_from_21 days_x_over21 ///
    days_sq days_sq_x_over21 ///
    if abs(days_from_21) <= `bandwidth', ///
    vce(robust)

estimates store rd_quadratic

* Cubic RD
regress mortality_rate over_21 days_from_21 days_x_over21 ///
    days_sq days_sq_x_over21 days_cu days_cu_x_over21 ///
    if abs(days_from_21) <= `bandwidth', ///
    vce(robust)

estimates store rd_cubic

********************************************************************************
* ROBUSTNESS: DIFFERENT BANDWIDTHS
********************************************************************************

foreach bw in 90 180 270 365 548 730 {
    qui regress mortality_rate over_21 days_from_21 days_x_over21 ///
        if abs(days_from_21) <= `bw', vce(robust)
}

********************************************************************************
* BALANCE TEST: DENSITY AT THRESHOLD
********************************************************************************

* Create narrow bins around threshold
gen bin_narrow = floor(days_from_21 / 15) * 15 if abs(days_from_21) < 180

* Count observations in each bin
preserve
collapse (count) n = person_id, by(bin_narrow)
drop if missing(bin_narrow)

* Plot histogram
twoway (bar n bin_narrow, barwidth(14) color("44 95 138%70")), ///
    xline(0, lcolor(gs12) lwidth(vthin) lpattern(dash)) ///
    xtitle("Days from 21st Birthday", size(large) margin(t=3)) ///
    ytitle("Number of Observations", size(large) margin(r=3)) ///
    xlabel(, labsize(large) labcolor(gs5)) ///
    ylabel(, labsize(large) labcolor(gs5) grid glcolor(gs14) glwidth(vthin)) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(zero))

graph export "$analysis/output/rd_density.png", replace width(2400) height(1800)

restore

********************************************************************************
* EXPORT RESULTS TABLE
********************************************************************************

capture which esttab
if !_rc {
    esttab rd_linear rd_quadratic rd_cubic ///
        using "$analysis/output/rd_results.tex", ///
        replace ///
        keep(over_21) ///
        label fragment ///
        b(%9.4f) se(%9.4f) ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        nomtitles nonumbers ///
        prehead("\begin{tabular}{l*{3}{c}}" ///
                "\midrule \midrule" ///
                "Dependent Variable: &\multicolumn{3}{c}{Mortality Rate}\\" ///
                "\cmidrule(lr){2-4}" ///
                "Model:              & Linear & Quadratic & Cubic\\" ///
                "                    & (1) & (2) & (3)\\" ///
                "\midrule" ///
                "\emph{Variables} \\") ///
        posthead("") ///
        prefoot("\midrule" ///
                "\emph{Fit statistics} \\") ///
        stats(N r2, fmt(%9.0fc %9.4f) ///
              labels("Observations" "R\$^2\$")) ///
        postfoot("\midrule \midrule" ///
                 "\multicolumn{4}{l}{\emph{Robust standard-errors in parentheses}}\\" ///
                 "\multicolumn{4}{l}{\emph{Bandwidth: \$\pm\$ `bandwidth' days}}\\" ///
                 "\multicolumn{4}{l}{\emph{Signif. Codes: ***: 0.01, **: 0.05, *: 0.1}}\\" ///
                 "\end{tabular}")
}

di as text _n "RD analysis complete."
