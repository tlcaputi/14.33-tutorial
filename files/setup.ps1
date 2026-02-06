# 14.33 Research Project Setup Script (Windows)
# Creates a well-organized project directory following Gentzkow & Shapiro best practices

function Setup-Project {
    param(
        [string]$ProjectName = "my_research_project"
    )

    # Validate project name
    if ($ProjectName -notmatch '^[a-zA-Z0-9_-]+$') {
        Write-Error "Project name can only contain letters, numbers, underscores, and hyphens"
        return
    }

    if (Test-Path $ProjectName) {
        Write-Error "Directory '$ProjectName' already exists"
        return
    }

    Write-Host "Creating project: $ProjectName" -ForegroundColor Green
    Write-Host ""

    # Create directory structure
    $dirs = @(
        "$ProjectName/build/input",
        "$ProjectName/build/code",
        "$ProjectName/build/output",
        "$ProjectName/build/temp",
        "$ProjectName/analysis/input",
        "$ProjectName/analysis/code",
        "$ProjectName/analysis/output/tables",
        "$ProjectName/analysis/output/figures",
        "$ProjectName/analysis/temp",
        "$ProjectName/paper"
    )
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    # Create .gitkeep files
    $gitkeeps = @(
        "$ProjectName/build/input/.gitkeep",
        "$ProjectName/build/output/.gitkeep",
        "$ProjectName/build/temp/.gitkeep",
        "$ProjectName/analysis/input/.gitkeep",
        "$ProjectName/analysis/output/tables/.gitkeep",
        "$ProjectName/analysis/output/figures/.gitkeep",
        "$ProjectName/analysis/temp/.gitkeep"
    )
    foreach ($file in $gitkeeps) {
        New-Item -ItemType File -Path $file -Force | Out-Null
    }

    # Create README.md
    @"
# Research Project

## Directory Structure

```
project/
├── build/          # Data preparation pipeline
│   ├── input/      # Raw data (NEVER modify these files)
│   ├── code/       # Scripts to clean and prepare data
│   ├── output/     # Cleaned datasets ready for analysis
│   └── temp/       # Intermediate files (can be deleted)
│
├── analysis/       # Analysis pipeline
│   ├── input/      # Cleaned data (copy from build/output)
│   ├── code/       # Analysis scripts
│   ├── output/     # Final tables and figures
│   └── temp/       # Intermediate analysis files
│
└── paper/          # Writing
    ├── draft.tex   # Main document
    └── references.bib
```

## How to Run

### Stata
```stata
do master.do
```

### R
```r
source("master.R")
```

### Python
```python
python master.py
```

## Key Principles

1. **Never modify raw data** - Files in `build/input/` are read-only
2. **Save intermediate files** - Number them: `01_imported.dta`, `02_cleaned.dta`
3. **Everything reproducible** - Anyone can run `master.do` and get your results
4. **Use relative paths** - Set working directory once at the top
"@ | Out-File -FilePath "$ProjectName/README.md" -Encoding utf8

    # Create master.do
    @"
/*==============================================================================
    MASTER DO FILE
    Project: [Your Project Name]
    Author:  [Your Name]
    Date:    [Date]

    This file runs all scripts in order to reproduce the analysis.

    INSTRUCTIONS:
    1. Set the project directory below
    2. Run this entire file: do master.do
==============================================================================*/

clear all
set more off
cap log close

* Set project directory (CHANGE THIS TO YOUR PATH)
global project "C:/Users/yourname/Dropbox/my_research_project"
cd "`$project'"

* Start log
log using "master_log.txt", replace text

* ============================================================================
* BUILD: Clean and prepare data
* ============================================================================

do "build/code/01_import_data.do"
* do "build/code/02_clean_data.do"
* do "build/code/03_merge_data.do"

* ============================================================================
* ANALYSIS: Generate results
* ============================================================================

do "analysis/code/01_summary_stats.do"
* do "analysis/code/02_main_regression.do"
* do "analysis/code/03_robustness.do"

* ============================================================================

log close
di "Master file completed successfully!"
"@ | Out-File -FilePath "$ProjectName/master.do" -Encoding utf8

    # Create master.R
    @"
#===============================================================================
#   MASTER R SCRIPT
#   Project: [Your Project Name]
#   Author:  [Your Name]
#   Date:    [Date]
#
#   This file runs all scripts in order to reproduce the analysis.
#===============================================================================

# Clear environment
rm(list = ls())

# Set project directory (CHANGE THIS TO YOUR PATH)
project_dir <- "C:/Users/yourname/Dropbox/my_research_project"
setwd(project_dir)

# Load packages
pacman::p_load(tidyverse, haven, fixest)

# ============================================================================
# BUILD: Clean and prepare data
# ============================================================================

source("build/code/01_import_data.R")
# source("build/code/02_clean_data.R")
# source("build/code/03_merge_data.R")

# ============================================================================
# ANALYSIS: Generate results
# ============================================================================

source("analysis/code/01_summary_stats.R")
# source("analysis/code/02_main_regression.R")
# source("analysis/code/03_robustness.R")

# ============================================================================

cat("\nMaster script completed successfully!\n")
"@ | Out-File -FilePath "$ProjectName/master.R" -Encoding utf8

    # Create master.py
    @"
#===============================================================================
#   MASTER PYTHON SCRIPT
#   Project: [Your Project Name]
#   Author:  [Your Name]
#   Date:    [Date]
#
#   This file runs all scripts in order to reproduce the analysis.
#   Run with: python master.py
#===============================================================================

import os
import subprocess
import sys

# Set project directory (CHANGE THIS TO YOUR PATH)
project_dir = "C:/Users/yourname/Dropbox/my_research_project"
os.chdir(project_dir)

# Helper function to run scripts
def run_script(script_path):
    """Run a Python script and check for errors."""
    print(f"\n{'='*60}")
    print(f"Running: {script_path}")
    print('='*60)
    result = subprocess.run([sys.executable, script_path], capture_output=False)
    if result.returncode != 0:
        raise RuntimeError(f"Script failed: {script_path}")

# ============================================================================
# BUILD: Clean and prepare data
# ============================================================================

run_script("build/code/01_import_data.py")
# run_script("build/code/02_clean_data.py")
# run_script("build/code/03_merge_data.py")

# ============================================================================
# ANALYSIS: Generate results
# ============================================================================

run_script("analysis/code/01_summary_stats.py")
# run_script("analysis/code/02_main_regression.py")
# run_script("analysis/code/03_robustness.py")

# ============================================================================

print("\n" + "="*60)
print("Master script completed successfully!")
print("="*60)
"@ | Out-File -FilePath "$ProjectName/master.py" -Encoding utf8

    # Create starter build scripts
    @"
/*==============================================================================
    01_import_data.do
    Purpose: Import and save raw data
==============================================================================*/

* Import raw data
* import delimited "`$project'/build/input/raw_data.csv", clear

* Basic inspection
* describe
* summarize
* codebook

* Save
* save "`$project'/build/output/01_imported.dta", replace
"@ | Out-File -FilePath "$ProjectName/build/code/01_import_data.do" -Encoding utf8

    @"
#===============================================================================
#   01_import_data.R
#   Purpose: Import and save raw data
#===============================================================================

# Import raw data
# data <- read_csv("build/input/raw_data.csv")

# Basic inspection
# glimpse(data)
# summary(data)

# Save
# write_dta(data, "build/output/01_imported.dta")
"@ | Out-File -FilePath "$ProjectName/build/code/01_import_data.R" -Encoding utf8

    @"
#===============================================================================
#   01_import_data.py
#   Purpose: Import and save raw data
#===============================================================================

import pandas as pd

# Import raw data
# data = pd.read_csv("build/input/raw_data.csv")

# Basic inspection
# print(data.info())
# print(data.describe())

# Save
# data.to_stata("build/output/01_imported.dta")
# Or as Parquet (faster, smaller):
# data.to_parquet("build/output/01_imported.parquet")
"@ | Out-File -FilePath "$ProjectName/build/code/01_import_data.py" -Encoding utf8

    # Create starter analysis scripts
    @"
/*==============================================================================
    01_summary_stats.do
    Purpose: Generate summary statistics
==============================================================================*/

* Load cleaned data
* use "`$project'/build/output/cleaned_data.dta", clear

* Summary statistics
* summarize

* Export summary table
* estpost summarize
* esttab using "`$project'/analysis/output/tables/summary_stats.tex", ///
*     cells("mean(fmt(2)) sd(fmt(2)) min max count") replace
"@ | Out-File -FilePath "$ProjectName/analysis/code/01_summary_stats.do" -Encoding utf8

    @"
#===============================================================================
#   01_summary_stats.R
#   Purpose: Generate summary statistics
#===============================================================================

# Load cleaned data
# data <- read_dta("build/output/cleaned_data.dta")

# Summary statistics
# summary(data)

# Create summary table
# library(modelsummary)
# datasummary_skim(data, output = "analysis/output/tables/summary_stats.tex")
"@ | Out-File -FilePath "$ProjectName/analysis/code/01_summary_stats.R" -Encoding utf8

    @"
#===============================================================================
#   01_summary_stats.py
#   Purpose: Generate summary statistics
#===============================================================================

import pandas as pd

# Load cleaned data
# data = pd.read_stata("build/output/cleaned_data.dta")
# Or from Parquet:
# data = pd.read_parquet("build/output/cleaned_data.parquet")

# Summary statistics
# print(data.describe())

# Export summary table to LaTeX
# summary_df = data.describe().T
# summary_df.to_latex("analysis/output/tables/summary_stats.tex")
"@ | Out-File -FilePath "$ProjectName/analysis/code/01_summary_stats.py" -Encoding utf8

    # Create .gitignore
    @"
# Data files (usually too large for git)
*.dta
*.csv
*.xlsx
*.xls

# Temporary files
*/temp/*
!*/temp/.gitkeep

# Stata artifacts
*.log
*.smcl

# R artifacts
.Rhistory
.RData
.Rproj.user

# Python artifacts
__pycache__/
*.pyc
*.pyo
.ipynb_checkpoints/
.venv/
venv/

# LaTeX artifacts
*.aux
*.bbl
*.blg
*.fdb_latexmk
*.fls
*.synctex.gz

# OS files
.DS_Store
Thumbs.db
"@ | Out-File -FilePath "$ProjectName/.gitignore" -Encoding utf8

    # Create basic LaTeX template
    @"
\documentclass[12pt]{article}
\usepackage[margin=1in]{geometry}
\usepackage{times}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{hyperref}

\title{Your Paper Title}
\author{Your Name}
\date{\today}

\begin{document}

\maketitle

\begin{abstract}
Your abstract here.
\end{abstract}

\section{Introduction}

\section{Data}

\section{Empirical Strategy}

\section{Results}

\section{Conclusion}

\bibliographystyle{aer}
\bibliography{references}

\end{document}
"@ | Out-File -FilePath "$ProjectName/paper/draft.tex" -Encoding utf8

    # Create empty bibliography
    New-Item -ItemType File -Path "$ProjectName/paper/references.bib" -Force | Out-Null

    # Success message
    Write-Host "========================================"
    Write-Host "  Project created: $ProjectName" -ForegroundColor Green
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Directory structure:"
    Write-Host "  $ProjectName/"
    Write-Host "  ├── build/      (data preparation)"
    Write-Host "  ├── analysis/   (your analysis)"
    Write-Host "  └── paper/      (your writeup)"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. cd $ProjectName"
    Write-Host "  2. Put your raw data in build/input/"
    Write-Host "  3. Edit build/code/01_import_data.do (or .R or .py)"
    Write-Host "  4. Update the project path in master.do (or master.R or master.py)"
    Write-Host "  5. Run master.do to execute everything"
    Write-Host ""
    Write-Host "Learn more: https://theodorecaputi.com/teaching/14.33/tutorial#project-setup"
}
