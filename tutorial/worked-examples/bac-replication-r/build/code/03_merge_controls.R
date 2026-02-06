# 03_merge_controls.R - Merge BAC dates, policy controls, and economic data

library(dplyr)
library(tidyr)
library(httr)
library(readr)

# =============================================================================
# BAC Adoption Dates (from APIS)
# =============================================================================
bac_dates <- c(
  "01" = 1995, "02" = 2001, "04" = 2001, "05" = 2001, "06" = 1990, "08" = 2004,
  "09" = 2002, "10" = 2004, "12" = 1994, "13" = 2001, "15" = 1995, "16" = 1997,
  "17" = 1997, "18" = 2001, "19" = 2003, "20" = 1993, "21" = 2000, "22" = 2003,
  "23" = 1988, "24" = 2001, "25" = 2003, "26" = 2003, "27" = 2005, "28" = 2002,
  "29" = 2001, "30" = 2003, "31" = 2001, "32" = 2003, "33" = 1994, "34" = 2004,
  "35" = 1994, "36" = 2003, "37" = 1993, "38" = 2003, "39" = 2003, "40" = 2001,
  "41" = 1983, "42" = 2003, "44" = 2000, "45" = 2003, "46" = 2002, "47" = 2003,
  "48" = 1999, "49" = 1983, "50" = 1991, "51" = 1994, "53" = 1999, "54" = 2004,
  "55" = 2003, "56" = 2002
)

# =============================================================================
# Policy Controls - Adoption dates (year, month)
# Sources: NHTSA, IIHS, APIS
# =============================================================================

# ALR (Administrative License Revocation) - list of (year, month)
alr_adoption <- list(
  "27" = c(1976, 1), "54" = c(1981, 1), "35" = c(1984, 1), "32" = c(1983, 7),
  "16" = c(1984, 7), "30" = c(1984, 10), "08" = c(1985, 7), "19" = c(1986, 1),
  "49" = c(1986, 7), "06" = c(1990, 1), "53" = c(1988, 1), "23" = c(1988, 1),
  "50" = c(1989, 7), "41" = c(1989, 1), "04" = c(1990, 1), "17" = c(1986, 1),
  "20" = c(1988, 7), "31" = c(1989, 1), "37" = c(1990, 10), "55" = c(1988, 1),
  "15" = c(1990, 1), "02" = c(1989, 1), "12" = c(1990, 1), "13" = c(1991, 7),
  "26" = c(1993, 10), "39" = c(1993, 7), "48" = c(1993, 9), "51" = c(1995, 7),
  "18" = c(1996, 7), "01" = c(1996, 7), "45" = c(1998, 7), "05" = c(1997, 8),
  "24" = c(1997, 10), "47" = c(1997, 7), "33" = c(1993, 1), "44" = c(1994, 7),
  "10" = c(1996, 1), "34" = c(1994, 1), "22" = c(1995, 8), "28" = c(1995, 7),
  "40" = c(1997, 11), "36" = c(1994, 11), "09" = c(1995, 10), "25" = c(1994, 1),
  "42" = c(1994, 7), "38" = c(1995, 8), "46" = c(1996, 7), "21" = c(1996, 7),
  "29" = c(1996, 7), "56" = c(1997, 7)
)

# Zero Tolerance (<0.02 BAC for under 21)
zero_tolerance <- list(
  "23" = c(1983, 1), "49" = c(1983, 1), "27" = c(1991, 8), "04" = c(1992, 1),
  "35" = c(1993, 7), "39" = c(1993, 7), "31" = c(1993, 1), "06" = c(1994, 1),
  "24" = c(1994, 10), "26" = c(1994, 10), "54" = c(1994, 6), "08" = c(1995, 7),
  "09" = c(1995, 10), "10" = c(1995, 1), "16" = c(1995, 7), "17" = c(1995, 1),
  "19" = c(1995, 5), "25" = c(1995, 1), "28" = c(1995, 7), "30" = c(1995, 10),
  "32" = c(1995, 10), "33" = c(1995, 1), "34" = c(1995, 1), "37" = c(1995, 12),
  "38" = c(1995, 8), "41" = c(1995, 10), "42" = c(1995, 2), "44" = c(1995, 7),
  "46" = c(1995, 7), "47" = c(1995, 7), "50" = c(1995, 7), "53" = c(1995, 1),
  "55" = c(1995, 1), "56" = c(1995, 7), "05" = c(1995, 7), "01" = c(1996, 10),
  "02" = c(1996, 9), "12" = c(1996, 1), "15" = c(1996, 6), "20" = c(1996, 7),
  "21" = c(1996, 7), "29" = c(1996, 1), "36" = c(1996, 11), "40" = c(1996, 9),
  "51" = c(1996, 7), "13" = c(1997, 7), "22" = c(1997, 8), "48" = c(1997, 9),
  "18" = c(1998, 7), "45" = c(1998, 7)
)

