# 01_download_fars.R - Download FARS data (1982-2008)
# This script downloads real FARS crash data from NHTSA
# Run time: ~10-15 minutes depending on internet speed

library(httr)
library(readr)
library(dplyr)

# Cache file - if exists, skip download
cache_file <- file.path(build, "output", "fars_raw.rds")

if (file.exists(cache_file)) {
  cat("  FARS data already downloaded, loading from cache...\n")
} else {
  cat("  Downloading FARS data from NHTSA (1982-2008)...\n")
  cat("  This will take ~10-15 minutes...\n")

  # Create input directory
  input_dir <- file.path(build, "input", "fars")
  dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)

  all_data <- list()

  for (year in 1982:2008) {
    cat(sprintf("    Processing %d...", year))

    # Try different URL formats (NHTSA has changed URLs over time)
    urls_to_try <- c(
      sprintf("https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/National/FARS%dNationalCSV.zip", year, year),
      sprintf("https://static.nhtsa.gov/nhtsa/downloads/FARS/%d/FARS%dNationalCSV.zip", year, year)
    )

    response <- NULL
    for (url in urls_to_try) {
      tryCatch({
        response <- GET(url, timeout(300))
        if (status_code(response) == 200) break
      }, error = function(e) NULL)
    }

    if (is.null(response) || status_code(response) != 200) {
      cat(" SKIPPED (couldn't download)\n")
      next
    }

    tryCatch({
      # Save and extract zip file
      zip_file <- file.path(input_dir, sprintf("FARS%d.zip", year))
      writeBin(content(response, "raw"), zip_file)

      extract_dir <- file.path(input_dir, sprintf("FARS%d", year))
      dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
      unzip(zip_file, exdir = extract_dir)

      # Find accident and vehicle files
      all_files <- list.files(extract_dir, recursive = TRUE, full.names = TRUE)
      csv_files <- all_files[grepl("\\.csv$", all_files, ignore.case = TRUE)]

      accident_file <- csv_files[grepl("accident|^acc", basename(csv_files), ignore.case = TRUE)][1]
      vehicle_file <- csv_files[grepl("vehicle", basename(csv_files), ignore.case = TRUE)][1]

      if (is.na(accident_file)) {
        cat(" no accident file\n")
        next
      }

      # Read accident file
      acc_df <- read_csv(accident_file, show_col_types = FALSE, locale = locale(encoding = "latin1"))
      names(acc_df) <- toupper(names(acc_df))

      # Get state FIPS
      if ("STATE" %in% names(acc_df)) {
        acc_df$state_fips <- sprintf("%02d", as.integer(acc_df$STATE))
      }

      # Get case number
      if ("ST_CASE" %in% names(acc_df)) {
        acc_df$st_case <- acc_df$ST_CASE
      } else {
        acc_df$st_case <- seq_len(nrow(acc_df))
      }

      # Get fatality count
      if ("FATALS" %in% names(acc_df)) {
        acc_df$fatalities <- acc_df$FATALS
      } else {
        acc_df$fatalities <- 1
      }

      acc_df$year <- year

      # Read vehicle file for hit-run indicator
      if (!is.na(vehicle_file)) {
        veh_df <- read_csv(vehicle_file, show_col_types = FALSE, locale = locale(encoding = "latin1"))
        names(veh_df) <- toupper(names(veh_df))

        if ("ST_CASE" %in% names(veh_df)) {
          veh_df$st_case <- veh_df$ST_CASE
        }

        # Find hit-run column (varies by year)
        hit_run_cols <- names(veh_df)[grepl("HIT.*RUN", names(veh_df))]

        if (length(hit_run_cols) > 0) {
          hit_run_col <- hit_run_cols[1]
          # FARS HIT_RUN codes: 1-4 are all "Yes" categories
          veh_df$hit_run <- as.integer(veh_df[[hit_run_col]] %in% c(1, 2, 3, 4, "1", "2", "3", "4"))

          # Aggregate to crash level (max hit_run across vehicles)
          hr_by_crash <- veh_df %>%
            group_by(st_case) %>%
            summarise(hit_run = max(hit_run, na.rm = TRUE), .groups = "drop")

          acc_df <- acc_df %>%
            merge(hr_by_crash, by = "st_case", all.x = TRUE) %>%
            mutate(hit_run = replace_na(hit_run, 0))
        } else {
          acc_df$hit_run <- 0
        }
      } else {
        acc_df$hit_run <- 0
      }

      # Keep only needed columns
      all_data[[as.character(year)]] <- acc_df %>%
        select(state_fips, year, fatalities, hit_run)

      n_hr <- sum(acc_df$hit_run)
      cat(sprintf(" %s crashes, %s hit-run\n",
                  format(nrow(acc_df), big.mark = ","),
                  format(n_hr, big.mark = ",")))

    }, error = function(e) {
      cat(sprintf(" ERROR: %s\n", e$message))
    })
  }

  # Combine all years
  if (length(all_data) > 0) {
    fars_df <- bind_rows(all_data)

    # Save raw data
    saveRDS(fars_df, cache_file)
    cat(sprintf("  Saved %s crash records to cache\n", format(nrow(fars_df), big.mark = ",")))
  } else {
    stop("Could not download any FARS data!")
  }
}

cat("  FARS download complete.\n")
