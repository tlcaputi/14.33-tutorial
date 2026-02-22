# 05_iv.R
# Instrumental variables (2SLS): class size and student test scores
#
# Inspired by Angrist & Lavy (1999), who use Maimonides' Rule as an
# instrument for class size. The rule says that a class must be split
# once enrollment exceeds a threshold — so enrollment (relative to that
# threshold) shifts class size in a quasi-random way.
#
# Our synthetic iv_data.csv mimics that structure:
#   class_size      — actual class size (potentially endogenous)
#   enrollment      — school enrollment (instrument)
#   test_score      — student achievement outcome
#   pct_disadvantaged — school-level control variable
#
# The OLS estimate of class size on test scores is biased because schools
# with high-achieving students may be assigned smaller classes (reverse
# causality) or because omitted variables (e.g. funding) affect both.
# 2SLS isolates variation in class size that comes only from enrollment.
#
# Outputs:
#   analysis/output/tables/iv_results.tex

cat("Running 05_iv.R...\n")

# ------------------------------------------------------------------
# Setup — master.R sets these; edit below if running standalone
if (!exists("root")) {
  root     <- "."
  build    <- file.path(root, "build")
  analysis <- file.path(root, "analysis")
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(data.table, fixest, ggplot2)
}
# ------------------------------------------------------------------

pacman::p_load(data.table, fixest)

# ---- Read data -------------------------------------------------------
dt <- fread(file.path(root, "analysis/code/iv_data.csv"))

cat("\nDataset:", nrow(dt), "schools\n")
cat("Variables:", paste(names(dt), collapse = ", "), "\n")
cat("\nSummary:\n")
print(dt[, lapply(.SD, mean), .SDcols = c("enrollment", "class_size",
                                            "test_score", "pct_disadvantaged")])

# ---- First stage: Does enrollment predict class size? ----------------
# A strong first stage (F > 10, rule of thumb) validates the instrument.
# We expect a positive coefficient: more students -> bigger classes.
first_stage <- feols(
  class_size ~ enrollment + pct_disadvantaged,
  data = dt,
  vcov = "hetero"   # Heteroskedasticity-robust SEs
)

cat("\nFirst Stage:\n")
print(summary(first_stage))

# F-statistic for instrument strength
cat("\nFirst-stage F-statistic (weak instrument test):\n")
print(fitstat(first_stage, "ivf"))

# ---- Reduced form: Does enrollment predict test scores? --------------
# The reduced form skips the endogenous regressor entirely and asks:
# does the instrument (enrollment) predict the outcome (test_score)?
# If it does, and the first stage is strong, we have a valid instrument.
reduced_form <- feols(
  test_score ~ enrollment + pct_disadvantaged,
  data = dt,
  vcov = "hetero"
)

cat("\nReduced Form:\n")
print(summary(reduced_form))

# ---- OLS (potentially biased) ----------------------------------------
# OLS regresses test_score on class_size directly. If higher-quality
# schools have smaller classes, OLS will OVERESTIMATE the benefit of
# small class sizes (or underestimate the harm of large ones).
ols_model <- feols(
  test_score ~ class_size + pct_disadvantaged,
  data = dt,
  vcov = "hetero"
)

cat("\nOLS (likely biased):\n")
print(summary(ols_model))

# ---- 2SLS: Instrument class_size with enrollment ---------------------
# fixest syntax: outcome ~ exogenous controls | FEs | endogenous ~ instrument
# Here we have no FEs, so the middle slot is 0.
# The 2SLS coefficient gives us the LATE: the effect of class size on
# test scores for students whose class size is moved by enrollment.
iv_2sls <- feols(
  test_score ~ pct_disadvantaged | 0 | class_size ~ enrollment,
  data = dt,
  vcov = "hetero"
)

cat("\n2SLS:\n")
print(summary(iv_2sls))

# ---- Compare OLS vs 2SLS --------------------------------------------
cat("\n--- OLS vs IV comparison ---\n")
cat(sprintf("  OLS: class_size coefficient = %7.4f (SE = %.4f)\n",
            coef(ols_model)["class_size"],
            se(ols_model)["class_size"]))
cat(sprintf("  2SLS: class_size coefficient = %7.4f (SE = %.4f)\n",
            coef(iv_2sls)["fit_class_size"],
            se(iv_2sls)["fit_class_size"]))
cat("  (A larger negative 2SLS coefficient suggests OLS is upward biased.)\n")

# ---- Export regression table ----------------------------------------
dir.create(file.path(root, "analysis/output/tables"),
           showWarnings = FALSE, recursive = TRUE)

etable(
  first_stage, reduced_form, ols_model, iv_2sls,
  title   = "IV Results: Class Size and Student Achievement",
  headers = c("First Stage", "Reduced Form", "OLS", "2SLS"),
  dict    = c(
    class_size        = "Class size",
    enrollment        = "Enrollment (instrument)",
    pct_disadvantaged = "Pct.\\ disadvantaged",
    test_score        = "Test score",
    fit_class_size    = "Class size (instrumented)"
  ),
  notes  = "Heteroskedasticity-robust standard errors. First-stage outcome is class size; all other models have test score as outcome.",
  file   = file.path(root, "analysis/output/tables/iv_results.tex"),
  replace = TRUE
)

cat("\n  Saved iv_results.tex\n")
