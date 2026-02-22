# Tutorial Worked Examples - Current State

**Last Updated:** 2026-02-16
**Status:** All Complete and Verified

## Overview

Three tutorial projects, each with Stata/R/Python versions producing **identical numerical results** (within floating-point precision). All code uses consistent packages and specifications across languages.

---

## Project 1: BAC Replication (French & Gumus 2024)

### Location
```
tutorial/worked-examples/
├── bac-replication-python/     # Python package
├── bac-replication-r/          # R package
├── bac-replication-stata/      # Stata package
├── bac-replication-python.zip  # Downloadable
├── bac-replication-r.zip
└── bac-replication-stata.zip
```

### How to Run
```bash
# Python
cd bac-replication-python && python main.py

# R
cd bac-replication-r && Rscript master.R

# Stata
cd bac-replication-stata && stata-se -b do master.do
```

### Requirements
- **Python:** pandas, numpy, pyfixest, matplotlib, requests
- **R:** tidyverse, fixest, modelsummary, httr
- **Stata:** reghdfe, estout (auto-installed if missing)

### Expected Results (TWFE)
| Outcome | Coefficient | Std Error | p-value | N |
|---------|------------|-----------|---------|-----|
| Hit-Run | 0.0584 | 0.0446 | 0.196 | 1,350 |
| Non-Hit-Run | 0.0178 | 0.0172 | 0.305 | 1,350 |

### Verification Status
- **148 numeric comparisons** across TWFE, event study, summary stats
- Coefficients, SEs, p-values: match to 10+ decimal places across all 3 languages
- R² only difference: Stata 0.9134 vs R/Python 0.9135 (unavoidable reghdfe vs fixest df correction)

### Output Files (in `analysis/output/`)
**Tables:** `twfe_results.csv`, `summary_stats.csv`, `es_coefficients_hr.csv`, `es_coefficients_nhr.csv`, `table2_regression.tex`, `table3_event_study.tex`
**Figures:** `event_study_hr.png`, `event_study_nhr.png`, `event_study_combined.png`

### Package Structure
```
bac-replication-{language}/
├── master.{ext} / main.py
├── build/
│   ├── code/
│   │   ├── 01_download_fars     # Download FARS from NHTSA (1982-2008)
│   │   ├── 02_clean_fars        # Clean and aggregate
│   │   └── 03_merge_controls    # Add policy controls + FRED unemployment
│   └── output/                  # Cleaned data (created at runtime)
└── analysis/
    ├── code/
    │   ├── 01_summary_stats     # Descriptive statistics
    │   ├── 02_twfe_regression   # Main TWFE: ln_hr ~ treated + unemployment | state + year
    │   ├── 03_event_study       # Event study with 16 leads/lags
    │   ├── 04_tables            # LaTeX tables
    │   └── 05_figures           # Event study plots
    └── output/
```

### Regression Specification
```
ln_hr ~ treated + unemployment | state_fips + year, cluster(state_fips)
```
- 8 policy controls + unemployment
- CRV1 clustered SEs by state
- Python uses `pyfixest.feols()`, R uses `fixest::feols()`, Stata uses `reghdfe`

---

## Project 2: Project Walkthrough

### Location
```
tutorial/data/
├── project-walkthrough/       # Source directory (Stata/R/Python)
├── project-walkthrough.zip    # Complete package ZIP
├── pkg-stata.zip              # Starter Stata package
├── pkg-r.zip                  # Starter R package
└── pkg-python.zip             # Starter Python package
```

### How to Run
```bash
# Python
cd project-walkthrough && python main.py

# R
cd project-walkthrough && Rscript master.R

# Stata
cd project-walkthrough && stata-se -b do master.do
```

### Expected Results (DD Regression - 4 models)
| Model | DV | Coefficient | SE | p-value | N |
|-------|-----|------------|-----|---------|-----|
| 1 (Basic) | log(fatal+1) | ~value | ~value | ~value | 800 |
| 2 (Controls) | log(fatal+1) | ~value | ~value | ~value | 800 |
| 3 (Region) | log(fatal+1) | interaction coeffs | — | — | 800 |
| 4 (Alt outcome) | log(serious+1) | ~value | ~value | ~value | 800 |

### Verification Status
- **44 coefficients** verified matching across Stata/R/Python
- All 5 analyses (descriptive, DD, event study, IV, RD) produce identical results
- Packages: Python uses `pyfixest` + `statsmodels`, R uses `fixest` + `rdrobust`, Stata uses `reghdfe` + `ivreg2` + `rdrobust`

