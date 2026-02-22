# Master script — sets root and sources all scripts in order
rm(list = ls())

root <- tryCatch({
  dirname(rstudioapi::getActiveDocumentContext()$path)
}, error = function(e) {
  getwd()
})

build    <- file.path(root, "build")
analysis <- file.path(root, "analysis")

if (!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, haven, fixest, ggplot2, rdrobust, modelsummary)

# Build
source(file.path(build, "code", "01_filter_crashes.R"))
source(file.path(build, "code", "02_collapse_crashes.R"))
source(file.path(build, "code", "03_reshape_crashes.R"))
source(file.path(build, "code", "04_append_demographics.R"))
source(file.path(build, "code", "05_collapse_demographics.R"))
source(file.path(build, "code", "06_merge_datasets.R"))

# Analysis
source(file.path(analysis, "code", "01_descriptive_table.R"))
source(file.path(analysis, "code", "02_dd_regression.R"))
source(file.path(analysis, "code", "03_event_study.R"))
source(file.path(analysis, "code", "04_dd_table.R"))
source(file.path(analysis, "code", "05_iv.R"))
source(file.path(analysis, "code", "06_rd.R"))

cat("All scripts completed successfully!\n")
