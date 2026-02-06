/*==============================================================================
    Session 3: Diff-in-Diff and Event Studies
    Course: 14.33 Economics Research and Communication

    This script demonstrates:
    1. Setting up panel data for DiD
    2. Creating treatment timing variables
    3. Running two-way fixed effects (TWFE)
    4. Running event study specifications
==============================================================================*/

clear all
set more off

* Set your working directory
* cd "/Users/yourname/Dropbox/14.33"

* For this example, we'll use the Stevenson & Wolfers no-fault divorce data
* Download from: https://www.nber.org/research/data/marriage-and-divorce-data

* ============================================================================
* STEP 1: Load and explore data
* ============================================================================

* Load the data (adjust path as needed)
use bacon_example_diff_in_diff_review.dta, clear

* Explore structure
tab year
tab stfips

* Examine key variables
summarize asmrs        // Female suicide rate (outcome Y)
summarize pcinc asmrh cases  // Controls

* ============================================================================
* STEP 2: Create treatment timing variable
* ============================================================================

* Create variable for year state adopted no-fault divorce
* Missing = never adopted (control state)
gen _nfd = .

* Fill in adoption years for each state
replace _nfd = 1971 if stfips == 1   // Alabama
replace _nfd = 1973 if stfips == 4   // Arizona
replace _nfd = 1970 if stfips == 6   // California
replace _nfd = 1971 if stfips == 8   // Colorado
replace _nfd = 1973 if stfips == 9   // Connecticut
replace _nfd = 1977 if stfips == 11  // DC
replace _nfd = 1971 if stfips == 12  // Florida
replace _nfd = 1973 if stfips == 13  // Georgia
replace _nfd = 1971 if stfips == 16  // Idaho
replace _nfd = 1984 if stfips == 17  // Illinois
replace _nfd = 1973 if stfips == 18  // Indiana
replace _nfd = 1970 if stfips == 19  // Iowa
replace _nfd = 1969 if stfips == 20  // Kansas
replace _nfd = 1972 if stfips == 21  // Kentucky
replace _nfd = 1973 if stfips == 23  // Maine
replace _nfd = 1975 if stfips == 25  // Massachusetts
replace _nfd = 1972 if stfips == 26  // Michigan
replace _nfd = 1974 if stfips == 27  // Minnesota
replace _nfd = 1973 if stfips == 29  // Missouri
replace _nfd = 1975 if stfips == 30  // Montana
replace _nfd = 1972 if stfips == 31  // Nebraska
replace _nfd = 1973 if stfips == 32  // Nevada
replace _nfd = 1971 if stfips == 33  // New Hampshire
replace _nfd = 1971 if stfips == 34  // New Jersey
replace _nfd = 1973 if stfips == 35  // New Mexico
replace _nfd = 1971 if stfips == 38  // North Dakota
replace _nfd = 1974 if stfips == 39  // Ohio
replace _nfd = 1973 if stfips == 41  // Oregon
replace _nfd = 1980 if stfips == 42  // Pennsylvania
replace _nfd = 1976 if stfips == 44  // Rhode Island
replace _nfd = 1969 if stfips == 45  // South Carolina
replace _nfd = 1985 if stfips == 46  // South Dakota
replace _nfd = 1974 if stfips == 48  // Texas
replace _nfd = 1973 if stfips == 53  // Washington
replace _nfd = 1977 if stfips == 55  // Wisconsin
replace _nfd = 1977 if stfips == 56  // Wyoming

* Label the variable
label variable _nfd "Year state adopted no-fault divorce"

* Check: how many states adopted vs never adopted?
tab _nfd, missing

* ============================================================================
* STEP 3: Create post-treatment indicator for TWFE
* ============================================================================

* Create post-treatment indicator
* = 1 if year >= year state adopted no-fault divorce
* = 0 otherwise (including never-adopters)
gen treat_post = (year >= _nfd)

* For never-treated, treat_post should be 0 always
replace treat_post = 0 if missing(_nfd)

label variable treat_post "Post-treatment indicator"

