# 02_twfe_regression.R - Two-Way Fixed Effects regression

library(fixest)
library(dplyr)

# Load analysis data
analysis_data <- readRDS(file.path(build, "output", "analysis_data.rds"))

# Build formula with available controls
# Policy controls are always present (created in build script)
controls <- c("alr", "zero_tolerance", "primary_seatbelt", "secondary_seatbelt",
              "mlda21", "gdl", "speed_70", "aggravated_dui")
if ("unemployment" %in% names(analysis_data)) {
  controls <- c(controls, "unemployment")
}
if ("income" %in% names(analysis_data)) {
  controls <- c(controls, "income")
}

# TWFE regression: Hit-and-run fatalities
cat("  Running TWFE regression for hit-run fatalities...\n")
if (length(controls) > 0) {
  hr_formula <- as.formula(paste("ln_hr ~ treated +", paste(controls, collapse = " + "), "| state_fips + year"))
} else {
  hr_formula <- ln_hr ~ treated | state_fips + year
}
hr_model <- feols(hr_formula, data = analysis_data, cluster = ~state_fips)

# TWFE regression: Non-hit-and-run fatalities (placebo)
cat("  Running TWFE regression for non-hit-run fatalities...\n")
if (length(controls) > 0) {
  nhr_formula <- as.formula(paste("ln_nhr ~ treated +", paste(controls, collapse = " + "), "| state_fips + year"))
} else {
  nhr_formula <- ln_nhr ~ treated | state_fips + year
}
nhr_model <- feols(nhr_formula, data = analysis_data, cluster = ~state_fips)

# Extract results
hr_coef <- coef(hr_model)["treated"]
hr_se <- se(hr_model)["treated"]
hr_pval <- pvalue(hr_model)["treated"]

nhr_coef <- coef(nhr_model)["treated"]
nhr_se <- se(nhr_model)["treated"]
nhr_pval <- pvalue(nhr_model)["treated"]

# Create results summary
results_summary <- tibble(
  outcome = c("Hit-Run", "Non-Hit-Run"),
  coefficient = c(hr_coef, nhr_coef),
  std_error = c(hr_se, nhr_se),
  pvalue = c(hr_pval, nhr_pval),
  n_obs = c(nobs(hr_model), nobs(nhr_model)),
  r2 = c(r2(hr_model, "ar2"), r2(nhr_model, "ar2"))
)

# Save results
write.csv(results_summary, file.path(analysis, "output", "tables", "twfe_results.csv"),
          row.names = FALSE)

# Print results
cat("\n  TWFE Results:\n")
cat("  ============================================================\n")
cat(sprintf("  %-20s %12s %12s %10s\n", "", "Coefficient", "Std Error", "p-value"))
cat("  ------------------------------------------------------------\n")
cat(sprintf("  %-20s %12.4f %12.4f %10.4f\n", "Hit-Run:", hr_coef, hr_se, hr_pval))
cat(sprintf("  %-20s %12.4f %12.4f %10.4f\n", "Non-Hit-Run:", nhr_coef, nhr_se, nhr_pval))
cat("  ============================================================\n")

# Store models for other scripts
TWFE_HR_RESULTS <- hr_model
TWFE_NHR_RESULTS <- nhr_model
