# Master script — sets root and sources all scripts in order
#
# Usage: cd into the pkg-r/ folder, then run:
#   Rscript master.R
# Or open master.R in RStudio and click "Source".
rm(list = ls())

root <- tryCatch({
  dirname(rstudioapi::getActiveDocumentContext()$path)
}, error = function(e) {
  getwd()
})

build    <- file.path(root, "build")
analysis <- file.path(root, "analysis")

if (!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, haven, fixest, ggplot2, rdrobust, modelsummary)

# Create output directories (zip may strip empty folders)
dir.create(file.path(build, "output"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(analysis, "output", "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(analysis, "output", "figures"), showWarnings = FALSE, recursive = TRUE)

# Build
source(file.path(build, "code", "01_filter_crashes.R"))
source(file.path(build, "code", "02_collapse_crashes.R"))
source(file.path(build, "code", "03_reshape_crashes.R"))
source(file.path(build, "code", "04_append_demographics.R"))
source(file.path(build, "code", "05_collapse_demographics.R"))
source(file.path(build, "code", "06_merge_datasets.R"))

# Analysis
source(file.path(analysis, "code", "01_descriptive_table.R"))
source(file.path(analysis, "code", "02_dd_regression.R"))
source(file.path(analysis, "code", "03_event_study.R"))
source(file.path(analysis, "code", "04_dd_table.R"))
source(file.path(analysis, "code", "05_iv.R"))
source(file.path(analysis, "code", "06_rd.R"))

# Compile LaTeX tables to PDF
tables_dir <- file.path(analysis, "output", "tables")
tex_files  <- list.files(tables_dir, pattern = "\\.tex$", full.names = TRUE)

if (length(tex_files) > 0 && nzchar(Sys.which("pdflatex"))) {
  cat("\nCompiling LaTeX tables to PDF...\n")
  owd <- setwd(tables_dir)
  for (tf in tex_files) {
    base    <- tools::file_path_sans_ext(basename(tf))
    wrapper <- paste0(base, "_compile.tex")

    # Check if the .tex uses tabularray (modelsummary) or plain tabular (fixest)
    tex_content <- readLines(tf, warn = FALSE)
    uses_tabularray <- any(grepl("tabularray|talltblr", tex_content))

    if (uses_tabularray) {
      preamble <- c(
        "\\documentclass[border=10pt]{standalone}",
        "\\usepackage{booktabs,amsmath,tabularray,graphicx,codehigh}",
        "\\usepackage[normalem]{ulem}",
        "\\UseTblrLibrary{booktabs}",
        "\\UseTblrLibrary{siunitx}",
        "\\newcommand{\\tinytableTabularrayUnderline}[1]{\\underline{#1}}",
        "\\newcommand{\\tinytableTabularrayStrikeout}[1]{\\sout{#1}}",
        "\\NewTableCommand{\\tinytableDefineColor}[3]{\\definecolor{#1}{#2}{#3}}"
      )
    } else {
      preamble <- c(
        "\\documentclass[border=10pt]{standalone}",
        "\\usepackage{booktabs,amsmath,threeparttable,makecell}"
      )
    }
    writeLines(c(preamble, "\\begin{document}",
                 paste0("\\input{", basename(tf), "}"),
                 "\\end{document}"), wrapper)

    system(paste("pdflatex -interaction=nonstopmode", shQuote(wrapper),
                 "> /dev/null 2>&1"))

    pdf_out <- paste0(base, "_compile.pdf")
    target  <- paste0(base, ".pdf")
    if (file.exists(pdf_out)) {
      file.rename(pdf_out, target)
      cat("  Compiled:", target, "\n")
    } else {
      cat("  WARNING: Failed to compile", basename(tf), "\n")
    }
    # Clean up
    for (ext in c("_compile.tex", "_compile.aux", "_compile.log")) {
      f <- paste0(base, ext)
      if (file.exists(f)) file.remove(f)
    }
  }
  setwd(owd)
} else if (length(tex_files) == 0) {
  cat("\nNo .tex files found — skipping PDF compilation.\n")
} else {
  cat("\npdflatex not found — skipping PDF compilation.\n")
  cat("Install LaTeX to compile tables: https://www.tug.org/texlive/\n")
}

cat("All scripts completed successfully!\n")
