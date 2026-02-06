# 01_summary_stats.R - Summary statistics

library(dplyr)
library(tidyr)

# Load analysis data
analysis_data <- readRDS(file.path(build, "output", "analysis_data.rds"))

# Summary statistics for main variables
summary_stats <- analysis_data %>%
  summarise(
    n_obs = n(),
    across(c(total_fatalities, hr_fatalities, nhr_fatalities,
             ln_hr, ln_nhr, treated),
           list(
             mean = ~mean(., na.rm = TRUE),
             sd = ~sd(., na.rm = TRUE),
             min = ~min(., na.rm = TRUE),
             max = ~max(., na.rm = TRUE)
           ))
  ) %>%
  pivot_longer(everything(), names_to = "stat", values_to = "value")

# Create formatted table
stats_table <- tibble(
  Variable = c("Total Fatalities", "HR Fatalities", "Non-HR Fatalities",
               "Log HR Fatalities", "Log Non-HR Fatalities", "Treated"),
  N = nrow(analysis_data),
  Mean = c(
    mean(analysis_data$total_fatalities),
    mean(analysis_data$hr_fatalities),
    mean(analysis_data$nhr_fatalities),
    mean(analysis_data$ln_hr),
    mean(analysis_data$ln_nhr),
    mean(analysis_data$treated)
  ),
  SD = c(
    sd(analysis_data$total_fatalities),
    sd(analysis_data$hr_fatalities),
    sd(analysis_data$nhr_fatalities),
    sd(analysis_data$ln_hr),
    sd(analysis_data$ln_nhr),
    sd(analysis_data$treated)
  ),
  Min = c(
    min(analysis_data$total_fatalities),
    min(analysis_data$hr_fatalities),
    min(analysis_data$nhr_fatalities),
    min(analysis_data$ln_hr),
    min(analysis_data$ln_nhr),
    min(analysis_data$treated)
  ),
  Max = c(
    max(analysis_data$total_fatalities),
    max(analysis_data$hr_fatalities),
    max(analysis_data$nhr_fatalities),
    max(analysis_data$ln_hr),
    max(analysis_data$ln_nhr),
    max(analysis_data$treated)
  )
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
