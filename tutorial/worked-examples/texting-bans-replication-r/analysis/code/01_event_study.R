# 01_event_study.R -- TWFE and event study regressions
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(fixest)
})

# ── Load data ────────────────────────────────────────────────
analysis_data <- readRDS(file.path(BUILD, "output", "analysis_data.rds"))
analysis_data <- analysis_data |>
  mutate(ln_fatalities = log(fatalities))

# ── Simple TWFE ──────────────────────────────────────────────
twfe <- feols(
  ln_fatalities ~ treated + unemployment + income | state + year,
  data = analysis_data,
  cluster = ~state
)
cat(sprintf("    TWFE coefficient on treated: %.4f (SE: %.4f)\n",
            coef(twfe)["treatedTRUE"], se(twfe)["treatedTRUE"]))

# ── Event study ──────────────────────────────────────────────
analysis_data <- analysis_data |>
  mutate(
    event_time_binned = case_when(
      event_time == -1000 ~ -1000L,
      event_time <= -6    ~ -6L,
      event_time >= 6     ~  6L,
      TRUE                ~ as.integer(event_time)
    )
  )

es <- feols(
  ln_fatalities ~ i(event_time_binned, ever_treated, ref = c(-1, -1000)) +
    unemployment + income | state + year,
  data = analysis_data,
  cluster = ~state
)

cat("    Event study summary:\n")
print(summary(es))

# ── Export coefficients ──────────────────────────────────────
coef_tbl <- broom::tidy(es, conf.int = TRUE) |>
  filter(str_detect(term, "event_time")) |>
  mutate(event_time = as.numeric(str_extract(term, "-?\\d+"))) |>
  select(event_time, coefficient = estimate, std_error = std.error,
         ci_lower = conf.low, ci_upper = conf.high) |>
  arrange(event_time)

out_path <- file.path(ANALYSIS, "output", "event_study_coefs.csv")
write_csv(coef_tbl, out_path)
cat(sprintf("    Saved coefficients to %s\n", out_path))

# Print results
cat("\n    Event Study Coefficients:\n")
cat(sprintf("    %6s  %10s  %10s  %10s  %10s\n",
            "Time", "Coef", "SE", "CI Lower", "CI Upper"))
cat("    ", strrep("-", 52), "\n", sep = "")
for (i in seq_len(nrow(coef_tbl))) {
  r <- coef_tbl[i, ]
  cat(sprintf("    %6d  %10.4f  %10.4f  %10.4f  %10.4f\n",
              r$event_time, r$coefficient, r$std_error, r$ci_lower, r$ci_upper))
}
