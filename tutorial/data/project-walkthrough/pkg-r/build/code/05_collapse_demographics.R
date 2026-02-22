# Setup — master.R sets these; edit below if running standalone
if (!exists("root")) {
  root <- "."
  build <- file.path(root, "build")
  analysis <- file.path(root, "analysis")
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(data.table, haven)
}

# Read combined demographics
dt <- fread(file.path(build, "output", "demographics_combined.csv"))

# Drop DC (state_fips == 51) and pre-2000 years
dt <- dt[state_fips != 51 & year >= 2000]

# Clean income: strip "$" and "," then convert to numeric
dt[, income := as.numeric(gsub("[$,]", "", income))]

# Weighted collapse to state_fips-year level
result <- dt[, .(
  population    = sum(weight),
  median_income = weighted.mean(income, weight),
  pct_urban     = weighted.mean(urban, weight)
), by = .(state_fips, year)]

# Sanity check: 50 states x 16 years (2000-2015) = 800 rows
stopifnot(nrow(result) == 800)

# Save
fwrite(result, file.path(build, "output", "demographics_state_year.csv"))
