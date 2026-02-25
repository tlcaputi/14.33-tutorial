# 04_dd_table.R
# Professional multi-column DiD table
#
# Presents five regression models side by side in a single LaTeX table:
#   m1 — Baseline TWFE, fatal crashes
#   m2 — TWFE + demographic controls
#   m3 — Southern states only (heterogeneity check)
#   m4 — Non-Southern states only (heterogeneity check)
#   m5 — Alternative outcome: serious crashes
#
# Subgroup models (m3, m4) test whether the policy effect differs by region.
# The alternative outcome (m5) checks whether effects generalise beyond
# fatal crashes to the broader category of serious crashes.
#
# Outputs:
#   analysis/output/tables/dd_table.tex

cat("Running 04_dd_table.R...\n")

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

# ---- Create variables ------------------------------------------------
if (!"post_treated" %in% names(dt)) {
  dt[, post_treated := fifelse(!is.na(adoption_year) & year >= adoption_year, 1L, 0L)]
}

# South indicator: the Census Bureau defines the South as the 16 states
# (plus DC) in the "South" region. The analysis_panel uses that labeling.
cat("\nRegions in data:\n")
print(dt[, .N, by = region][order(-N)])

dt[, south := as.integer(region == "South")]

cat("\nSample breakdown:\n")
cat("  Total obs.:", nrow(dt), "\n")
cat("  South obs.:", dt[south == 1, .N], "\n")
cat("  Non-South: ", dt[south == 0, .N], "\n")

# ---- Model 1: Baseline TWFE ------------------------------------------
m1 <- feols(
  fatal_crashes ~ post_treated | state_fips + year,
  data = dt,
  vcov = ~state_fips
)

# ---- Model 2: TWFE + controls ----------------------------------------
m2 <- feols(
  fatal_crashes ~ post_treated + log_pop + median_income | state_fips + year,
  data = dt,
  vcov = ~state_fips
)

# ---- Model 3: South only ---------------------------------------------
# Restriction: south == 1
# This tests whether the policy was particularly effective (or ineffective)
# in Southern states, which often have higher baseline crash rates.
m3 <- feols(
  fatal_crashes ~ post_treated + log_pop + median_income | state_fips + year,
  data = dt[south == 1],
  vcov = ~state_fips
)

# ---- Model 4: Non-South only -----------------------------------------
m4 <- feols(
  fatal_crashes ~ post_treated + log_pop + median_income | state_fips + year,
  data = dt[south == 0],
  vcov = ~state_fips
)

# ---- Model 5: Serious crashes outcome --------------------------------
# Uses the same specification as m2 but replaces the outcome.
# If the policy reduces fatalities but not serious crashes (or vice versa),
# that tells us something about the mechanism.
m5 <- feols(
  serious_crashes ~ post_treated + log_pop + median_income | state_fips + year,
  data = dt,
  vcov = ~state_fips
)

# ---- Console output --------------------------------------------------
cat("\n--- Model results ---\n")
for (i in 1:5) {
  cat(sprintf("\nm%d:\n", i))
  print(summary(get(paste0("m", i))))
}

# ---- Export LaTeX table ----------------------------------------------
dir.create(file.path(root, "analysis/output/tables"),
           showWarnings = FALSE, recursive = TRUE)

# Column headers appear above model numbers in a multi-row header.
# We use a list to create a grouped header:
#   Row 1: "Full sample" spanning cols 1-2, "By region" spanning 3-4, "Alt. outcome" col 5
#   Row 2: individual model labels
etable(
  m1, m2, m3, m4, m5,
  title   = "Difference-in-Differences: Robustness Checks",
  headers = list(
    "Full sample" = 2,
    "By region"   = 2,
    "Alt.\\ DV"   = 1
  ),
  dict = c(
    post_treated  = "Post $\\times$ Treated",
    log_pop       = "log(Population)",
    median_income = "Median income",
    fatal_crashes   = "Fatal crashes",
    serious_crashes = "Serious crashes"
  ),
  notes  = "All models include state and year fixed effects. Standard errors clustered by state.",
  file   = file.path(root, "analysis/output/tables/dd_table.tex"),
  replace = TRUE
)

cat("\n  Saved dd_table.tex\n")
