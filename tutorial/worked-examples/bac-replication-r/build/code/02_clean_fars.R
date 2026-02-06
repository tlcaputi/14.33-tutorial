# 02_clean_fars.R - Clean and aggregate FARS data to state-year level

library(dplyr)
library(tidyr)

# State FIPS to name mapping
state_names <- c(
  "01" = "Alabama", "02" = "Alaska", "04" = "Arizona", "05" = "Arkansas",
  "06" = "California", "08" = "Colorado", "09" = "Connecticut", "10" = "Delaware",
  "12" = "Florida", "13" = "Georgia", "15" = "Hawaii", "16" = "Idaho",
  "17" = "Illinois", "18" = "Indiana", "19" = "Iowa", "20" = "Kansas",
  "21" = "Kentucky", "22" = "Louisiana", "23" = "Maine", "24" = "Maryland",
  "25" = "Massachusetts", "26" = "Michigan", "27" = "Minnesota", "28" = "Mississippi",
  "29" = "Missouri", "30" = "Montana", "31" = "Nebraska", "32" = "Nevada",
  "33" = "New Hampshire", "34" = "New Jersey", "35" = "New Mexico", "36" = "New York",
  "37" = "North Carolina", "38" = "North Dakota", "39" = "Ohio", "40" = "Oklahoma",
  "41" = "Oregon", "42" = "Pennsylvania", "44" = "Rhode Island", "45" = "South Carolina",
  "46" = "South Dakota", "47" = "Tennessee", "48" = "Texas", "49" = "Utah",
  "50" = "Vermont", "51" = "Virginia", "53" = "Washington", "54" = "West Virginia",
  "55" = "Wisconsin", "56" = "Wyoming"
)

cat("  Loading raw FARS data...\n")
fars_df <- readRDS(file.path(build, "output", "fars_raw.rds"))
fars_df$state_fips <- sprintf("%02d", as.integer(fars_df$state_fips))

cat("  Aggregating to state-year level...\n")

# Aggregate: count fatalities and hit-run fatalities by state-year
state_year <- fars_df %>%
  group_by(state_fips, year) %>%
  summarise(
    total_fatalities = sum(fatalities, na.rm = TRUE),
    hr_fatalities = sum(fatalities * hit_run, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(nhr_fatalities = total_fatalities - hr_fatalities)

# Keep only 50 states (exclude DC, territories)
state_year <- state_year %>%
  filter(state_fips %in% names(state_names)) %>%
  mutate(state_name = state_names[state_fips])

# Create complete panel (ensure all state-years are present)
all_states <- names(state_names)
all_years <- 1982:2008

complete_panel <- expand.grid(state_fips = all_states, year = all_years, stringsAsFactors = FALSE) %>%
  mutate(state_name = state_names[state_fips])

# Merge and fill zeros for missing state-years
state_year <- complete_panel %>%
  left_join(state_year %>% select(-state_name), by = c("state_fips", "year")) %>%
  mutate(
    total_fatalities = replace_na(total_fatalities, 0),
    hr_fatalities = replace_na(hr_fatalities, 0),
    nhr_fatalities = replace_na(nhr_fatalities, 0)
  )

# Sort
state_year <- state_year %>%
  arrange(state_fips, year)

# Save
saveRDS(state_year, file.path(build, "output", "state_year_crashes.rds"))

cat(sprintf("  Created state-year panel: %d observations\n", nrow(state_year)))
cat(sprintf("  Total fatalities: %s\n", format(sum(state_year$total_fatalities), big.mark = ",")))
cat(sprintf("  HR fatalities: %s (%.1f%%)\n",
            format(sum(state_year$hr_fatalities), big.mark = ","),
            100 * sum(state_year$hr_fatalities) / sum(state_year$total_fatalities)))
