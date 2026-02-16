# 02_merge_datasets.R
# Merge crashes with demographics, policies, and state names

cat("Running 02_merge_datasets.R...\n")

# Load packages
pacman::p_load(data.table, haven)

# Read datasets
crashes <- fread(file.path(root, "build/output/crashes_state_year.csv"))
demographics <- as.data.table(read_dta(file.path(root, "build/input/state_demographics.dta")))
policies <- fread(file.path(root, "build/input/policy_adoptions.csv"))
state_names <- fread(file.path(root, "build/input/state_names.csv"))

# Merge all datasets
analysis_panel <- crashes[demographics, on = .(state_fips, year), nomatch = 0]
analysis_panel <- analysis_panel[policies, on = .(state_fips), nomatch = 0]
analysis_panel <- analysis_panel[state_names, on = .(state_fips), nomatch = 0]

# Create treatment indicator and log population
analysis_panel[, treated := fifelse(year >= adoption_year & !is.na(adoption_year), 1, 0)]
analysis_panel[, log_pop := log(population)]

# Save merged panel
fwrite(analysis_panel, file.path(root, "build/output/analysis_panel.csv"))

cat("  Saved analysis_panel.csv\n")
cat("  Observations:", nrow(analysis_panel), "\n")
cat("  States:", uniqueN(analysis_panel$state_fips), "\n")
cat("  Years:", paste(range(analysis_panel$year), collapse = "-"), "\n")
