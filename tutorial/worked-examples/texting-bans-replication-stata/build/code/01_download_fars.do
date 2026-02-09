* 01_download_fars.do -- Download FARS accident data (2007-2022)
* =============================================================================
* Downloads ZIP files from NHTSA, extracts accident.csv for each year.
* Skips download if cached DTA exists.
* =============================================================================

local root "`c(pwd)'"
local cache_file "`root'/build/output/fars_raw.dta"

capture confirm file "`cache_file'"
if _rc == 0 {
    display "    Cached fars_raw.dta found -- skipping download."
}
else {
    * Download and extract each year
    forvalues year = 2007/2022 {
        local csv_file "`root'/build/output/fars_csvs/accident_`year'.csv"

        capture confirm file "`csv_file'"
        if _rc == 0 {
            display "    `year': using cached CSV"
        }
        else {
            display "    `year': downloading..."
            local url "https://static.nhtsa.gov/nhtsa/downloads/FARS/`year'/National/FARS`year'NationalCSV.zip"
            local zip_file "`root'/build/output/fars_csvs/FARS`year'.zip"

            * Download ZIP
            copy "`url'" "`zip_file'", replace

            * Extract accident.csv
            local temp_dir "`root'/build/output/fars_csvs/temp_`year'"
            capture mkdir "`temp_dir'"
            shell unzip -j -o "`zip_file'" "*/accident.csv" "*/ACCIDENT.csv" -d "`temp_dir'" 2>/dev/null || true

            * Find and move the accident file
            local found 0
            foreach fname in accident.csv ACCIDENT.csv Accident.csv {
                capture confirm file "`temp_dir'/`fname'"
                if _rc == 0 {
                    copy "`temp_dir'/`fname'" "`csv_file'", replace
                    local found 1
                    continue, break
                }
            }

            * Clean up
            shell rm -rf "`temp_dir'" "`zip_file'"
            display "    `year': OK"
        }
    }

    * Load and combine all years
    clear
    tempfile combined
    save `combined', emptyok

    forvalues year = 2007/2022 {
        local csv_file "`root'/build/output/fars_csvs/accident_`year'.csv"
        import delimited "`csv_file'", clear varnames(1)

        * Standardize column names (FARS uses uppercase)
        capture rename STATE state
        capture rename STATENAME statename
        capture rename YEAR year
        capture rename MONTH month
        capture rename FATALS fatals

        keep state statename year month fatals
        append using `combined'
        save `combined', replace
    }

    use `combined', clear
    save "`cache_file'", replace
    display "    Saved `=_N' rows to fars_raw.dta"
}
