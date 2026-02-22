# Setup — master.R sets these; edit below if running standalone
if (!exists("root")) {
  root <- "."
  build <- file.path(root, "build")
  analysis <- file.path(root, "analysis")
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(data.table, haven)
}

# Read filtered crash data
crashes <- fread(file.path(build, "output", "crashes_filtered.csv"))

# Collapse to state_fips-year-severity counts
crashes <- crashes[, .(n_crashes = .N), by = .(state_fips, year, severity)]

# Save
fwrite(crashes, file.path(build, "output", "crashes_collapsed.csv"))
