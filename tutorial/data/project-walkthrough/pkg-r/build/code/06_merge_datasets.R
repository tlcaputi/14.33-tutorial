# Setup — master.R sets these; edit below if running standalone
if (!exists("root")) {
  root <- "."
  build <- file.path(root, "build")
  analysis <- file.path(root, "analysis")
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(data.table, haven)
}

# Read all input datasets
crashes      <- fread(file.path(build, "output", "crashes_state_year.csv"))
demographics <- fread(file.path(build, "output", "demographics_state_year.csv"))
policies     <- fread(file.path(build, "input",  "policy_adoptions.csv"))
state_names  <- fread(file.path(build, "input",  "state_names.csv"))

# Merge crashes + demographics on state_fips x year
panel <- merge(crashes, demographics, by = c("state_fips", "year"), all = TRUE)

# Merge in policy adoption years on state_fips
panel <- merge(panel, policies, by = "state_fips", all.x = TRUE)

# Merge in state names on state_fips
panel <- merge(panel, state_names, by = "state_fips", all.x = TRUE)

# Create treatment indicator: 1 if state adopted policy and year >= adoption year
panel[, post_treated := fifelse(!is.na(adoption_year) & year >= adoption_year, 1L, 0L)]

# Create log population
panel[, log_pop := log(population)]

# Save
fwrite(panel, file.path(build, "output", "analysis_panel.csv"))
