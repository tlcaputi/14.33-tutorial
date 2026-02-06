# 03_event_study.R - Event study specification

library(fixest)
library(dplyr)
library(tidyr)

# Load analysis data
analysis_data <- readRDS(file.path(build, "output", "analysis_data.rds"))

# Bin event time at endpoints (-5 to +10)
MIN_ET <- -5
MAX_ET <- 10

analysis_data <- analysis_data %>%
  mutate(
    event_time_binned = case_when(
      is.na(event_time) ~ NA_real_,
      event_time < MIN_ET ~ MIN_ET,
      event_time > MAX_ET ~ MAX_ET,
      TRUE ~ event_time
    )
  )

# Get unique event times (excluding -1 as reference)
event_times <- sort(unique(analysis_data$event_time_binned[!is.na(analysis_data$event_time_binned)]))
event_times <- event_times[event_times != -1]

# Build formula with available controls
controls <- c()
if ("unemployment" %in% names(analysis_data)) {
  controls <- c(controls, "unemployment")
}

# Event study: Hit-and-run
cat("  Running event study: ln_hr ~ event_time_dummies + FE\n")
if (length(controls) > 0) {
  hr_es_formula <- as.formula(paste(
    "ln_hr ~ i(event_time_binned, ref = -1) +",
    paste(controls, collapse = " + "),
    "| state_fips + year"
  ))
} else {
  hr_es_formula <- ln_hr ~ i(event_time_binned, ref = -1) | state_fips + year
}
hr_es_model <- feols(hr_es_formula, data = analysis_data, cluster = ~state_fips)

# Extract coefficients for hit-run
hr_coefs <- tibble(
  event_time = event_times,
  coefficient = coef(hr_es_model)[paste0("event_time_binned::", event_times)],
  std_error = se(hr_es_model)[paste0("event_time_binned::", event_times)],
  pvalue = pvalue(hr_es_model)[paste0("event_time_binned::", event_times)]
) %>%
  mutate(
    ci_lower = coefficient - 1.96 * std_error,
    ci_upper = coefficient + 1.96 * std_error
  )

# Add reference period
hr_coefs <- bind_rows(
  hr_coefs,
  tibble(event_time = -1, coefficient = 0, std_error = 0, pvalue = NA, ci_lower = 0, ci_upper = 0)
) %>%
  arrange(event_time)

# Save hit-run coefficients
write.csv(hr_coefs, file.path(analysis, "output", "tables", "es_coefficients_hr.csv"),
          row.names = FALSE)

# Print hit-run results
cat("  Event study coefficients (Hit-Run):\n")
for (i in 1:nrow(hr_coefs)) {
  row <- hr_coefs[i, ]
  sig <- ifelse(!is.na(row$pvalue) && row$pvalue < 0.05, "*", "")
  cat(sprintf("    t=%+3d: %7.4f (%6.4f)%s\n",
              as.integer(row$event_time), row$coefficient, row$std_error, sig))
}

# Event study: Non-hit-and-run
cat("\n  Running event study: ln_nhr ~ event_time_dummies + FE\n")
if (length(controls) > 0) {
  nhr_es_formula <- as.formula(paste(
    "ln_nhr ~ i(event_time_binned, ref = -1) +",
    paste(controls, collapse = " + "),
    "| state_fips + year"
  ))
} else {
  nhr_es_formula <- ln_nhr ~ i(event_time_binned, ref = -1) | state_fips + year
}
nhr_es_model <- feols(nhr_es_formula, data = analysis_data, cluster = ~state_fips)

# Extract coefficients for non-hit-run
nhr_coefs <- tibble(
  event_time = event_times,
  coefficient = coef(nhr_es_model)[paste0("event_time_binned::", event_times)],
  std_error = se(nhr_es_model)[paste0("event_time_binned::", event_times)],
  pvalue = pvalue(nhr_es_model)[paste0("event_time_binned::", event_times)]
) %>%
  mutate(
    ci_lower = coefficient - 1.96 * std_error,
    ci_upper = coefficient + 1.96 * std_error
  )

# Add reference period
nhr_coefs <- bind_rows(
  nhr_coefs,
  tibble(event_time = -1, coefficient = 0, std_error = 0, pvalue = NA, ci_lower = 0, ci_upper = 0)
) %>%
  arrange(event_time)

# Save non-hit-run coefficients
write.csv(nhr_coefs, file.path(analysis, "output", "tables", "es_coefficients_nhr.csv"),
          row.names = FALSE)

# Store for figures script
ES_COEF_HR <- hr_coefs
ES_COEF_NHR <- nhr_coefs

cat("  Saved event study coefficients\n")