* Verify
tab treat_post, missing
tab _nfd treat_post, missing

* ============================================================================
* STEP 4: Two-Way Fixed Effects (TWFE) Regression
* ============================================================================

* Install reghdfe if not already installed
* ssc install reghdfe
* ssc install ftools

* Basic TWFE: state + year fixed effects
reghdfe asmrs treat_post, absorb(stfips year) cluster(stfips)

* With controls
reghdfe asmrs treat_post pcinc asmrh cases, absorb(stfips year) cluster(stfips)

* Store results for comparison
eststo clear
eststo m1: reghdfe asmrs treat_post, absorb(stfips year) cluster(stfips)
eststo m2: reghdfe asmrs treat_post pcinc asmrh cases, absorb(stfips year) cluster(stfips)

* Display results side by side
esttab m1 m2, se r2 label ///
    title("TWFE: Effect of No-Fault Divorce on Female Suicide") ///
    mtitles("No Controls" "With Controls")

* ============================================================================
* STEP 5: Event Study Specification
* ============================================================================

* Create time relative to treatment
* Negative = years before treatment
* 0 = year of treatment
* Positive = years after treatment
gen time_to_treat = year - _nfd

* IMPORTANT: Never-treated states don't have meaningful "time to treatment"
* Set them to a value far outside the data range (-1000)
* This ensures they don't contaminate any event-time coefficient
replace time_to_treat = -1000 if missing(_nfd)

* Create ever_treated indicator
gen ever_treated = !missing(_nfd)
label variable ever_treated "Ever adopted no-fault divorce"

label variable time_to_treat "Years relative to treatment"

* Check the distribution (should see -1000 for never-treated)
tab time_to_treat

* Handle Stata's factor variable limitation (no negatives allowed)
* We need to shift only the TREATED units' time values
* Never-treated stay at -1000 (won't match any factor level)

* Find the minimum value among treated units
summ time_to_treat if ever_treated == 1
local min_val = r(min)

* Shift so minimum is 0 (only for treated units)
gen shifted_ttt = time_to_treat - `min_val' if ever_treated == 1
* Never-treated get missing (they won't contribute to event study dummies)
replace shifted_ttt = . if ever_treated == 0

* Find the value that corresponds to t=-1 (our reference period)
summ shifted_ttt if time_to_treat == -1
local true_neg1 = r(mean)

display "Reference period (t=-1) is shifted_ttt = `true_neg1'"

* Event study regression
* ib`true_neg1' sets t=-1 as the reference category
* Never-treated have missing shifted_ttt, so they don't contribute to
* the event study coefficients (only to the fixed effects)
reghdfe asmrs ib`true_neg1'.shifted_ttt pcinc asmrh cases, ///
    absorb(stfips year) cluster(stfips)

* ============================================================================
* STEP 6: Create Event Study Plot
* ============================================================================

* Store coefficients for plotting
* First, get the coefficient estimates
matrix b = e(b)
matrix V = e(V)

* Create a dataset for plotting
preserve
clear

* Set up time variable
local obs = 40  // Adjust based on your time range
set obs `obs'
gen time_to_treat = _n - 20  // Centered around 0

* This is a simplified version - for publication-quality plots,
* use coefplot or build a more sophisticated plotting routine
restore

* Alternative: Use coefplot (install first: ssc install coefplot)
* coefplot, keep(*.shifted_ttt) vertical ///
*     yline(0) xline(`true_neg1') ///
*     title("Event Study: No-Fault Divorce and Female Suicide")

* ============================================================================
* NOTES
* ============================================================================

* Key things to check:
* 1. Pre-treatment coefficients should be near zero (parallel trends)
* 2. Look for anticipation effects (significant coefficients before t=0)
* 3. Post-treatment coefficients show the treatment effect over time

* Modern DiD methods for staggered adoption:
* - Goodman-Bacon decomposition: bacondecomp
* - Callaway & Sant'Anna: csdid
* - Sun & Abraham: eventstudyinteract
* - Imputation estimator: did_imputation

display "Session 3 complete!"
