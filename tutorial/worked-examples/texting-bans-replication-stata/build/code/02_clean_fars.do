* 02_clean_fars.do -- Aggregate FARS data to state-year level
* =============================================================================

local root "`c(pwd)'"

use "`root'/build/output/fars_raw.dta", clear

* Collapse to state-year totals
collapse (sum) fatalities = fatals (count) n_crashes = fatals, by(state statename year)

* Summary stats
distinct state
local n_states = r(ndistinct)
distinct year
local n_years = r(ndistinct)

display "    `n_states' states x `n_years' years = `=_N' rows"
summarize fatalities, meanonly
display "    Mean annual fatalities per state: `=round(r(mean))'"

save "`root'/build/output/state_year_fatalities.dta", replace
