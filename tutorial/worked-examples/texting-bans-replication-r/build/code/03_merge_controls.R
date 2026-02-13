# 03_merge_controls.R -- Merge policy dates and economic controls
# =============================================================================

suppressPackageStartupMessages(library(tidyverse))

# ── Load data ────────────────────────────────────────────────
state_year <- readRDS(file.path(BUILD, "output", "state_year_fatalities.rds"))
policy <- read_csv(file.path(ROOT, "texting_ban_dates.csv"),
                   na = c("", "NA", "."), show_col_types = FALSE)

# ── Merge and create treatment variables ─────────────────────
analysis_data <- state_year %>%
  merge(policy, by = "state", all.x = TRUE) %>%
  mutate(
    ever_treated = !is.na(texting_ban_year),
    treated      = ever_treated & year >= texting_ban_year,
    event_time   = if_else(is.na(texting_ban_year), -1000L,
                           as.integer(year - texting_ban_year))
  )

cat(sprintf("    %d treated obs, %d never-treated obs\n",
            sum(analysis_data$ever_treated),
            sum(!analysis_data$ever_treated)))

# ── Load state FIPS mapping ────────────────────────────────────
# Maps numeric FIPS codes (used by FARS) to state abbreviations (used by FRED)
state_fips_map <- read_csv(file.path(ROOT, "state_fips_map.csv"), show_col_types = FALSE)

download_fred_series <- function(suffix, value_name) {
  frames <- list()
  for (i in seq_len(nrow(state_fips_map))) {
    st   <- state_fips_map$state_abbr[i]
    fips <- state_fips_map$state[i]
    series_id <- paste0(st, suffix)
    url <- paste0("https://fred.stlouisfed.org/graph/fredgraph.csv?id=", series_id)
    tryCatch({
      df <- read_csv(url, show_col_types = FALSE)
      names(df) <- c("date", value_name)
      df[[value_name]] <- as.numeric(df[[value_name]])
      df$year <- as.integer(substr(df$date, 1, 4))
      df <- df %>%
        filter(year >= 2007, year <= 2022) %>%
        group_by(year) %>%
        summarise(!!value_name := mean(.data[[value_name]], na.rm = TRUE),
                  .groups = "drop") %>%
        mutate(state = fips)
      frames[[length(frames) + 1]] <- df
    }, error = function(e) NULL)
    Sys.sleep(0.3)
  }
  bind_rows(frames)
}

cat("    Downloading unemployment from FRED...\n")
all_unemp <- download_fred_series("UR", "unemployment")
cat(sprintf("    Got unemployment for %d states\n", n_distinct(all_unemp$state)))

cat("    Downloading per-capita income from FRED...\n")
all_income <- download_fred_series("PCPI", "income")
cat(sprintf("    Got income for %d states\n", n_distinct(all_income$state)))

# ── Merge controls ───────────────────────────────────────────
analysis_data <- analysis_data %>%
  merge(all_unemp, by = c("state", "year"), all.x = TRUE) %>%
  merge(all_income, by = c("state", "year"), all.x = TRUE)

# Drop DC (FIPS 11)
analysis_data <- analysis_data %>% filter(state != 11)

cat(sprintf("    Final dataset: %d rows\n", nrow(analysis_data)))

saveRDS(analysis_data, file.path(BUILD, "output", "analysis_data.rds"))
