#!/usr/bin/env Rscript
# =============================================================================
# Replication Package: Texting Bans and Traffic Fatalities
# =============================================================================
# Event study analysis of state texting-while-driving bans
# using FARS data (2007-2022).
#
# Requirements:
#   install.packages(c("tidyverse", "fixest", "arrow"))
#
# Usage:
#   Rscript master.R
# =============================================================================

cat("============================================================\n")
cat("Texting Bans and Traffic Fatalities -- Replication Package\n")
cat("============================================================\n")

ROOT <- dirname(normalizePath(sys.frame(1)$ofile %||% "master.R"))
if (ROOT == ".") ROOT <- getwd()

BUILD    <- file.path(ROOT, "build")
ANALYSIS <- file.path(ROOT, "analysis")

# Create output directories
dir.create(file.path(BUILD, "output"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(ANALYSIS, "output"), recursive = TRUE, showWarnings = FALSE)

# ── Phase 1: Build data ─────────────────────────────────────
build_scripts <- c(
  "01_download_fars.R",
  "02_clean_fars.R",
  "03_merge_controls.R"
)

cat("\n-- Phase 1: Building data --\n")
for (i in seq_along(build_scripts)) {
  script <- build_scripts[i]
  cat(sprintf("\n  [%d/%d] Running %s...\n", i, length(build_scripts), script))
  t0 <- proc.time()["elapsed"]
  source(file.path(BUILD, "code", script), local = FALSE)
  cat(sprintf("  Done (%.1fs)\n", proc.time()["elapsed"] - t0))
}

# ── Phase 2: Analysis ───────────────────────────────────────
analysis_scripts <- c(
  "01_event_study.R",
  "02_figures.R"
)

cat("\n-- Phase 2: Running analysis --\n")
for (i in seq_along(analysis_scripts)) {
  script <- analysis_scripts[i]
  cat(sprintf("\n  [%d/%d] Running %s...\n", i, length(analysis_scripts), script))
  t0 <- proc.time()["elapsed"]
  source(file.path(ANALYSIS, "code", script), local = FALSE)
  cat(sprintf("  Done (%.1fs)\n", proc.time()["elapsed"] - t0))
}

# ── Summary ──────────────────────────────────────────────────
cat("\n============================================================\n")
cat("Complete! Output files:\n")
cat(sprintf("  %s\n", file.path(ANALYSIS, "output", "event_study_coefs.csv")))
cat(sprintf("  %s\n", file.path(ANALYSIS, "output", "event_study.png")))
cat("============================================================\n")
