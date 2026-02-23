********************************************************************************
* 06_RD.DO
* Purpose: Regression discontinuity analysis of the minimum legal drinking age
*          (MLDA) on mortality, inspired by Carpenter & Dobkin (2009).
*
*          RD Design: Individuals just above and just below age 21 are very
*          similar except that those above 21 can legally purchase alcohol.
*          The running variable (days_from_21) is centered at zero — negative
*          values are days before the 21st birthday, positive values after.
*
*          We estimate three polynomial specifications to assess robustness:
*            Linear    — two separate lines, one on each side of the cutoff
*            Quadratic — two separate quadratic curves
*            Cubic     — two separate cubic curves
*
*          We also produce two graphical diagnostics:
*            rd_plot.png       — binned scatter + linear fit on each side
*            rd_plot_poly.png  — binned scatter + quadratic fit
*            rd_density.png    — histogram of obs by bin (McCrary density test)
*
* Input:   $analysis/code/rd_data.csv
* Output:  $analysis/output/figures/rd_plot.png
*          $analysis/output/figures/rd_plot_poly.png
*          $analysis/output/figures/rd_density.png
*          $analysis/output/tables/rd_results.tex
********************************************************************************

* Setup — master.do sets these globals. To run this script standalone,
* set `root` to the full path of the project folder (pkg-stata/).
if `"${root}"' == "" {
    clear all
    set more off
    global root "/path/to/pkg-stata"
    global build "$root/build"
    global analysis "$root/analysis"
    cd "$root"
}

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

label variable mortality_rate "Mortality Rate"
label variable over_21        "Over 21"
label variable days_from_21   "Days from 21st Birthday"

describe
summarize

********************************************************************************
* SANITY CHECKS
* Before fitting anything, verify the design: over_21 should flip cleanly at
* days_from_21 = 0, and we should have observations on both sides of the cutoff.
********************************************************************************

* Check that treatment status is a step function at the threshold
tab over_21 if abs(days_from_21) < 30

* Quick summary near the threshold
sum mortality_rate over_21 if abs(days_from_21) < 30

********************************************************************************
* RD VISUALIZATION — LINEAR FIT
* Standard RD plot: bin the running variable, compute mean outcome per bin,
* plot binned means as scatter points, and overlay separate linear trend lines
* on each side of the cutoff.
*
* Why bins? Individual-level scatter is too noisy. Binning at 30-day intervals
* makes the jump (or lack thereof) at the threshold visually clear.
********************************************************************************

preserve

* Create 30-day bins, centered within each bin
local bin_width = 30
gen bin = floor(days_from_21 / `bin_width') * `bin_width' + `bin_width' / 2

* Collapse to bin-level means
collapse (mean) mortality_rate days_from_21, by(bin)

* RD plot: separate color/symbol for below vs. above threshold
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
           position(11) ring(0) rows(2) size(large) ///
           region(lcolor(white) fcolor(white%80))) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(zero))

graph export "$analysis/output/figures/rd_plot.png", replace width(2400) height(1800)
graph export "$analysis/output/figures/rd_plot.pdf", replace

********************************************************************************
* RD VISUALIZATION — QUADRATIC FIT
* Same binned scatter, but fit separate quadratic curves (qfit) on each side.
* If the linear and quadratic plots look similar, linear is a reasonable
* approximation. If they diverge, we may need higher-order polynomials.
********************************************************************************

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
           position(11) ring(0) rows(2) size(large) ///
           region(lcolor(white) fcolor(white%80))) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(zero))

graph export "$analysis/output/figures/rd_plot_poly.png", replace width(2400) height(1800)
graph export "$analysis/output/figures/rd_plot_poly.pdf", replace

restore

********************************************************************************
* DENSITY PLOT (McCrary Test — Informal)
* If individuals could precisely manipulate their running variable to land just
* above or below the threshold, there would be a "bunching" of observations
* just above 21 (to gain drinking rights). A smooth density of observations
* across the threshold is evidence against manipulation.
* This plot shows the count of observations in 15-day bins near the cutoff.
********************************************************************************

preserve

* Create narrow 15-day bins within +/- 180 days of threshold
gen bin_narrow = floor(days_from_21 / 15) * 15 if abs(days_from_21) < 180

collapse (count) n = person_id, by(bin_narrow)
drop if missing(bin_narrow)

twoway (bar n bin_narrow, barwidth(14) color("44 95 138%70")), ///
    xline(0, lcolor(gs12) lwidth(vthin) lpattern(dash)) ///
    xtitle("Days from 21st Birthday", size(large) margin(t=3)) ///
    ytitle("Number of Observations", size(large) margin(r=3)) ///
    xlabel(, labsize(large) labcolor(gs5)) ///
    ylabel(, labsize(large) labcolor(gs5) grid glcolor(gs14) glwidth(vthin)) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(zero))

graph export "$analysis/output/figures/rd_density.png", replace width(2400) height(1800)

restore

********************************************************************************
* RD REGRESSION — WITHIN BANDWIDTH
* We restrict the sample to observations within +/- 365 days of the threshold.
* Narrower bandwidth = less extrapolation, but less data and larger SEs.
*
* Each model allows different slopes on each side of the cutoff by interacting
* days_from_21 with over_21. This is standard in RD regressions.
*
* Interaction terms created manually:
*   days_x_over21    = days_from_21 * over_21   (linear slope difference)
*   days_sq_x_over21 = days_sq * over_21         (quadratic slope difference)
*   days_cu_x_over21 = days_cu * over_21         (cubic slope difference)
*
* The coefficient on over_21 is the estimated discontinuity at the threshold.
********************************************************************************

local bandwidth = 365

* Create polynomial terms and their interactions with over_21
gen days_x_over21    = days_from_21 * over_21
gen days_sq          = days_from_21^2
gen days_cu          = days_from_21^3
gen days_sq_x_over21 = days_sq * over_21
gen days_cu_x_over21 = days_cu * over_21

* --- Linear RD ---
* Allows a different intercept (jump) and slope on each side of the cutoff.
regress mortality_rate over_21 days_from_21 days_x_over21 ///
    male income ///
    if abs(days_from_21) <= `bandwidth', ///
    vce(robust)

