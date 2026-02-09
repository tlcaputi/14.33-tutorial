# 02_clean_fars.R -- Aggregate FARS data to state-year level
# =============================================================================

suppressPackageStartupMessages(library(tidyverse))

fars_raw <- readRDS(file.path(BUILD, "output", "fars_raw.rds"))

state_year <- fars_raw |>
  group_by(state, statename, year) |>
  summarize(
    fatalities = sum(fatals),
    n_crashes  = n(),
    .groups = "drop"
  )

cat(sprintf("    %d states x %d years = %d rows\n",
            n_distinct(state_year$state),
            n_distinct(state_year$year),
            nrow(state_year)))
cat(sprintf("    Mean annual fatalities per state: %.0f\n",
            mean(state_year$fatalities)))

saveRDS(state_year, file.path(BUILD, "output", "state_year_fatalities.rds"))
