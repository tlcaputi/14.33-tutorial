# 01_descriptive_table.R
# Create descriptive statistics table

cat("Running 01_descriptive_table.R...\n")

# Load packages
pacman::p_load(data.table)

# Read analysis panel
dt <- fread(file.path(root, "build/output/analysis_panel.csv"))

# Define treatment groups
dt[, group := fcase(
  is.na(adoption_year), "Untreated",
  year >= adoption_year, "Treated×Post",
  year < adoption_year, "Treated×Pre"
)]

# Variables for descriptive table
vars <- c("fatal_crashes", "serious_crashes", "total_crashes",
          "fatal_share", "population", "median_income", "pct_urban")

# Function to calculate summary stats
calc_stats <- function(x) {
  c(Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    N = sum(!is.na(x)))
}

# Calculate stats for each group
desc_table <- lapply(vars, function(v) {
  all_stats <- calc_stats(dt[[v]])
  treated_post <- calc_stats(dt[group == "Treated×Post", ][[v]])
  treated_pre <- calc_stats(dt[group == "Treated×Pre", ][[v]])
  untreated <- calc_stats(dt[group == "Untreated", ][[v]])

  data.table(
    Variable = v,
    All_Mean = all_stats["Mean"],
    All_SD = all_stats["SD"],
    TreatedPost_Mean = treated_post["Mean"],
    TreatedPost_SD = treated_post["SD"],
    TreatedPre_Mean = treated_pre["Mean"],
    TreatedPre_SD = treated_pre["SD"],
    Untreated_Mean = untreated["Mean"],
    Untreated_SD = untreated["SD"]
  )
})

desc_table <- rbindlist(desc_table)

# Create output directory
dir.create(file.path(root, "analysis/output"), showWarnings = FALSE, recursive = TRUE)

# Save table
fwrite(desc_table, file.path(root, "analysis/output/descriptive_table.csv"))

# Print formatted table
cat("\n")
cat("Descriptive Statistics\n")
cat("======================\n\n")
print(desc_table, digits = 2)

cat("\n  Saved descriptive_table.csv\n")
