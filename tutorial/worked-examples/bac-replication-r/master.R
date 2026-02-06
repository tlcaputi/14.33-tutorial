#==============================================================================
#    Master Script: BAC Replication (French & Gumus 2024)
#
#    This script downloads all data automatically and produces all tables
#    and figures from the tutorial. Run time: ~15-20 minutes.
#
#    Instructions:
#    1. Open this file in RStudio or R
#    2. Run the entire script (Ctrl+Shift+Enter in RStudio)
#    3. Wait ~15-20 minutes for data download and analysis
#    4. Find results in analysis/output/
#==============================================================================

rm(list = ls())

# Auto-detect project root directory
# Try RStudio API first, then fall back to working directory
root <- tryCatch({
  dirname(rstudioapi::getActiveDocumentContext()$path)
}, error = function(e) {
  # Running from Rscript - use working directory
  getwd()
})

if (is.null(root) || root == "" || root == ".") {
  root <- getwd()
}

# Verify we're in the right directory
if (!file.exists(file.path(root, "master.R"))) {
  stop("Please run this script from the bac-replication-r directory")
}

# Define paths (don't change these)
build <- file.path(root, "build")
analysis <- file.path(root, "analysis")

cat("BAC Replication Package (R)\n")
cat("============================\n")
cat("Root directory:", root, "\n\n")

# Create directories
dir.create(file.path(build, "input"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(build, "output"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(analysis, "output", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(analysis, "output", "figures"), recursive = TRUE, showWarnings = FALSE)

# Install required packages if not present
required_packages <- c("tidyverse", "fixest", "modelsummary", "broom", "httr", "readr")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing package:", pkg, "\n")
    install.packages(pkg, repos = "https://cloud.r-project.org/")
  }
}

# Load packages
library(tidyverse)
library(fixest)
library(modelsummary)
library(broom)
library(httr)
library(readr)

# Run the build scripts (data preparation)
cat("\n[1/8] Downloading FARS data (1982-2008)...\n")
source(file.path(build, "code", "01_download_fars.R"))

cat("\n[2/8] Cleaning FARS data...\n")
source(file.path(build, "code", "02_clean_fars.R"))

cat("\n[3/8] Merging policy controls...\n")
source(file.path(build, "code", "03_merge_controls.R"))

# Run the analysis
cat("\n[4/8] Computing summary statistics...\n")
source(file.path(analysis, "code", "01_summary_stats.R"))

cat("\n[5/8] Running TWFE regression...\n")
source(file.path(analysis, "code", "02_twfe_regression.R"))

cat("\n[6/8] Running event study...\n")
source(file.path(analysis, "code", "03_event_study.R"))

cat("\n[7/8] Creating tables...\n")
source(file.path(analysis, "code", "04_tables.R"))

cat("\n[8/8] Creating figures...\n")
source(file.path(analysis, "code", "05_figures.R"))

cat("\n============================\n")
cat("Done! All results saved to:\n")
cat("  Tables:", file.path(analysis, "output", "tables"), "\n")
cat("  Figures:", file.path(analysis, "output", "figures"), "\n")
