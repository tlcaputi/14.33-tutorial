* 02_clean_fars.do - Clean and aggregate FARS data to state-year level

clear

di "  Loading raw FARS data..."
use "$build/output/fars_raw.dta", clear

* Ensure state_fips is properly formatted
capture destring state_fips, replace
tostring state_fips, replace format(%02.0f)

di "  Aggregating to state-year level..."

* Aggregate: count fatalities and hit-run fatalities by state-year
* HR fatalities = sum of fatalities in crashes where hit_run=1
gen hr_fatalities = fatalities * hit_run
collapse (sum) total_fatalities=fatalities hr_fatalities, by(state_fips year)

* Calculate non-HR fatalities
gen nhr_fatalities = total_fatalities - hr_fatalities

* Add state names (50 states only, exclude DC and territories)
gen state_name = ""
replace state_name = "Alabama" if state_fips == "01"
replace state_name = "Alaska" if state_fips == "02"
replace state_name = "Arizona" if state_fips == "04"
replace state_name = "Arkansas" if state_fips == "05"
replace state_name = "California" if state_fips == "06"
replace state_name = "Colorado" if state_fips == "08"
replace state_name = "Connecticut" if state_fips == "09"
replace state_name = "Delaware" if state_fips == "10"
replace state_name = "Florida" if state_fips == "12"
replace state_name = "Georgia" if state_fips == "13"
replace state_name = "Hawaii" if state_fips == "15"
replace state_name = "Idaho" if state_fips == "16"
replace state_name = "Illinois" if state_fips == "17"
replace state_name = "Indiana" if state_fips == "18"
replace state_name = "Iowa" if state_fips == "19"
replace state_name = "Kansas" if state_fips == "20"
replace state_name = "Kentucky" if state_fips == "21"
replace state_name = "Louisiana" if state_fips == "22"
replace state_name = "Maine" if state_fips == "23"
replace state_name = "Maryland" if state_fips == "24"
replace state_name = "Massachusetts" if state_fips == "25"
replace state_name = "Michigan" if state_fips == "26"
replace state_name = "Minnesota" if state_fips == "27"
replace state_name = "Mississippi" if state_fips == "28"
replace state_name = "Missouri" if state_fips == "29"
replace state_name = "Montana" if state_fips == "30"
replace state_name = "Nebraska" if state_fips == "31"
replace state_name = "Nevada" if state_fips == "32"
replace state_name = "New Hampshire" if state_fips == "33"
replace state_name = "New Jersey" if state_fips == "34"
replace state_name = "New Mexico" if state_fips == "35"
replace state_name = "New York" if state_fips == "36"
replace state_name = "North Carolina" if state_fips == "37"
replace state_name = "North Dakota" if state_fips == "38"
replace state_name = "Ohio" if state_fips == "39"
replace state_name = "Oklahoma" if state_fips == "40"
replace state_name = "Oregon" if state_fips == "41"
replace state_name = "Pennsylvania" if state_fips == "42"
replace state_name = "Rhode Island" if state_fips == "44"
replace state_name = "South Carolina" if state_fips == "45"
replace state_name = "South Dakota" if state_fips == "46"
replace state_name = "Tennessee" if state_fips == "47"
replace state_name = "Texas" if state_fips == "48"
replace state_name = "Utah" if state_fips == "49"
replace state_name = "Vermont" if state_fips == "50"
replace state_name = "Virginia" if state_fips == "51"
replace state_name = "Washington" if state_fips == "53"
replace state_name = "West Virginia" if state_fips == "54"
replace state_name = "Wisconsin" if state_fips == "55"
replace state_name = "Wyoming" if state_fips == "56"

* Keep only 50 states (exclude DC, territories)
keep if state_name != ""

* Create complete panel (ensure all state-years are present)
preserve
clear
set obs 50
gen state_fips = ""
local i = 1
foreach fips in "01" "02" "04" "05" "06" "08" "09" "10" "12" "13" ///
                "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" ///
                "25" "26" "27" "28" "29" "30" "31" "32" "33" "34" ///
                "35" "36" "37" "38" "39" "40" "41" "42" "44" "45" ///
                "46" "47" "48" "49" "50" "51" "53" "54" "55" "56" {
    replace state_fips = "`fips'" in `i'
    local i = `i' + 1
}

* Expand to all years
expand 27
bysort state_fips: gen year = 1981 + _n
tempfile complete_panel
save `complete_panel', replace
restore

* Merge to ensure complete panel
merge 1:1 state_fips year using `complete_panel'
drop _merge

