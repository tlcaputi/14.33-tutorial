# 01_summary_stats.R - Summary statistics

library(dplyr)
library(tidyr)

# Load analysis data
analysis_data <- readRDS(file.path(build, "output", "analysis_data.rds"))

# Core variables always present
vars <- c("total_fatalities", "hr_fatalities", "nhr_fatalities",
          "ln_hr", "ln_nhr", "treated")
labels <- c("Total Fatalities", "HR Fatalities", "Non-HR Fatalities",
            "Log HR Fatalities", "Log Non-HR Fatalities", "Treated")

# Add control variables if available
if ("unemployment" %in% names(analysis_data)) {
  vars <- c(vars, "unemployment")
  labels <- c(labels, "Unemployment")
}
if ("income" %in% names(analysis_data)) {
  vars <- c(vars, "income")
  labels <- c(labels, "Income")
}

# Summary statistics for main variables
summary_stats <- analysis_data %>%
  summarise(
    n_obs = n(),
    across(all_of(vars),
           list(
             mean = ~mean(., na.rm = TRUE),
             sd = ~sd(., na.rm = TRUE),
             min = ~min(., na.rm = TRUE),
             max = ~max(., na.rm = TRUE)
           ))
  ) %>%
  pivot_longer(everything(), names_to = "stat", values_to = "value")

# Create formatted table dynamically
stats_table <- tibble(
  Variable = labels,
  N = nrow(analysis_data),
  Mean = sapply(vars, function(v) mean(analysis_data[[v]], na.rm = TRUE)),
  SD = sapply(vars, function(v) sd(analysis_data[[v]], na.rm = TRUE)),
  Min = sapply(vars, function(v) min(analysis_data[[v]], na.rm = TRUE)),
  Max = sapply(vars, function(v) max(analysis_data[[v]], na.rm = TRUE))
)

# Save summary stats
write.csv(stats_table, file.path(analysis, "output", "tables", "summary_stats.csv"),
          row.names = FALSE)

# Summary by treatment status
summary_by_treatment <- analysis_data %>%
  group_by(treated) %>%
  summarise(
    n_obs = n(),
    mean_hr = mean(hr_fatalities),
    mean_nhr = mean(nhr_fatalities),
    mean_ln_hr = mean(ln_hr),
    mean_ln_nhr = mean(ln_nhr),
    .groups = "drop"
  )

write.csv(summary_by_treatment,
          file.path(analysis, "output", "tables", "summary_by_treatment.csv"),
          row.names = FALSE)

cat("  Summary statistics saved\n")
print(stats_table)
