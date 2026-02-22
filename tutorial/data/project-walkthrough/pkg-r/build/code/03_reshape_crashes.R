# Setup — master.R sets these; edit below if running standalone
if (!exists("root")) {
  root <- "."
  build <- file.path(root, "build")
  analysis <- file.path(root, "analysis")
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(data.table, haven)
}

# Read collapsed crash data
crashes <- fread(file.path(build, "output", "crashes_collapsed.csv"))

# Reshape wide: one row per state_fips-year, columns for each severity
crashes <- dcast(crashes, state_fips + year ~ severity, value.var = "n_crashes", fill = 0L)

# Rename severity columns
setnames(crashes, "fatal",   "fatal_crashes")
setnames(crashes, "serious", "serious_crashes")

# Compute total crashes and fatal share
crashes[, total_crashes := fatal_crashes + serious_crashes]
crashes[, fatal_share   := fatal_crashes / total_crashes]

# Save
fwrite(crashes, file.path(build, "output", "crashes_state_year.csv"))
