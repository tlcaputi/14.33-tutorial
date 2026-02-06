* 01_download_fars.do - Download FARS data (1982-2008)
* This script downloads real FARS crash data from NHTSA
* Run time: ~10-15 minutes depending on internet speed

clear all

* Check if cache file exists
capture confirm file "$build/output/fars_raw.dta"
if _rc == 0 {
    di "  FARS data already downloaded, loading from cache..."
}
else {
    di "  Downloading FARS data from NHTSA (1982-2008)..."
    di "  This will take ~10-15 minutes..."

    * Create temp directory
    capture mkdir "$build/input/fars"

    * Initialize empty dataset for appending
    clear
    gen state_fips = ""
    gen year = .
    gen fatalities = .
    gen hit_run = .
    save "$build/output/fars_raw.dta", replace

    * Loop through years
    forvalues year = 1982/2008 {
        di "    Processing `year'..." _continue

        * Try to download from NHTSA
        local url1 "https://static.nhtsa.gov/nhtsa/downloads/FARS/`year'/National/FARS`year'NationalCSV.zip"
        local url2 "https://static.nhtsa.gov/nhtsa/downloads/FARS/`year'/FARS`year'NationalCSV.zip"
        local zipfile "$build/input/fars/FARS`year'.zip"

        * Try first URL
        capture copy "`url1'" "`zipfile'", replace
        if _rc != 0 {
            * Try second URL
            capture copy "`url2'" "`zipfile'", replace
        }

        if _rc != 0 {
            di " SKIPPED (couldn't download)"
            continue
        }

        * Unzip the file using shell command for reliability
        local outdir "$build/input/fars/FARS`year'"
        capture mkdir "`outdir'"
        !unzip -o "`zipfile'" -d "`outdir'" > /dev/null 2>&1

        * Find and read accident file
        local accfile ""
        local vehfile ""

        * Use bash find to locate files reliably
        tempfile accpath vehpath
        !find "`outdir'" -iname "accident.csv" -o -iname "acc`year'.csv" 2>/dev/null | head -1 > `accpath'
        !find "`outdir'" -iname "vehicle.csv" -o -iname "veh`year'.csv" 2>/dev/null | head -1 > `vehpath'

        file open accf using `accpath', read text
        file read accf line
        local accfile "`line'"
        file close accf

        file open vehf using `vehpath', read text
        file read vehf line
        local vehfile "`line'"
        file close vehf

        if "`accfile'" == "" {
            di " no accident file found"
            continue
        }

        * Read accident file
        clear
        quietly capture import delimited "`accfile'", clear

        if _rc != 0 {
            di " error reading accident file"
            continue
        }

        * Standardize variable names to uppercase
        foreach var of varlist * {
            local newname = upper("`var'")
            capture rename `var' `newname'
        }

        * Get state FIPS
        capture gen state_fips = string(STATE, "%02.0f")
        if _rc != 0 {
            capture gen state_fips = string(state, "%02.0f")
        }

        * Get case number
        capture gen st_case = ST_CASE
        if _rc != 0 {
            capture gen st_case = st_case
            if _rc != 0 {
                gen st_case = _n
            }
        }

        * Get fatality count
        capture gen fatalities = FATALS
        if _rc != 0 {
            capture gen fatalities = fatals
            if _rc != 0 {
                gen fatalities = 1
            }
        }

        gen year = `year'

        * Initialize hit_run to 0
        gen hit_run = 0

        * Try to read vehicle file for hit-run indicator
        if "`vehfile'" != "" {
            preserve
            clear
            quietly capture import delimited "`vehfile'", clear

            if _rc == 0 {
                * Standardize variable names
                foreach var of varlist * {
                    local newname = upper("`var'")
                    capture rename `var' `newname'
                }

                * Get case number
                capture gen st_case = ST_CASE
                if _rc != 0 {
                    capture gen st_case = st_case
                }

                * Find hit-run variable (varies by year)
                local hrvar ""
                foreach v of varlist * {
                    if strpos(upper("`v'"), "HIT") > 0 & strpos(upper("`v'"), "RUN") > 0 {
                        local hrvar "`v'"
                        continue, break
                    }
                }

                if "`hrvar'" != "" {
                    * FARS HIT_RUN codes: 1-4 are all "Yes" categories
                    gen hr_flag = inlist(`hrvar', 1, 2, 3, 4)

                    * Aggregate to crash level (max hit_run across vehicles)
                    collapse (max) hr_flag, by(st_case)

                    tempfile hrdata
                    save `hrdata', replace
                }
                else {
                    clear
                }
            }
            restore

            * Merge hit-run indicator
            capture confirm file `hrdata'
            if _rc == 0 {
                merge m:1 st_case using `hrdata', keep(1 3) nogen
                capture replace hit_run = hr_flag if hr_flag != .
                capture drop hr_flag
            }
        }

        * Keep only needed variables
        keep state_fips year fatalities hit_run

        * Count crashes and hit-runs
        local n_crashes = _N
        quietly count if hit_run == 1
        local n_hr = r(N)

        * Append to master dataset
        append using "$build/output/fars_raw.dta"
        save "$build/output/fars_raw.dta", replace

        di " `n_crashes' crashes, `n_hr' hit-run"
    }

    * Clean up - remove empty first observation
    use "$build/output/fars_raw.dta", clear
    drop if missing(year)
    save "$build/output/fars_raw.dta", replace

    local total_crashes = _N
    di ""
    di "  Saved `total_crashes' crash records to cache"
}

di "  FARS download complete."
