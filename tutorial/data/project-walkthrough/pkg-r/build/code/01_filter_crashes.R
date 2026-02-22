# Setup — master.R sets these; edit below if running standalone
if (!exists("root")) {
  root <- "."
  build <- file.path(root, "build")
  analysis <- file.path(root, "analysis")
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(data.table, haven)
}

# Read crash data
crashes <- fread(file.path(build, "input", "crash_data.csv"))

# Filter: keep only fatal and serious (drop minor)
crashes <- crashes[severity %in% c("fatal", "serious")]

# Save
fwrite(crashes, file.path(build, "output", "crashes_filtered.csv"))
