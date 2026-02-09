* 03_merge_controls.do -- Merge policy dates and economic controls
* =============================================================================

local root "`c(pwd)'"

* ── Load policy dates ────────────────────────────────────────
import delimited "`root'/texting_ban_dates.csv", clear varnames(1)
destring texting_ban_year, replace force
destring primary_enforcement, replace force
save "`root'/build/output/texting_ban_dates.dta", replace

* ── Merge with fatality data ─────────────────────────────────
use "`root'/build/output/state_year_fatalities.dta", clear
merge m:1 state using "`root'/build/output/texting_ban_dates.dta", nogen keep(master match)

* Create treatment variables
gen ever_treated = !missing(texting_ban_year)
gen treated = (year >= texting_ban_year) & ever_treated
gen event_time = year - texting_ban_year if ever_treated
replace event_time = -1000 if !ever_treated

display "    Treated obs: `=string(sum(ever_treated))'"
display "    Never-treated obs: `=string(sum(!ever_treated))'"

* ── Download FRED controls ───────────────────────────────────
* State abbreviations and FIPS codes for FRED series
local st_abbr AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY
local st_fips  1  2  4  5  6  8  9 10 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56

save "`root'/build/output/analysis_data.dta", replace

* Download unemployment
display "    Downloading unemployment from FRED..."
tempfile unemp_all
clear
gen state = .
gen year = .
gen unemployment = .
save `unemp_all', replace

local n : word count `st_abbr'
forvalues j = 1/`n' {
    local st : word `j' of `st_abbr'
    local fips : word `j' of `st_fips'
    capture {
        local url "https://fred.stlouisfed.org/graph/fredgraph.csv?id=`st'UR"
        import delimited "`url'", clear varnames(1)
        gen yr = real(substr(date, 1, 4))
        destring v2, replace force
        rename v2 unemp_val
        keep if yr >= 2007 & yr <= 2022
        collapse (mean) unemployment = unemp_val, by(yr)
        rename yr year
        gen state = `fips'
        append using `unemp_all'
        save `unemp_all', replace
    }
    sleep 300
}

display "    Downloading per-capita income from FRED..."
tempfile income_all
clear
gen state = .
gen year = .
gen income = .
save `income_all', replace

forvalues j = 1/`n' {
    local st : word `j' of `st_abbr'
    local fips : word `j' of `st_fips'
    capture {
        local url "https://fred.stlouisfed.org/graph/fredgraph.csv?id=`st'PCPI"
        import delimited "`url'", clear varnames(1)
        gen yr = real(substr(date, 1, 4))
        destring v2, replace force
        rename v2 income_val
        keep if yr >= 2007 & yr <= 2022
        collapse (mean) income = income_val, by(yr)
        rename yr year
        gen state = `fips'
        append using `income_all'
        save `income_all', replace
    }
    sleep 300
}

* Merge controls back
use "`root'/build/output/analysis_data.dta", clear
merge 1:1 state year using `unemp_all', nogen keep(master match)
merge 1:1 state year using `income_all', nogen keep(master match)

* Drop DC (FIPS 11)
drop if state == 11

display "    Final dataset: `=_N' rows"

save "`root'/build/output/analysis_data.dta", replace
