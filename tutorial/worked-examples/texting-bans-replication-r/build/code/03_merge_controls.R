# 03_merge_controls.R -- Merge policy dates and economic controls
# =============================================================================

suppressPackageStartupMessages(library(tidyverse))

# ── Load data ────────────────────────────────────────────────
state_year <- readRDS(file.path(BUILD, "output", "state_year_fatalities.rds"))
policy <- read_csv(file.path(ROOT, "build", "input", "texting_ban_dates.csv"),
                   na = c("", "NA", "."), show_col_types = FALSE)

# ── Merge and create treatment variables ─────────────────────
analysis_data <- state_year |>
  left_join(policy, by = "state") |>
  mutate(
    ever_treated = !is.na(texting_ban_year),
    treated      = ever_treated & year >= texting_ban_year,
    event_time   = if_else(is.na(texting_ban_year), -1000L,
                           as.integer(year - texting_ban_year))
  )

cat(sprintf("    %d treated obs, %d never-treated obs\n",
            sum(analysis_data$ever_treated),
            sum(!analysis_data$ever_treated)))

# ── Download FRED controls ───────────────────────────────────
state_codes <- c(
  "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
  "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
  "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
  "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
  "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
)
state_fips_vals <- c(
   1,  2,  4,  5,  6,  8,  9, 10, 12, 13,
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
  25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
  35, 36, 37, 38, 39, 40, 41, 42, 44, 45,
  46, 47, 48, 49, 50, 51, 53, 54, 55, 56
)

download_fred_series <- function(suffix, value_name) {
  frames <- list()
  for (i in seq_along(state_codes)) {
    st   <- state_codes[i]
    fips <- state_fips_vals[i]
    series_id <- paste0(st, suffix)
    url <- paste0("https://fred.stlouisfed.org/graph/fredgraph.csv?id=", series_id)
    tryCatch({
      df <- read_csv(url, show_col_types = FALSE)
      names(df) <- c("date", value_name)
      df[[value_name]] <- as.numeric(df[[value_name]])
      df$year <- as.integer(substr(df$date, 1, 4))
      df <- df |>
        filter(year >= 2007, year <= 2022) |>
        group_by(year) |>
        summarise(!!value_name := mean(.data[[value_name]], na.rm = TRUE),
                  .groups = "drop") |>
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
analysis_data <- analysis_data |>
  left_join(all_unemp, by = c("state", "year")) |>
  left_join(all_income, by = c("state", "year"))

# Drop DC (FIPS 11)
analysis_data <- analysis_data |> filter(state != 11)

cat(sprintf("    Final dataset: %d rows\n", nrow(analysis_data)))

saveRDS(analysis_data, file.path(BUILD, "output", "analysis_data.rds"))
