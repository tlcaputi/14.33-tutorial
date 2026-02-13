# 01_download_fars.R -- Download FARS accident data (2007-2022)
# =============================================================================
# Downloads ZIP files from NHTSA, extracts accident.csv for each year,
# keeps relevant columns, and saves a combined RDS file.
# Skips download if cached file already exists.
# =============================================================================

suppressPackageStartupMessages(library(tidyverse))
# Note: we use %>% (magrittr pipe) throughout for clarity

FARS_YEARS <- 2007:2022
CACHE_FILE <- file.path(BUILD, "output", "fars_raw.rds")
RAW_DIR    <- file.path(BUILD, "output", "fars_csvs")

if (file.exists(CACHE_FILE)) {
  cat("    Cached fars_raw.rds found -- skipping download.\n")
  fars_raw <- readRDS(CACHE_FILE)
} else {
  dir.create(RAW_DIR, recursive = TRUE, showWarnings = FALSE)
  frames <- list()

  for (year in FARS_YEARS) {
    csv_path <- file.path(RAW_DIR, paste0("accident_", year, ".csv"))

    if (file.exists(csv_path)) {
      cat(sprintf("    %d: using cached CSV\n", year))
    } else {
      url <- sprintf(
        "https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/National/FARS%dNationalCSV.zip",
        year, year
      )
      cat(sprintf("    %d: downloading...", year))
      zip_file <- tempfile(fileext = ".zip")
      download.file(url, zip_file, mode = "wb", quiet = TRUE)

      # Extract accident.csv
      temp_dir <- tempdir()
      unzip(zip_file, exdir = temp_dir)
      accident_file <- list.files(temp_dir, pattern = "accident\\.csv$",
                                   recursive = TRUE, full.names = TRUE,
                                   ignore.case = TRUE)[1]
      file.copy(accident_file, csv_path, overwrite = TRUE)

      # Clean up
      unlink(zip_file)
      unlink(list.files(temp_dir, full.names = TRUE, recursive = TRUE,
                         pattern = "\\.(csv|CSV)$"))
      cat(" OK\n")
    }

    df <- read_csv(csv_path, show_col_types = FALSE) %>%
      select(STATE, STATENAME, YEAR, MONTH, FATALS) %>%
      rename_all(tolower)
    frames[[as.character(year)]] <- df
  }

  fars_raw <- bind_rows(frames)
  saveRDS(fars_raw, CACHE_FILE)
  cat(sprintf("    Saved %s rows to fars_raw.rds\n", format(nrow(fars_raw), big.mark = ",")))
}
