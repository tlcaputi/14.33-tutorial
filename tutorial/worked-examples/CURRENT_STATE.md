# BAC Replication Packages - Current State

**Last Updated:** 2026-02-05
**Status:** ✅ Complete and Working

## Overview

Three fully functional replication packages for the French & Gumus (2024) BAC/hit-and-run tutorial. Each package downloads FARS data automatically from NHTSA and unemployment data from FRED, then produces all tables and figures.

## Package Locations

```
teaching/14.33/tutorial/worked-examples/
├── bac-replication-python/     # Python package
├── bac-replication-r/          # R package
├── bac-replication-stata/      # Stata package
├── bac-replication-python.zip  # Downloadable Python package
├── bac-replication-r.zip       # Downloadable R package
└── bac-replication-stata.zip   # Downloadable Stata package
```

## How to Run Each Package

### Python
```bash
cd bac-replication-python
python main.py
```
**Requirements:** pandas, numpy, linearmodels, matplotlib, requests

### R
```bash
cd bac-replication-r
Rscript master.R
# OR in RStudio: open master.R and run
```
**Requirements:** tidyverse, fixest, modelsummary, httr

### Stata
```bash
cd bac-replication-stata
stata-se -b do master.do
# OR in Stata GUI: open master.do and run
```
**Requirements:** reghdfe, estout (auto-installed if missing)

## Expected Output

All three packages produce **identical results**:

| Outcome | Coefficient | Std Error | p-value | N |
|---------|------------|-----------|---------|-----|
| Hit-Run | 0.0584 | 0.045 | 0.196 | 1,350 |
| Non-Hit-Run | 0.0178 | 0.017 | 0.305 | 1,350 |

### Output Files (in `analysis/output/`)

**Tables:**
- `twfe_results.csv` - Main TWFE regression results
- `summary_stats.csv` - Descriptive statistics
- `es_coefficients_hr.csv` - Hit-run event study coefficients
- `es_coefficients_nhr.csv` - Non-hit-run event study coefficients
- `table2_regression.tex` - LaTeX formatted regression table

**Figures:**
- `event_study_hr.png` - Hit-run event study plot
- `event_study_nhr.png` - Non-hit-run event study plot
- `event_study_combined.png` - Combined event study plot

## Package Structure

Each package follows the same structure:
```
bac-replication-{language}/
├── master.{ext}           # Main script to run everything
├── build/
│   ├── code/
│   │   ├── 01_download_fars.{ext}    # Download FARS from NHTSA
│   │   ├── 02_clean_fars.{ext}       # Clean and aggregate
│   │   └── 03_merge_controls.{ext}   # Add policy controls + FRED
│   ├── input/             # Downloaded raw data (created at runtime)
│   └── output/            # Cleaned data files (created at runtime)
└── analysis/
    ├── code/
    │   ├── 01_summary_stats.{ext}    # Descriptive statistics
    │   ├── 02_twfe_regression.{ext}  # Main TWFE regression
    │   ├── 03_event_study.{ext}      # Event study specification
    │   ├── 04_tables.{ext}           # Generate tables
    │   └── 05_figures.{ext}          # Generate figures
    └── output/
        ├── tables/        # Output tables (created at runtime)
        └── figures/       # Output figures (created at runtime)
```

## Key Implementation Details

### Data Sources
1. **FARS (Fatality Analysis Reporting System)**: Downloaded from NHTSA for years 1982-2008
   - URL pattern: `https://static.nhtsa.gov/nhtsa/downloads/FARS/{year}/National/FARS{year}NationalCSV.zip`
   - Hit-run indicator from vehicle file (HIT_RUN values 1-4 = "yes")

2. **FRED Unemployment Data**: Downloaded from St. Louis Fed
   - URL pattern: `https://fred.stlouisfed.org/graph/fredgraph.csv?id={STATE}UR`
   - State codes: ALUR (Alabama), AKUR (Alaska), etc.

### Policy Control Variables
All packages include the same policy controls with fractional-year coding:
- ALR (Administrative License Revocation)
- Zero Tolerance (for under-21 BAC)
- Primary/Secondary Seatbelt Laws
- MLDA21 (Minimum Legal Drinking Age)
- GDL (Graduated Driver Licensing)
- Speed 70+ mph limits
- Aggravated DUI laws

### Regression Specification
```
ln_hr ~ treated + unemployment + state_FE + year_FE
```
- Standard errors clustered by state
- `treated = 1` if year >= BAC adoption year for that state

## Fixes Applied in This Session

### Python (`03_event_study.py`)
- **Issue:** Syntax error in nested ternary expression
- **Fix:** Line 68 rewritten from:
  ```python
  # BROKEN:
  sig = '*' if abs(row['coefficient'] / row['std_error']) > 1.96 if row['std_error'] > 0 else False else ''
  # FIXED:
  sig = '*' if (row['std_error'] > 0 and abs(row['coefficient'] / row['std_error']) > 1.96) else ''
  ```

### R (`master.R`)
- **Issue:** `rstudioapi::getActiveDocumentContext()` fails when run from command line
- **Fix:** Wrapped in tryCatch:
  ```r
  root <- tryCatch({
    dirname(rstudioapi::getActiveDocumentContext()$path)
  }, error = function(e) {
    getwd()
  })
  ```

### Stata (`01_download_fars.do`)
- **Issue:** FARS 2006-2008 files not found (different ZIP structure)
- **Fix:** Use bash `find` command to locate files:
  ```stata
  !find "`outdir'" -iname "accident.csv" -o -iname "acc`year'.csv" 2>/dev/null | head -1 > `accpath'
  ```

### Stata (`03_merge_controls.do`)
- **Issue 1:** FRED CSV column is `observation_date` not `date`
- **Fix:** Changed `substr(date, 1, 4)` to `substr(observation_date, 1, 4)`

- **Issue 2:** FRED downloads failing intermittently
- **Fix:** Added retry logic (3 attempts per state with 1-second delay)

### Stata (`03_event_study.do`)
- **Issue:** Invalid format string `%+3.0f`
- **Fix:** Changed to `%3.0f` (Stata doesn't support + sign format modifier)

## Testing Verification

All packages were tested end-to-end:
1. ✅ Python: `python main.py` completes successfully
2. ✅ R: `Rscript master.R` completes successfully
3. ✅ Stata: `stata-se -b do master.do` completes successfully
4. ✅ All produce matching coefficients (within floating point precision)
5. ✅ All download 50 states of unemployment data from FRED
6. ✅ All process 27 years of FARS data (1982-2008)

## Files on Website

The zip files are available at:
- `theodorecaputi.com/teaching/14.33/tutorial/worked-examples/bac-replication-python.zip`
- `theodorecaputi.com/teaching/14.33/tutorial/worked-examples/bac-replication-r.zip`
- `theodorecaputi.com/teaching/14.33/tutorial/worked-examples/bac-replication-stata.zip`

## Potential Future Improvements

1. Add README files to each package with usage instructions
2. Add requirements.txt for Python package
3. Consider pre-downloading a sample of FARS data for faster testing
4. Add unit tests for data processing steps

## Related Documentation

- Tutorial page: `teaching/14.33/tutorial/examples/bac-replication.html`
- Main course page: `teaching/14.33/index.html`
