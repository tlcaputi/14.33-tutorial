# 02_dd_regression.R
# Difference-in-differences regression
#
# Estimates the effect of a state-level policy on fatal crashes using a
# two-way fixed effects (TWFE) DiD design:
#
#   log(fatal_crashes + 1) = beta * post_treated + gamma_s + delta_t + e
#
# Model 1 — TWFE with no controls (cleanest DiD interpretation)
# Model 2 — TWFE with demographic controls (log pop, income, urban share)
#
# Outputs:
#   analysis/output/tables/dd_results.tex

cat("Running 02_dd_regression.R...\n")

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
dt <- fread(file.path(root, "build/output/analysis_panel.csv"))

# ---- Outcome: log of fatal crashes + 1 ------------------------------
# We add 1 before taking logs to handle zeros (log(0) is undefined).
# This is common practice; the coefficient on post_treated approximates
# the percent change in fatal crashes.
dt[, log_fatal := log(fatal_crashes + 1)]

# ---- Create post_treated ---------------------------------------------
# post_treated = 1 in treated states on or after their adoption year.
dt[, post_treated := treated]

cat("\nSample:", nrow(dt), "state-year observations\n")
cat("States:", dt[, uniqueN(state_fips)], "\n")
cat("Years: ", dt[, min(year)], "to", dt[, max(year)], "\n")
cat("Share post_treated:", round(mean(dt$post_treated), 3), "\n")

# ---- Model 1: TWFE, no controls --------------------------------------
# The | state_fips + year syntax tells feols to absorb both sets of FEs.
# vcov = ~state_fips clusters standard errors at the state level —
# this accounts for serial correlation within states over time.
m1 <- feols(
  log_fatal ~ post_treated | state_fips + year,
  data  = dt,
  vcov  = ~state_fips
)

# ---- Model 2: TWFE with controls -------------------------------------
# Controls: log population (size effect), median income (wealth),
#           pct_urban (driving patterns differ in cities vs. rural areas).
# Note: we use log_pop rather than population so the scale is comparable.
m2 <- feols(
  log_fatal ~ post_treated + log_pop + median_income + pct_urban |
    state_fips + year,
  data  = dt,
  vcov  = ~state_fips
)

# ---- Console output --------------------------------------------------
cat("\nModel 1 — TWFE, no controls:\n")
print(summary(m1))

cat("\nModel 2 — TWFE with controls:\n")
print(summary(m2))

# ---- Export regression table -----------------------------------------
dir.create(file.path(root, "analysis/output/tables"),
           showWarnings = FALSE, recursive = TRUE)

etable(
  m1, m2,
  title   = "Difference-in-Differences: Effect of Policy on Log Fatal Crashes",
  headers = c("No Controls", "With Controls"),
  dict    = c(
    post_treated   = "Post $\\times$ Treated",
    log_pop        = "log(Population)",
    median_income  = "Median income",
    pct_urban      = "Pct.\\ urban"
  ),
  file    = file.path(root, "analysis/output/tables/dd_results.tex"),
  replace = TRUE
)

cat("\n  Saved dd_results.tex\n")
