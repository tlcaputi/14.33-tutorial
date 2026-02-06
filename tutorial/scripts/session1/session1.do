/*==============================================================================
    Stata Session 1: Basics through Merging
    14.33 Economics Research and Communication

    This script covers:
    - Basic Stata commands
    - Exploring data
    - Creating variables
    - Importing CSV files
    - Reshaping data (wide to long)
    - Merging datasets
==============================================================================*/

clear all
set more off

* Set your working directory (CHANGE THIS!)
* cd "/Users/yourname/Dropbox/14.33/session1"

* ==============================================================================
* PART 1: BASIC COMMANDS
* ==============================================================================

* Load built-in dataset
sysuse auto, clear

* View the data
browse

* Get an overview
describe
summarize

* Summary of specific variables
summarize price mpg weight

* Detailed summary with percentiles
summarize price, detail

* Frequency table for categorical variable
tabulate foreign

* Cross-tabulation
tabulate foreign rep78

* ==============================================================================
* PART 2: CREATING VARIABLES
* ==============================================================================

* Create a new variable
gen price_thousands = price / 1000

* Create a binary indicator
gen expensive = (price > 6000)

* Conditional replacement
gen car_type = ""
replace car_type = "Cheap" if price < 5000
replace car_type = "Medium" if price >= 5000 & price < 10000
replace car_type = "Expensive" if price >= 10000

* Using if conditions
summarize mpg if foreign == 1
summarize mpg if foreign == 0

* Drop observations
drop if missing(rep78)

* Keep only certain variables
* keep make price mpg weight foreign

* ==============================================================================
* PART 3: IMPORTING CSV DATA
* ==============================================================================

* Import a CSV file
* import delimited "mydata.csv", clear

* Common options:
* import delimited "mydata.csv", clear varnames(1)  // First row is variable names
* import delimited "mydata.csv", clear encoding("utf-8")  // Specify encoding

* ==============================================================================
* PART 4: RESHAPING DATA
* ==============================================================================

* Create example wide data
clear
input id income_2020 income_2021 income_2022
1 50000 52000 54000
2 60000 61000 63000
3 45000 47000 48000
end

* Look at the wide format
list

* Reshape from wide to long
* i() = unit identifier
* j() = new variable that will contain the year values
reshape long income_, i(id) j(year)

* Rename the stub
rename income_ income

* Look at the long format
list

* Reshape back to wide (if needed)
reshape wide income, i(id) j(year)

* ==============================================================================
* PART 5: MERGING DATASETS
* ==============================================================================

* Create master dataset (individuals)
clear
input person_id str2 state income
1 "MA" 50000
2 "MA" 60000
3 "CA" 70000
4 "NY" 55000
end
save "individuals.dta", replace

* Create using dataset (state characteristics)
clear
input str2 state min_wage population
"MA" 15.00 7000000
"CA" 15.50 39500000
"TX" 7.25 29500000
end
save "state_data.dta", replace

* Merge: many individuals per state -> m:1
use "individuals.dta", clear
merge m:1 state using "state_data.dta"

* ALWAYS check the merge results
tab _merge

* Investigate unmatched observations
list if _merge == 1  // Only in master (NY - no state data)
list if _merge == 2  // Only in using (TX - no individuals)

* Keep matched only (after understanding why others didn't match)
keep if _merge == 3
drop _merge

* View final merged data
list

* ==============================================================================
* CLEANUP
* ==============================================================================

* Remove temporary files
capture erase "individuals.dta"
capture erase "state_data.dta"

di "Session 1 script complete!"
