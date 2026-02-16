********************************************************************************
* 01_DESCRIPTIVE_TABLE.DO
* Purpose: Create descriptive statistics table with 4 columns
*          (All, Treated After, Treated Before, Untreated)
*          Each cell shows "mean (sd)" for continuous variables
* Input: build/output/analysis_panel.dta
* Output: analysis/output/descriptive_table.tex
********************************************************************************

clear all

use "$build/output/analysis_panel.dta", clear

********************************************************************************
* SETUP
********************************************************************************

* Create treatment group indicator (states that eventually adopt)
gen treated_state = !missing(adoption_year)

* Label variables
label variable fatal_crashes "Fatal Crashes"
label variable serious_crashes "Serious Crashes"
label variable total_crashes "Total Crashes"
label variable fatal_share "Fatal Share"
label variable population "Population"
label variable median_income "Median Income"
label variable pct_urban "Pct. Urban"

local sumvars fatal_crashes serious_crashes total_crashes fatal_share ///
              population median_income pct_urban

********************************************************************************
* WRITE TABLE
********************************************************************************

file open fh using "$analysis/output/descriptive_table.tex", write replace

file write fh "\begin{tabular}{lcccc}" _n
file write fh "\midrule \midrule" _n
file write fh "& All & Treated After & Treated Before & Untreated \\" _n
file write fh "\midrule" _n
file write fh "\emph{Continuous variables} \\" _n

* --- Continuous variables: mean (sd) in each cell ---
foreach var of local sumvars {
    local lab : variable label `var'

    qui sum `var'
    local m1 : di %14.2fc r(mean)
    local s1 : di %14.2fc r(sd)

    qui sum `var' if treated_state == 1 & treated == 1
    local m2 : di %14.2fc r(mean)
    local s2 : di %14.2fc r(sd)

    qui sum `var' if treated_state == 1 & treated == 0
    local m3 : di %14.2fc r(mean)
    local s3 : di %14.2fc r(sd)

    qui sum `var' if treated_state == 0
    local m4 : di %14.2fc r(mean)
    local s4 : di %14.2fc r(sd)

    * Trim whitespace
    forvalues g = 1/4 {
        local m`g' = strtrim("`m`g''")
        local s`g' = strtrim("`s`g''")
    }

    file write fh `"`lab' & `m1' (`s1') & `m2' (`s2') & `m3' (`s3') & `m4' (`s4') \\"' _n
}

* --- Census Region: N (%) in each cell ---
file write fh "\midrule" _n
file write fh "\emph{Census Region} & & & & \\" _n

foreach r in Midwest Northeast South West {
    qui count
    local N1 = r(N)
    qui count if region == "`r'"
    local n1 = r(N)
    local p1 : di %4.1f (`n1'/`N1')*100

    qui count if treated_state == 1 & treated == 1
    local N2 = r(N)
    qui count if region == "`r'" & treated_state == 1 & treated == 1
    local n2 = r(N)
    local p2 : di %4.1f (`n2'/`N2')*100

    qui count if treated_state == 1 & treated == 0
    local N3 = r(N)
    qui count if region == "`r'" & treated_state == 1 & treated == 0
    local n3 = r(N)
    local p3 : di %4.1f (`n3'/`N3')*100

    qui count if treated_state == 0
    local N4 = r(N)
    qui count if region == "`r'" & treated_state == 0
    local n4 = r(N)
    local p4 : di %4.1f (`n4'/`N4')*100

    forvalues g = 1/4 {
        local p`g' = strtrim("`p`g''")
    }

    file write fh `"\quad `r' & `n1' (`p1'\%) & `n2' (`p2'\%) & `n3' (`p3'\%) & `n4' (`p4'\%) \\"' _n
}

file write fh "\midrule \midrule" _n
file write fh `"\multicolumn{5}{l}{\emph{Mean (SD) for continuous variables; N (\%) for categorical variables}}\\"' _n
file write fh "\end{tabular}" _n

file close fh

di as text _n "Descriptive table complete."