# Primary Seatbelt Law
primary_seatbelt <- list(
  "01" = c(1999, 12), "02" = c(2006, 5), "06" = c(1993, 1), "09" = c(1986, 1),
  "10" = c(2003, 6), "13" = c(1996, 7), "15" = c(1985, 12), "17" = c(2003, 7),
  "18" = c(1998, 7), "19" = c(1986, 7), "21" = c(2006, 7), "22" = c(1995, 9),
  "23" = c(2007, 9), "24" = c(1997, 10), "26" = c(2000, 4), "28" = c(2006, 5),
  "34" = c(2000, 5), "35" = c(1986, 1), "36" = c(1984, 12), "37" = c(2006, 12),
  "40" = c(1997, 11), "41" = c(1990, 12), "45" = c(2005, 12), "47" = c(2004, 7),
  "48" = c(1985, 9), "53" = c(2002, 7)
)

# Secondary Seatbelt Law (any seatbelt law)
secondary_seatbelt <- list(
  "01" = c(1991, 7), "02" = c(1990, 9), "04" = c(1991, 1), "05" = c(1991, 7),
  "06" = c(1986, 1), "08" = c(1987, 7), "10" = c(1992, 1), "12" = c(1986, 7),
  "13" = c(1988, 9), "16" = c(1986, 7), "17" = c(1988, 1), "18" = c(1987, 7),
  "20" = c(1986, 7), "21" = c(1994, 7), "22" = c(1986, 7), "23" = c(1995, 12),
  "24" = c(1986, 7), "25" = c(1994, 2), "26" = c(1985, 7), "27" = c(1986, 8),
  "28" = c(1994, 7), "29" = c(1985, 9), "30" = c(1987, 10), "31" = c(1993, 1),
  "32" = c(1987, 7), "34" = c(1985, 3), "37" = c(1985, 10), "38" = c(1994, 7),
  "39" = c(1986, 5), "40" = c(1987, 2), "42" = c(1987, 11), "44" = c(1991, 6),
  "45" = c(1989, 7), "46" = c(1995, 1), "47" = c(1986, 4), "49" = c(1986, 4),
  "50" = c(1994, 1), "51" = c(1988, 1), "53" = c(1986, 6), "54" = c(1993, 9),
  "55" = c(1987, 12), "56" = c(1989, 6)
)

# MLDA 21
mlda21 <- list(
  "26" = c(1978, 12), "17" = c(1980, 1), "24" = c(1982, 7), "34" = c(1983, 1),
  "40" = c(1983, 9), "02" = c(1984, 1), "05" = c(1984, 1), "10" = c(1984, 1),
  "06" = c(1984, 1), "18" = c(1984, 7), "25" = c(1984, 6), "32" = c(1984, 7),
  "35" = c(1984, 7), "41" = c(1984, 4), "42" = c(1984, 1), "44" = c(1984, 7),
  "47" = c(1984, 8), "53" = c(1984, 1), "01" = c(1985, 9), "04" = c(1985, 8),
  "09" = c(1985, 10), "12" = c(1985, 7), "13" = c(1985, 9), "20" = c(1985, 7),
  "23" = c(1985, 1), "29" = c(1985, 7), "31" = c(1985, 1), "33" = c(1985, 6),
  "36" = c(1985, 12), "49" = c(1985, 7), "51" = c(1985, 7), "15" = c(1986, 9),
  "19" = c(1986, 4), "21" = c(1986, 7), "27" = c(1986, 9), "28" = c(1986, 10),
  "37" = c(1986, 9), "45" = c(1986, 9), "48" = c(1986, 9), "50" = c(1986, 7),
  "54" = c(1986, 7), "55" = c(1986, 9), "08" = c(1987, 7), "16" = c(1987, 4),
  "22" = c(1987, 9), "30" = c(1987, 4), "39" = c(1987, 7), "46" = c(1988, 4),
  "56" = c(1988, 7)
)