estimates store rd_linear

* Test whether slopes differ on the two sides
di as text _n "Test of slope difference (days x over21):"
test days_x_over21

* --- Quadratic RD ---
* Adds quadratic terms. If the true relationship is nonlinear, the linear
* model may confound curvature with the jump.
regress mortality_rate over_21 days_from_21 days_x_over21 ///
    days_sq days_sq_x_over21 ///
    male income ///
    if abs(days_from_21) <= `bandwidth', ///
    vce(robust)

estimates store rd_quadratic

* --- Cubic RD ---
* Further flexibility. If results are stable from linear → cubic, the jump
* estimate is robust to functional form assumptions.
regress mortality_rate over_21 days_from_21 days_x_over21 ///
    days_sq days_sq_x_over21 days_cu days_cu_x_over21 ///
    male income ///
    if abs(days_from_21) <= `bandwidth', ///
    vce(robust)

estimates store rd_cubic

********************************************************************************
* EXPORT RESULTS TABLE
* We keep only the over_21 coefficient (the RD estimate) in the table body.
* The polynomial terms are nuisance parameters — controlling for them, but
* not the focus of the table.
********************************************************************************

esttab rd_linear rd_quadratic rd_cubic ///
    using "$analysis/output/tables/rd_results.tex", ///
    replace ///
    keep(over_21) ///
    label fragment ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nomtitles nonumbers ///
    prehead("\begin{tabular}{l*{3}{c}}" ///
            "\midrule \midrule" ///
            "Dependent Variable: & \multicolumn{3}{c}{Mortality Rate}\\" ///
            "\cmidrule(lr){2-4}" ///
            "Model:              & Linear & Quadratic & Cubic\\" ///
            "                    & (1)    & (2)       & (3)\\" ///
            "\midrule" ///
            "\emph{Variables} \\") ///
    posthead("") ///
    prefoot("\midrule" ///
            "\emph{Fit statistics} \\") ///
    stats(N r2, fmt(%9.0fc %9.4f) ///
          labels("Observations" "R\$^2\$")) ///
    postfoot("\midrule \midrule" ///
             "\multicolumn{4}{l}{\emph{Robust standard-errors in parentheses}}\\" ///
             "\multicolumn{4}{l}{\emph{Bandwidth: $\pm$365 days from 21st birthday}}\\" ///
             "\multicolumn{4}{l}{\emph{Signif. Codes: ***: 0.01, **: 0.05, *: 0.1}}\\" ///
             "\end{tabular}")

di as text _n "RD analysis complete."
di as text    "Figures: $analysis/output/figures/rd_plot.png"
di as text    "         $analysis/output/figures/rd_plot_poly.png"
di as text    "         $analysis/output/figures/rd_density.png"
di as text    "Table:   $analysis/output/tables/rd_results.tex"
