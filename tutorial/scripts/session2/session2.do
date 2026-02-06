/*==============================================================================
    Stata Session 2: Loops, Organization, and Regression
    14.33 Economics Research and Communication

    This script covers:
    - Loops (forvalues, foreach)
    - Locals and macros
    - Project organization
    - OLS regression
    - Fixed effects
    - Instrumental variables
    - Exporting results
==============================================================================*/

clear all
set more off
set varabbrev off

* Set your working directory (CHANGE THIS!)
* cd "/Users/yourname/Dropbox/14.33/session2"

* ==============================================================================
* PART 1: LOOPS
* ==============================================================================

* forvalues: Loop over numbers
forvalues i = 1/5 {
    di "Iteration `i'"
}

* forvalues with step size: Count by 5s from 5 to 25
forvalues i = 5(5)25 {
    di "Value: `i'"
}

* foreach: Loop over a list of values
foreach var in price mpg weight {
    di "Variable: `var'"
}

* Practical example: Summarize multiple variables
sysuse auto, clear
foreach var in price mpg weight length {
    summarize `var'
}

* ==============================================================================
* PART 2: LOCALS
* ==============================================================================

* Create a local
local myvar = 7
di `myvar'

* Store a list in a local
local controls "mpg weight length"
reg price `controls'

* Store regression results
reg price mpg
local coef = _b[mpg]
local se = _se[mpg]
di "Coefficient: `coef', SE: `se'"

* ==============================================================================
* PART 3: PRESERVE AND RESTORE
* ==============================================================================

sysuse auto, clear

* Save the current state
preserve

* Modify the data
keep if foreign == 1
di "Observations (foreign only): " _N

* Go back to the full dataset
restore

di "Observations (full data): " _N

* ==============================================================================
* PART 4: PROJECT ORGANIZATION
* ==============================================================================

* Example master script structure:
/*
    clear all
    set more off

    * Set paths
    global root "/Users/me/Dropbox/project"
    global build "$root/build"
    global analysis "$root/analysis"

    * Run scripts
    do "$build/code/01_import.do"
    do "$build/code/02_clean.do"
    do "$analysis/code/01_regressions.do"
*/

* ==============================================================================
* PART 5: REGRESSION
* ==============================================================================

sysuse auto, clear

* Simple OLS
reg price mpg

* Multiple regression
reg price mpg weight length

* Heteroskedasticity-robust standard errors
reg price mpg weight length, robust

* Create a categorical variable for clustering example
gen manufacturer = word(make, 1)
encode manufacturer, gen(mfr_id)

* Clustered standard errors
reg price mpg weight, cluster(mfr_id)

* ==============================================================================
* PART 6: INTERACTIONS
* ==============================================================================

* # adds just the interaction
reg price mpg foreign#c.weight

* ## adds interaction AND main effects
reg price mpg foreign##c.weight

* ==============================================================================
* PART 7: FIXED EFFECTS
* ==============================================================================

* Using i. for fixed effects (shows all coefficients)
reg price mpg weight i.foreign

* Using absorb() to absorb fixed effects (faster, doesn't show FE)
reg price mpg weight, absorb(mfr_id)

* For larger datasets, use reghdfe (install first)
* ssc install reghdfe
* ssc install ftools
* reghdfe price mpg weight, absorb(mfr_id) cluster(mfr_id)

* ==============================================================================
* PART 8: INSTRUMENTAL VARIABLES
* ==============================================================================

* IV syntax: ivregress 2sls Y controls (endogenous = instruments)
* Example (not causally meaningful, just syntax demo):
ivregress 2sls price weight (mpg = length displacement)

* Check first-stage F-statistic
estat firststage

* With robust standard errors
ivregress 2sls price weight (mpg = length displacement), robust

* ==============================================================================
* PART 9: EXPORTING RESULTS
* ==============================================================================

* Install estout package
* ssc install estout

* Store multiple models
eststo clear
eststo m1: reg price mpg, robust
eststo m2: reg price mpg weight, robust
eststo m3: reg price mpg weight length, robust

* Display table
esttab m1 m2 m3, se r2 star(* 0.1 ** 0.05 *** 0.01)

* Export to LaTeX
* esttab m1 m2 m3 using "results.tex", replace se r2 booktabs

* Export to CSV
* esttab m1 m2 m3 using "results.csv", replace se r2

* ==============================================================================
* PRACTICE EXERCISE
* ==============================================================================

di _newline(2)
di "PRACTICE EXERCISE:"
di "1. Create a local called 'controls' containing 'weight length'"
di "2. Run: reg price mpg `controls', robust"
di "3. Use a loop to summarize mpg, weight, and length"

* Solution:
local controls "weight length"
reg price mpg `controls', robust

foreach v in mpg weight length {
    summarize `v'
}

di _newline(2)
di "Session 2 script complete!"
