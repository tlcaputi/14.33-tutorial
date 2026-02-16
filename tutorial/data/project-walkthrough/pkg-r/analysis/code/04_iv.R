# 04_iv.R
# Instrumental variables analysis: class size on test scores
# Inspired by Angrist & Lavy (1999) / Maimonides' Rule

cat("Running 04_iv.R...\n")

# Load packages
pacman::p_load(data.table, fixest)

# Read IV data
dt <- fread(file.path(root, "analysis/code/iv_data.csv"))

cat("\nDataset:", nrow(dt), "schools\n")
cat("Variables:", paste(names(dt), collapse = ", "), "\n")

# First stage: Does enrollment predict class size?
first_stage <- feols(
  class_size ~ enrollment + pct_disadvantaged,
  data = dt,
  vcov = "hetero"
)

# Reduced form: Does enrollment predict test scores?
reduced_form <- feols(
  test_score ~ enrollment + pct_disadvantaged,
  data = dt,
  vcov = "hetero"
)

# OLS (biased): class_size on test_score
ols <- feols(
  test_score ~ class_size + pct_disadvantaged,
  data = dt,
  vcov = "hetero"
)

# 2SLS: Instrument class_size with enrollment
iv_2sls <- feols(
  test_score ~ pct_disadvantaged | 0 | class_size ~ enrollment,
  data = dt,
  vcov = "hetero"
)

# Print results
cat("\nFirst Stage Results:\n")
print(summary(first_stage))

cat("\nF-statistic for weak instruments:\n")
print(fitstat(first_stage, "ivf"))

cat("\nReduced Form Results:\n")
print(summary(reduced_form))

cat("\nOLS Results:\n")
print(summary(ols))

cat("\n2SLS Results:\n")
print(summary(iv_2sls))

# Create comparison table
cat("\nComparison: OLS vs IV\n")
cat(sprintf("  OLS coefficient on class_size:  %8.4f\n", coef(ols)["class_size"]))
cat(sprintf("  IV coefficient on class_size:   %8.4f\n", coef(iv_2sls)["fit_class_size"]))

# Create output directory
dir.create(file.path(root, "analysis/output"), showWarnings = FALSE, recursive = TRUE)

# Export table
iv_table <- etable(
  ols, first_stage, reduced_form, iv_2sls,
  title = "OLS vs IV Results",
  headers = c("OLS", "First Stage", "Reduced Form", "2SLS"),
  file = file.path(root, "analysis/output/iv_table.tex"),
  replace = TRUE
)

# Save comparison CSV
comparison <- data.table(
  Model = c("OLS", "First Stage", "Reduced Form", "2SLS"),
  Coefficient = c(
    coef(ols)["class_size"],
    coef(first_stage)["enrollment"],
    coef(reduced_form)["enrollment"],
    coef(iv_2sls)["fit_class_size"]
  ),
  SE = c(
    se(ols)["class_size"],
    se(first_stage)["enrollment"],
    se(reduced_form)["enrollment"],
    se(iv_2sls)["fit_class_size"]
  )
)

fwrite(comparison, file.path(root, "analysis/output/iv_comparison.csv"))

cat("\n  Saved iv_table.tex and iv_comparison.csv\n")
