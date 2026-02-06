# 14.33 Tutorial - Current State

Last updated: 2026-02-04 (Session 2)

## Overview

The 14.33 tutorial is a comprehensive guide for economics students learning data analysis in Stata, R, and Python. It's hosted at https://theodorecaputi.com/teaching/14.33/tutorial/

## Tutorial Structure

```
teaching/14.33/tutorial/
├── index.html                    # Main tutorial index
├── getting-started.html          # Setup instructions
├── project-organization.html     # Directory structure guidance
├── finding-project.html          # How to find a research project
├── causal-inference.html         # Causal inference theory
├── data-fundamentals.html        # Data loading, cleaning, reshaping, merging
├── descriptive-analysis.html     # Summary stats, visualization, tables
├── regression.html               # OLS, FE, IV, DiD, event studies
├── advanced.html                 # Advanced topics
├── examples/
│   └── bac-replication.html      # Complete worked example (BAC laws)
├── data/                         # Data files for examples
│   ├── bacon_example.dta
│   └── bacon_example.csv
├── scripts/                      # Downloadable scripts
│   └── session3/
│       ├── session3.R
│       └── session3.py
└── sessions/                     # In-class session materials
    ├── session1.html
    ├── session2.html
    └── session3.html
```

## Recent Changes (2026-02-04, Session 2)

### 1. Event Study Code Fixes (fixest/pyfixest)

**Problem:** Event study code was using incorrect syntax for handling never-treated units.

**Before (incorrect):**
```r
feols(y ~ i(time_to_treat, ref = -1) | state + year, ...)
```

**After (correct):**
```r
# Never-treated units coded as -1000 (outside data range)
df$time_to_treat <- ifelse(is.na(df$adoption_year), -1000, df$year - df$adoption_year)
df$ever_treated <- !is.na(df$adoption_year)

feols(y ~ i(time_to_treat, ever_treated, ref = c(-1, -1000)) | state + year, ...)
```

**Key insight:** Never-treated units don't have a meaningful "time to treatment." We assign them -1000 (outside the data range) and exclude via `ref = c(-1, -1000)` to drop both the reference period AND the never-treated group.

**Files updated:**
- `regression.html` - Main event study section
- `examples/bac-replication.html` - Worked example
- `sessions/session3.html` - In-class materials
- `scripts/session3/session3.R`
- `scripts/session3/session3.py`
- `causal-inference.html` - Event study example

### 2. Package Loading Standardization

**Change:** Replaced all `library()` calls with `pacman::p_load()` throughout tutorial.

**Rationale:** `pacman::p_load()` auto-installs missing packages, reducing student friction.

**Files updated:** All tutorial HTML files containing R code (~70+ replacements)

### 3. BAC Worked Example Enhancements

**File:** `examples/bac-replication.html`

Added three new explanatory sections:

#### a. Data Workflow Explanation (new section)
Explains the multi-source data workflow:
1. Identify your data sources
2. Clean each dataset separately
3. Aggregate to a common unit of analysis
4. Standardize identifiers (e.g., state FIPS codes)
5. Merge everything together
6. Run all analyses on the merged dataset

#### b. Event Study Interpretation (expanded section)
Step-by-step guide to reading an event study plot:
- **Step 1:** Check pre-treatment coefficients (parallel trends)
- **Step 2:** Check for anticipation effects
- **Step 3:** Examine post-treatment effect (direction, magnitude, dynamics)
- **Putting It Together:** The story the event study tells

Includes interpretation of the specific BAC → hit-and-run results.

#### c. Publication-Ready Output Explanations
Added explanations for why each step matters when creating tables/figures.

### 4. Visual Examples for Event Studies

**File:** `regression.html`

Added inline SVG diagrams showing:
- Event study with parallel pre-trends vs. without
- Event studies with different dynamics (immediate, gradual, fading)
- Event studies with vs. without anticipation effects

## Key Technical Details

### Event Study Pattern (fixest)

```r
# Step 1: Create time-to-treatment variable
df <- df %>%
  mutate(
    time_to_treat = year - adoption_year,
    # Never-treated → -1000 (outside data range)
    time_to_treat = ifelse(is.na(time_to_treat), -1000, time_to_treat),
    # Treatment indicator
    ever_treated = !is.na(adoption_year)
  )

# Step 2: Event study regression
model <- feols(
  outcome ~ i(time_to_treat, ever_treated, ref = c(-1, -1000)) | state + year,
  data = df,
  vcov = ~state
)

# Step 3: Plot
iplot(model)
```

**Why -1000?**
- Must be outside the range of actual event times
- `ref = c(-1, -1000)` excludes both reference period AND never-treated
- See fixest walkthrough: https://lrberge.github.io/fixest/articles/fixest_walkthrough.html

### pyfixest Equivalent

```python
df['time_to_treat'] = df['year'] - df['adoption_year']
df['time_to_treat'] = df['time_to_treat'].fillna(-1000).astype(int)
df['ever_treated'] = df['adoption_year'].notna().astype(int)

model = pf.feols(
    'outcome ~ i(time_to_treat, ever_treated, ref=c(-1, -1000)) | state + year',
    vcov={'CRV1': 'state'}, data=df
)
```

### Callout CSS Classes
```css
.callout-info     /* Blue - informational */
.callout-success  /* Green - key principles, good practices */
.callout-warning  /* Orange - cautions, think-about-it boxes */
.callout-danger   /* Red - common mistakes, critical warnings */
```

### Required Packages

**R:**
- pacman (for p_load)
- tidyverse (dplyr, tidyr, stringr, ggplot2)
- haven (Stata files)
- fixest (fixed effects, event studies)
- modelsummary (tables)

**Python:**
- pandas, numpy
- pyfixest (R-style syntax)
- matplotlib

**Stata:**
- reghdfe
- coefplot (for event study plots)

## Build & Deployment

```bash
# Build locally
cd gh-website
npx @11ty/eleventy

# Serve with live reload
npx @11ty/eleventy --serve

# Deploy
git add .
git commit -m "Description"
git push origin master
```

Live at: https://theodorecaputi.com/teaching/14.33/tutorial/

## Git Commits (This Session)

1. `8b5fc2d` - Add data workflow explanation to BAC worked example
2. `2d8b18c` - Add detailed event study interpretation to BAC worked example

(Earlier commits from previous context handled fixest syntax fixes and library→pacman conversions)

## Known Issues

None currently.

## Next Steps / Future Work

1. **Callout standardization plan** still has inline styles in some files (see `~/.claude/plans/tingly-humming-horizon.md`)
2. Could add more worked examples beyond BAC replication
3. Session scripts could be expanded with more exercises

## Related Documentation

- `examples/bac-replication.html` - Complete worked example
- `worked-examples/bac-hit-and-run/CURRENT_STATE.md` - BAC analysis code state
- `~/.claude/plans/tingly-humming-horizon.md` - Callout standardization plan