### Analyses
1. **Descriptive Table** (`01_descriptive_table`) - Summary stats by treatment group
2. **DD Regression** (`02_dd_regression`) - 4 models with log DV, controls, region interactions
3. **Event Study** (`03_event_study`) - log DV with log_pop control, binned -5 to +5
4. **IV** (`04_iv`) - test_score ~ pct_disadvantaged (class_size = enrollment), robust SEs
5. **RD** (`05_rd`) - 365-day bandwidth, male + income covariates, robust SEs

---

## Project 3: Texting Bans

### Location
```
tutorial/worked-examples/
└── texting-bans-event-study.html    # HTML tutorial page only
```

### Status
No standalone code packages exist. This is an HTML tutorial page only with inline code examples. The code examples in the HTML use `pyfixest` for Python (updated in session 3).

---

## Key Technical Decisions

### Python Package: linearmodels → pyfixest
- **Why:** `linearmodels` (PanelOLS, IV2SLS) uses different degrees-of-freedom corrections than `fixest`/`reghdfe`, causing SE mismatches of ~2.4%
- **Fix:** Switched all Python code to `pyfixest`, a Python port of R's `fixest`. Produces identical CRV1 clustered SEs.
- **Syntax changes:**
  - FE: `pf.feols('Y ~ X | fe1 + fe2', data=df, vcov={'CRV1': 'cluster_var'})`
  - IV: `pf.feols('Y ~ exog | FE | endog ~ instrument', data=df, vcov='hetero')`
  - Event study: `pf.feols('Y ~ i(time, treated, ref=c(-1, -1000)) | fe1 + fe2', ...)`
- **print() behavior:** `pyfixest` `.summary()` prints to stdout and returns None. Do NOT wrap in `print()`. For `statsmodels`, `print(model.summary())` IS correct.

### R² Reporting
- R uses `r2(model, "ar2")` = overall adjusted R²
- Python uses `model._adj_r2` = overall adjusted R²
- Stata uses `e(r2_a)` from reghdfe = overall adjusted R²
- Do NOT use `"war2"` or `_adj_r2_within` — those are within R² (completely different metric, ~0.002 vs ~0.913)
- Tiny R² difference (~0.00007) between Stata and R/Python is unavoidable

### SE Alignment
- All languages use CRV1 (cluster-robust variance, type 1) by state
- `pyfixest` matches `fixest` exactly (same C++ engine)
- `reghdfe` matches to 10+ decimal places

---

## HTML Tutorial Pages

All HTML tutorial pages have been updated for code consistency:

| File | Python Package Used |
|------|-------------------|
| `getting-started.html` | `pip install pyfixest` |
| `basic-regression.html` | `pf.feols()` for FE models |
| `regression.html` | `pf.feols()` for FE, IV, DiD |
| `causal-methods.html` | `pf.feols()` for IV, DiD |
| `causal-inference.html` | `pf.feols()` with `i()` for event study |
| `examples/bac-replication.html` | `pf.feols()` for TWFE |
| `sessions/session3.html` | `model.summary()` (no print wrapper) |

**Zero references to `linearmodels`, `PanelOLS`, or `IV2SLS` remain in any HTML file.**

---

## Known Acceptable Differences

1. **BAC R² (Stata vs R/Python):** ~0.00007 due to reghdfe vs fixest df corrections
2. **Stata float precision:** Stata outputs fewer decimal places in CSVs by default
3. **PW Stata float → double:** Some Stata scripts needed `recast double` to avoid float truncation

---

## Related Documentation

- Session 3 changelog: `.CHANGELOG/2026-02-16_174925_tutorial-standardization-session3.md`
- BAC tutorial page: `tutorial/examples/bac-replication.html`
- PW tutorial page: `tutorial/examples/project-walkthrough.html`
- Texting bans page: `tutorial/worked-examples/texting-bans-event-study.html`

## ZIP Packages

**Important:** ZIP packages may need to be rebuilt to include the latest code changes from the standardization sessions. The source directories contain the updated code, but the ZIPs may be stale.

### Rebuild commands:
```bash
# BAC packages
cd tutorial/worked-examples
zip -r bac-replication-python.zip bac-replication-python/ -x "*/build/input/*" "*/build/output/*" "*/analysis/output/*" "*/__pycache__/*"
zip -r bac-replication-r.zip bac-replication-r/ -x "*/build/input/*" "*/build/output/*" "*/analysis/output/*"
zip -r bac-replication-stata.zip bac-replication-stata/ -x "*/build/input/*" "*/build/output/*" "*/analysis/output/*"

# PW packages
cd tutorial/data
zip -r project-walkthrough.zip project-walkthrough/ -x "*/__pycache__/*"
```
