* ===========================================================================
* 05_collapse_demographics.do
* Clean and collapse individual-level survey data to state-year aggregates
* ===========================================================================
*
* Input:  build/output/demographics_combined.dta
* Output: build/output/demographics_state_year.dta
*
* The demographic survey is at the individual respondent level. This script
* cleans the data (drops irrelevant observations, destringes messy numeric
* variables) and then collapses to a state-year panel with population
* counts, median income, and urbanization rate.
* ===========================================================================

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

* ---------------------------------------------------------------------------
* 1. Load combined individual-level survey data
* ---------------------------------------------------------------------------

use "$build/output/demographics_combined.dta", clear

di "Individual respondent records: " _N


* ---------------------------------------------------------------------------
* 2. Exploratory checks
* ---------------------------------------------------------------------------
* Always inspect key variables before cleaning to understand the data.

tab state_fips
tab year


* ---------------------------------------------------------------------------
* 3. Drop observations we do not want in the analysis
* ---------------------------------------------------------------------------

* Drop Washington D.C. (FIPS 51 in this dataset)
* D.C. is not a state and has unusual demographics; we exclude it.
drop if state_fips == 51
di "Records after dropping DC: " _N

* Restrict to years 2000 and later
* Earlier years have thinner coverage and predate our policy variation.
drop if year < 2000
di "Records after year restriction: " _N


* ---------------------------------------------------------------------------
* 4. Clean income variable
* ---------------------------------------------------------------------------
* Income is stored as a string with dollar signs and commas (e.g. "$45,000").
* destring with ignore() strips those characters and converts to numeric.

destring income, replace ignore("$,")

summarize income


* ---------------------------------------------------------------------------
* 5. Collapse to state-year level
* ---------------------------------------------------------------------------
* We compute three state-year aggregates from the survey microdata:
*
*   population    — total weighted count of individuals (rawsum of weights)
*   median_income — simple mean of income (weighted mean as approximation)
*   pct_urban     — weighted mean of the urban indicator (0/1)
*
* All computations use the survey weight variable so the estimates reflect
* population totals and means, not just sample statistics.

collapse                                  ///
    (rawsum) population = weight          ///
    (mean)   median_income = income       ///
    (mean)   pct_urban = urban            ///
    [aweight = weight],                   ///
    by(state_fips year)

di "State-year observations after collapse: " _N

* Verify we have exactly 800 state-year cells (40 states × 20 years, 2000–2019... adjust as needed)
* Update the expected count here if the years or state coverage differ.
assert _N == 800

summarize


* ---------------------------------------------------------------------------
* 6. Label variables
* ---------------------------------------------------------------------------

label variable state_fips    "State FIPS code"
label variable year          "Year"
label variable population    "Population (survey-weighted count)"
label variable median_income "Median household income (survey mean)"
label variable pct_urban     "Share of population living in urban area"


* ---------------------------------------------------------------------------
* 7. Sort and save
* ---------------------------------------------------------------------------

sort state_fips year

save "$build/output/demographics_state_year.dta", replace

di "Saved: $build/output/demographics_state_year.dta"