# GDL (Graduated Driver Licensing)
gdl <- list(
  "12" = c(1996, 7), "26" = c(1997, 4), "37" = c(1997, 12), "13" = c(1997, 7),
  "06" = c(1998, 7), "22" = c(1998, 7), "45" = c(1998, 7), "25" = c(1998, 3),
  "08" = c(1999, 7), "10" = c(1999, 7), "18" = c(1999, 7), "24" = c(1999, 7),
  "39" = c(1999, 7), "48" = c(1999, 7), "51" = c(1999, 7), "17" = c(1999, 7),
  "04" = c(2000, 7), "20" = c(2000, 7), "35" = c(2000, 7), "36" = c(2000, 9),
  "41" = c(2000, 7), "55" = c(2000, 9), "28" = c(2000, 7), "15" = c(2000, 7),
  "16" = c(2000, 7), "19" = c(2000, 7), "21" = c(2000, 7), "23" = c(2000, 7),
  "27" = c(2000, 7), "30" = c(2000, 7), "05" = c(2001, 7), "29" = c(2001, 7),
  "34" = c(2001, 7), "47" = c(2001, 7), "53" = c(2001, 7), "01" = c(2002, 7),
  "31" = c(2000, 7), "32" = c(2001, 7), "33" = c(2001, 7), "38" = c(2001, 7),
  "40" = c(2001, 7), "42" = c(2001, 7), "44" = c(2001, 7), "46" = c(2001, 7),
  "49" = c(2001, 7), "50" = c(2001, 7), "54" = c(2001, 7), "56" = c(2001, 7),
  "02" = c(2001, 7), "09" = c(2001, 7)
)

# Speed Limit >= 70 mph
speed_70 <- list(
  "04" = c(1987, 12), "16" = c(1987, 5), "32" = c(1987, 12), "48" = c(1987, 12),
  "49" = c(1987, 1), "56" = c(1987, 1), "01" = c(1996, 3), "05" = c(1996, 5),
  "06" = c(1996, 1), "08" = c(1996, 5), "12" = c(1996, 3), "13" = c(1996, 7),
  "18" = c(1996, 7), "19" = c(1996, 4), "20" = c(1996, 4), "21" = c(1996, 6),
  "26" = c(1996, 2), "28" = c(1996, 5), "29" = c(1996, 5), "31" = c(1996, 4),
  "35" = c(1996, 5), "37" = c(1996, 8), "38" = c(1996, 8), "40" = c(1996, 5),
  "46" = c(1996, 4), "51" = c(1996, 7), "53" = c(1996, 6), "22" = c(1997, 6),
  "27" = c(1997, 6), "54" = c(1997, 6), "47" = c(1998, 1), "30" = c(1999, 5),
  "45" = c(1999, 6)
)

# Aggravated DUI
aggravated_dui <- list(
  "06" = c(1982, 1), "49" = c(1983, 1), "23" = c(1988, 1), "50" = c(1991, 1),
  "31" = c(1993, 1), "35" = c(1993, 7), "37" = c(1993, 12), "39" = c(1993, 7),
  "08" = c(1994, 7), "33" = c(1994, 7), "48" = c(1995, 9), "16" = c(1997, 7),
  "17" = c(1998, 1), "27" = c(1998, 8), "26" = c(1999, 10), "41" = c(1999, 10),
  "53" = c(1999, 7), "42" = c(2000, 2), "44" = c(2000, 7), "04" = c(2001, 9),
  "13" = c(2001, 7), "20" = c(2001, 7), "24" = c(2001, 10), "29" = c(2001, 7),
  "45" = c(2001, 6), "12" = c(2002, 1), "19" = c(2002, 7), "28" = c(2002, 7),
  "40" = c(2002, 7), "32" = c(2003, 10), "38" = c(2003, 8), "47" = c(2003, 7),
  "54" = c(2003, 7), "55" = c(2003, 12), "56" = c(2003, 7), "51" = c(2004, 7),
  "36" = c(2006, 11)
)

# Function to calculate fractional value based on adoption timing
frac_value <- function(year, adopt_info) {
  if (is.null(adopt_info)) return(0)
  adopt_year <- adopt_info[1]
  adopt_month <- adopt_info[2]

  if (year < adopt_year) {
    return(0)
  } else if (year == adopt_year) {
    return((13 - adopt_month) / 12)
  } else {
    return(1)
  }
}

