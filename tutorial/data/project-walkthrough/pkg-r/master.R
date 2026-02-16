# Master script for project walkthrough
# Sets root directory and sources all scripts in order

# Set root directory
root <- tryCatch({
  dirname(rstudioapi::getActiveDocumentContext()$path)
}, error = function(e) {
  getwd()
})

# Load package manager
if (!require("pacman")) install.packages("pacman")

# Load required packages
pacman::p_load(
  data.table,
  haven,
  fixest,
  ggplot2,
  rdrobust
)

# Source build scripts
cat("Running build scripts...\n")
source(file.path(root, "build/code/01_collapse_crashes.R"))
source(file.path(root, "build/code/02_merge_datasets.R"))

# Source analysis scripts
cat("Running analysis scripts...\n")
source(file.path(root, "analysis/code/01_descriptive_table.R"))
source(file.path(root, "analysis/code/02_dd_regression.R"))
source(file.path(root, "analysis/code/03_event_study.R"))
source(file.path(root, "analysis/code/04_iv.R"))
source(file.path(root, "analysis/code/05_rd.R"))

cat("All scripts completed successfully!\n")
