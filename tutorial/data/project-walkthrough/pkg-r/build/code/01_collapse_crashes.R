# 01_collapse_crashes.R
# Collapse individual crash data to state-year level

cat("Running 01_collapse_crashes.R...\n")

# Load packages
pacman::p_load(data.table)

# Read crash data
crash_data <- fread(file.path(root, "build/input/crash_data.csv"))

# Collapse to state_fips-year level
crashes_state_year <- crash_data[, .(
  total_crashes = .N,
  fatal_crashes = sum(severity == "fatal"),
  serious_crashes = sum(severity == "serious"),
  fatal_share = mean(severity == "fatal")
), by = .(state_fips, year)]

# Create output directory if it doesn't exist
dir.create(file.path(root, "build/output"), showWarnings = FALSE, recursive = TRUE)

# Save collapsed data
fwrite(crashes_state_year, file.path(root, "build/output/crashes_state_year.csv"))

cat("  Saved crashes_state_year.csv\n")
cat("  Observations:", nrow(crashes_state_year), "\n")