* Fill zeros for missing state-years
replace total_fatalities = 0 if missing(total_fatalities)
replace hr_fatalities = 0 if missing(hr_fatalities)
replace nhr_fatalities = 0 if missing(nhr_fatalities)

* Re-add state names for any filled observations
replace state_name = "Alabama" if state_fips == "01" & state_name == ""
replace state_name = "Alaska" if state_fips == "02" & state_name == ""
replace state_name = "Arizona" if state_fips == "04" & state_name == ""
replace state_name = "Arkansas" if state_fips == "05" & state_name == ""
replace state_name = "California" if state_fips == "06" & state_name == ""
replace state_name = "Colorado" if state_fips == "08" & state_name == ""
replace state_name = "Connecticut" if state_fips == "09" & state_name == ""
replace state_name = "Delaware" if state_fips == "10" & state_name == ""
replace state_name = "Florida" if state_fips == "12" & state_name == ""
replace state_name = "Georgia" if state_fips == "13" & state_name == ""
replace state_name = "Hawaii" if state_fips == "15" & state_name == ""
replace state_name = "Idaho" if state_fips == "16" & state_name == ""
replace state_name = "Illinois" if state_fips == "17" & state_name == ""
replace state_name = "Indiana" if state_fips == "18" & state_name == ""
replace state_name = "Iowa" if state_fips == "19" & state_name == ""
replace state_name = "Kansas" if state_fips == "20" & state_name == ""
replace state_name = "Kentucky" if state_fips == "21" & state_name == ""
replace state_name = "Louisiana" if state_fips == "22" & state_name == ""
replace state_name = "Maine" if state_fips == "23" & state_name == ""
replace state_name = "Maryland" if state_fips == "24" & state_name == ""
replace state_name = "Massachusetts" if state_fips == "25" & state_name == ""
replace state_name = "Michigan" if state_fips == "26" & state_name == ""
replace state_name = "Minnesota" if state_fips == "27" & state_name == ""
replace state_name = "Mississippi" if state_fips == "28" & state_name == ""
replace state_name = "Missouri" if state_fips == "29" & state_name == ""
replace state_name = "Montana" if state_fips == "30" & state_name == ""
replace state_name = "Nebraska" if state_fips == "31" & state_name == ""
replace state_name = "Nevada" if state_fips == "32" & state_name == ""
replace state_name = "New Hampshire" if state_fips == "33" & state_name == ""
replace state_name = "New Jersey" if state_fips == "34" & state_name == ""
replace state_name = "New Mexico" if state_fips == "35" & state_name == ""
replace state_name = "New York" if state_fips == "36" & state_name == ""
replace state_name = "North Carolina" if state_fips == "37" & state_name == ""
replace state_name = "North Dakota" if state_fips == "38" & state_name == ""
replace state_name = "Ohio" if state_fips == "39" & state_name == ""
replace state_name = "Oklahoma" if state_fips == "40" & state_name == ""
replace state_name = "Oregon" if state_fips == "41" & state_name == ""
replace state_name = "Pennsylvania" if state_fips == "42" & state_name == ""
replace state_name = "Rhode Island" if state_fips == "44" & state_name == ""
replace state_name = "South Carolina" if state_fips == "45" & state_name == ""
replace state_name = "South Dakota" if state_fips == "46" & state_name == ""
replace state_name = "Tennessee" if state_fips == "47" & state_name == ""
replace state_name = "Texas" if state_fips == "48" & state_name == ""
replace state_name = "Utah" if state_fips == "49" & state_name == ""
replace state_name = "Vermont" if state_fips == "50" & state_name == ""
replace state_name = "Virginia" if state_fips == "51" & state_name == ""
replace state_name = "Washington" if state_fips == "53" & state_name == ""
replace state_name = "West Virginia" if state_fips == "54" & state_name == ""
replace state_name = "Wisconsin" if state_fips == "55" & state_name == ""
replace state_name = "Wyoming" if state_fips == "56" & state_name == ""

* Sort
sort state_fips year

* Save
save "$build/output/state_year_crashes.dta", replace

local n_obs = _N
sum total_fatalities
local total_fat = r(sum)
sum hr_fatalities
local hr_fat = r(sum)
local hr_pct = 100 * `hr_fat' / `total_fat'

di "  Created state-year panel: `n_obs' observations"
di "  Total fatalities: `total_fat'"
di "  HR fatalities: `hr_fat' (`hr_pct'%)"
