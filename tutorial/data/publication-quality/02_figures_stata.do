* --- Generate fake event study data ---
clear all
set seed 42
set obs 11

gen period = _n - 6
gen coef = .
gen se = .

* Coefficients
replace coef = -0.10 if period == -5
replace coef =  0.05 if period == -4
replace coef = -0.15 if period == -3
replace coef =  0.08 if period == -2
replace coef =  0.02 if period == -1
replace coef =  0.00 if period ==  0
replace coef =  0.80 if period ==  1
replace coef =  1.50 if period ==  2
replace coef =  2.10 if period ==  3
replace coef =  2.40 if period ==  4
replace coef =  2.60 if period ==  5

* Standard errors
replace se = 0.35 if period == -5
replace se = 0.30 if period == -4
replace se = 0.28 if period == -3
replace se = 0.25 if period == -2
replace se = 0.20 if period == -1
replace se = 0.00 if period ==  0
replace se = 0.22 if period ==  1
replace se = 0.25 if period ==  2
replace se = 0.30 if period ==  3
replace se = 0.35 if period ==  4
replace se = 0.40 if period ==  5

gen ci_lo = coef - 1.96 * se
gen ci_hi = coef + 1.96 * se


* ===== STEP 1: Default Stata plot =====
twoway (connected coef period), ///
    title("Event Study") ///
    xtitle("period") ytitle("estimate") ///
    yline(0)
graph export "fig_step1_default_stata.png", replace width(800)


* ===== STEP 2: Add confidence intervals =====
twoway (rcap ci_lo ci_hi period) ///
       (connected coef period, msymbol(O)), ///
    title("Event Study") ///
    xtitle("period") ytitle("estimate") ///
    yline(0, lcolor(black) lwidth(thin)) ///
    legend(off)
graph export "fig_step2_with_ci_stata.png", replace width(800)


* ===== STEP 3: Better styling =====
twoway (rcap ci_lo ci_hi period, lcolor("67 130 175")) ///
       (connected coef period, lcolor("67 130 175") mcolor("67 130 175") ///
        msymbol(O) msize(medium) lwidth(medthin)), ///
    title("Effect of Policy on Fatality Rate", size(medium)) ///
    xtitle("Years Relative to Policy Adoption") ///
    ytitle("Estimated Effect") ///
    yline(0, lcolor(gray) lwidth(vthin) lpattern(dash)) ///
    xline(-0.5, lcolor(gray) lwidth(vthin) lpattern(dash)) ///
    xlabel(-5(1)5) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white))
graph export "fig_step3_themed_stata.png", replace width(800)


* ===== STEP 4: Publication quality =====
twoway (rarea ci_hi ci_lo period, color("44 95 138%20") lwidth(none)) ///
       (line coef period, lcolor("44 95 138") lwidth(medthin)) ///
       (scatter coef period, mcolor("44 95 138") msymbol(O) msize(small)), ///
    yline(0, lcolor(gs12) lwidth(vthin)) ///
    xline(-0.5, lcolor(gs12) lwidth(vthin) lpattern(dash)) ///
    xtitle("Years Relative to Policy Adoption", size(small) margin(t=3)) ///
    ytitle("Estimated Effect on Fatality Rate", size(small) margin(r=3)) ///
    xlabel(-5(1)5, labsize(small) labcolor(gs5)) ///
    ylabel(, labsize(small) labcolor(gs5) grid glcolor(gs14) glwidth(vthin)) ///
    text(-0.7 -3 "Pre-treatment", color(gs8) size(small) placement(c)) ///
    text(3.0  3  "Post-treatment", color(gs8) size(small) placement(c)) ///
    legend(off) ///
    graphregion(color(white) margin(medium)) ///
    plotregion(color(white) margin(small)) ///
    title("") ///
    scheme(s2mono)
graph export "fig_step4_publication_stata.png", replace width(1600)

display "All Stata figures saved."