# State unemployment FRED codes
state_unemp_codes <- c(
  "01" = "ALUR", "02" = "AKUR", "04" = "AZUR", "05" = "ARUR", "06" = "CAUR",
  "08" = "COUR", "09" = "CTUR", "10" = "DEUR", "12" = "FLUR", "13" = "GAUR",
  "15" = "HIUR", "16" = "IDUR", "17" = "ILUR", "18" = "INUR", "19" = "IAUR",
  "20" = "KSUR", "21" = "KYUR", "22" = "LAUR", "23" = "MEUR", "24" = "MDUR",
  "25" = "MAUR", "26" = "MIUR", "27" = "MNUR", "28" = "MSUR", "29" = "MOUR",
  "30" = "MTUR", "31" = "NEUR", "32" = "NVUR", "33" = "NHUR", "34" = "NJUR",
  "35" = "NMUR", "36" = "NYUR", "37" = "NCUR", "38" = "NDUR", "39" = "OHUR",
  "40" = "OKUR", "41" = "ORUR", "42" = "PAUR", "44" = "RIUR", "45" = "SCUR",
  "46" = "SDUR", "47" = "TNUR", "48" = "TXUR", "49" = "UTUR", "50" = "VTUR",
  "51" = "VAUR", "53" = "WAUR", "54" = "WVUR", "55" = "WIUR", "56" = "WYUR"
)

# Load crash data
cat("  Loading crash data...\n")
state_year <- readRDS(file.path(build, "output", "state_year_crashes.rds"))

# Add BAC adoption dates
cat("  Adding BAC adoption dates...\n")
state_year <- state_year %>%
  mutate(
    adoption_year = bac_dates[state_fips],
    event_time = year - adoption_year,
    treated = as.integer(event_time >= 0)
  )

# Add policy controls
cat("  Creating policy control variables...\n")

# Function to compute policy variable for a state-year
get_policy_values <- function(fips, yr) {
  tibble(
    state_fips = fips,
    year = yr,
    alr = frac_value(yr, alr_adoption[[fips]]),
    zero_tolerance = frac_value(yr, zero_tolerance[[fips]]),
    primary_seatbelt = frac_value(yr, primary_seatbelt[[fips]]),
    secondary_seatbelt_any = frac_value(yr, secondary_seatbelt[[fips]]),
    mlda21 = frac_value(yr, mlda21[[fips]]),
    gdl = frac_value(yr, gdl[[fips]]),
    speed_70 = frac_value(yr, speed_70[[fips]]),
    aggravated_dui = frac_value(yr, aggravated_dui[[fips]])
  )
}

# Create policy data for all state-years
policy_data <- map2_dfr(state_year$state_fips, state_year$year, get_policy_values)

# Calculate secondary seatbelt (any seatbelt minus primary)
policy_data <- policy_data %>%
  mutate(secondary_seatbelt = pmax(0, secondary_seatbelt_any - primary_seatbelt)) %>%
  select(-secondary_seatbelt_any)

# Merge policy data
state_year <- state_year %>%
  left_join(policy_data, by = c("state_fips", "year"))

# Download unemployment data from FRED
cat("  Downloading economic data from FRED...\n")
all_unemp <- list()
for (fips in names(state_unemp_codes)) {
  code <- state_unemp_codes[fips]
  tryCatch({
    url <- sprintf("https://fred.stlouisfed.org/graph/fredgraph.csv?id=%s", code)
    df <- read_csv(url, show_col_types = FALSE)
    names(df) <- c("date", "unemployment")
    df <- df %>%
      mutate(
        date = as.Date(date),
        year = as.integer(format(date, "%Y"))
      ) %>%
      filter(year >= 1982, year <= 2008) %>%
      group_by(year) %>%
      summarise(unemployment = mean(unemployment, na.rm = TRUE), .groups = "drop") %>%
      mutate(state_fips = fips)
    all_unemp[[fips]] <- df
  }, error = function(e) NULL)
}

if (length(all_unemp) > 0) {
  unemp_df <- bind_rows(all_unemp)
  state_year <- state_year %>%
    left_join(unemp_df, by = c("state_fips", "year"))
  cat(sprintf("    Added unemployment data for %d states\n", length(all_unemp)))
}

# Create log outcome variables
state_year <- state_year %>%
  mutate(
    ln_hr = log(hr_fatalities + 1),
    ln_nhr = log(nhr_fatalities + 1),
    ln_total = log(total_fatalities + 1)
  )

# Save final analysis dataset
saveRDS(state_year, file.path(build, "output", "analysis_data.rds"))
write_csv(state_year, file.path(build, "output", "analysis_data.csv"))

cat(sprintf("  Final dataset: %d observations\n", nrow(state_year)))
cat("  Saved to build/output/analysis_data.rds\n")
