# Setup — master.R sets these; edit below if running standalone
if (!exists("root")) {
  root <- "."
  build <- file.path(root, "build")
  analysis <- file.path(root, "analysis")
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(data.table, haven)
}

# Loop over years, read each annual demographic survey file and add year column
years <- 1995:2015
demo_list <- lapply(years, function(yr) {
  dt <- fread(file.path(build, "input", "demographic_survey", paste0("demographic_survey_", yr, ".csv")))
  dt[, year := yr]
  dt
})

# Stack all years together
demographics <- rbindlist(demo_list)

# Save
fwrite(demographics, file.path(build, "output", "demographics_combined.csv"))
