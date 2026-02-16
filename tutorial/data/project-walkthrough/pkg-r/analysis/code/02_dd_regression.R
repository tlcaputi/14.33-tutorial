# 02_dd_regression.R
# Difference-in-differences regression analysis

cat("Running 02_dd_regression.R...\n")

# Load packages
pacman::p_load(data.table, fixest)

# Read analysis panel
dt <- fread(file.path(root, "build/output/analysis_panel.csv"))

# Main DD regression
main_dd <- feols(
  fatal_crashes ~ treated + log_pop | state_fips + year,
  data = dt,
  cluster = ~state_fips
)

# Subgroup by region
region_dd <- feols(
  fatal_crashes ~ i(region, treated, ref = "Northeast") + log_pop | state_fips + year,
  data = dt,
  cluster = ~state_fips
)

# Alternative outcome: serious crashes
alt_outcome <- feols(
  serious_crashes ~ treated + log_pop | state_fips + year,
  data = dt,
  cluster = ~state_fips
)

# Create regression table
reg_table <- etable(
  main_dd, region_dd, alt_outcome,
  title = "Difference-in-Differences Results",
  headers = c("Main DD", "By Region", "Serious Crashes"),
  file = file.path(root, "analysis/output/dd_regression_table.tex"),
  replace = TRUE
)

# Print results
cat("\n")
cat("Main DD Results:\n")
print(summary(main_dd))

cat("\n  Saved dd_regression_table.tex\n")
