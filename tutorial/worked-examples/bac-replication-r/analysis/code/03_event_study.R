# 03_event_study.R - Event study specification

library(fixest)
library(dplyr)
library(tidyr)

# Load analysis data
analysis_data <- readRDS(file.path(build, "output", "analysis_data.rds"))

# Build formula with available controls
# Policy controls are always present (created in build script)
controls <- c("alr", "zero_tolerance", "primary_seatbelt", "secondary_seatbelt",
              "mlda21", "gdl", "speed_70", "aggravated_dui")
if ("unemployment" %in% names(analysis_data)) {
  controls <- c(controls, "unemployment")
}
if ("income" %in% names(analysis_data)) {
  controls <- c(controls, "income")
}

# Use fixest's bin argument to bin endpoint event times
# instead of manually creating event_time_binned with case_when
my_bin <- .("-5+" = ~x <= -5, "10+" = ~x >= 10)

# Event study: Hit-and-run
cat("  Running event study: ln_hr ~ event_time_dummies + FE\n")
if (length(controls) > 0) {
  hr_es_formula <- as.formula(paste(
    "ln_hr ~ i(event_time, ref = -1, bin = my_bin) +",
    paste(controls, collapse = " + "),
    "| state_fips + year"
  ))
} else {
  hr_es_formula <- ln_hr ~ i(event_time, ref = -1, bin = my_bin) | state_fips + year
}
hr_es_model <- feols(hr_es_formula, data = analysis_data, cluster = ~state_fips)

# Extract coefficients for hit-run using broom::tidy
hr_coefs <- broom::tidy(hr_es_model, conf.int = TRUE) %>%
  filter(grepl("event_time", term)) %>%
  mutate(
    event_time = as.numeric(stringr::str_extract(term, "-?\\d+")),
    pvalue = p.value
  ) %>%
  select(event_time, coefficient = estimate, std_error = std.error,
         pvalue, ci_lower = conf.low, ci_upper = conf.high) %>%
  arrange(event_time)

# Add reference period
hr_coefs <- bind_rows(
  hr_coefs,
  tibble(event_time = -1, coefficient = 0, std_error = 0, pvalue = NA,
         ci_lower = 0, ci_upper = 0)
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
    "ln_nhr ~ i(event_time, ref = -1, bin = my_bin) +",
    paste(controls, collapse = " + "),
    "| state_fips + year"
  ))
} else {
  nhr_es_formula <- ln_nhr ~ i(event_time, ref = -1, bin = my_bin) | state_fips + year
}
nhr_es_model <- feols(nhr_es_formula, data = analysis_data, cluster = ~state_fips)

# Extract coefficients for non-hit-run
nhr_coefs <- broom::tidy(nhr_es_model, conf.int = TRUE) %>%
  filter(grepl("event_time", term)) %>%
  mutate(
    event_time = as.numeric(stringr::str_extract(term, "-?\\d+")),
    pvalue = p.value
  ) %>%
  select(event_time, coefficient = estimate, std_error = std.error,
         pvalue, ci_lower = conf.low, ci_upper = conf.high) %>%
  arrange(event_time)

# Add reference period
nhr_coefs <- bind_rows(
  nhr_coefs,
  tibble(event_time = -1, coefficient = 0, std_error = 0, pvalue = NA,
         ci_lower = 0, ci_upper = 0)
) %>%
  arrange(event_time)

# Save non-hit-run coefficients
write.csv(nhr_coefs, file.path(analysis, "output", "tables", "es_coefficients_nhr.csv"),
          row.names = FALSE)

# Store for figures script
ES_COEF_HR <- hr_coefs
ES_COEF_NHR <- nhr_coefs

cat("  Saved event study coefficients\n")
