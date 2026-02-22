# 01_descriptive_table.R
# Descriptive statistics table
#
# Splits the sample into three groups:
#   Untreated      — states that never adopted the policy
#   Treated Before — treated states in pre-adoption years
#   Treated After  — treated states in post-adoption years (post_treated == 1)
#
# Outputs:
#   analysis/output/tables/descriptive_table.csv  (raw numbers)
#   analysis/output/tables/descriptive_table.tex  (publication-ready LaTeX)

cat("Running 01_descriptive_table.R...\n")

# ------------------------------------------------------------------
# Setup — master.R sets these; edit below if running standalone
if (!exists("root")) {
  root     <- "."
  build    <- file.path(root, "build")
  analysis <- file.path(root, "analysis")
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load(data.table, fixest, ggplot2)
}
# ------------------------------------------------------------------

# Load modelsummary for the LaTeX table
if (!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, modelsummary)

# ---- Read data -------------------------------------------------------
dt <- fread(file.path(root, "build/output/analysis_panel.csv"))

# ---- Create post_treated ---------------------------------------------
# post_treated = 1 in treated states on or after their adoption year.
# This equals the existing `treated` column; we rename for clarity.
dt[, post_treated := treated]

# ---- Assign comparison groups ----------------------------------------
# ever_treated = 1 for states that eventually adopt, regardless of year
dt[, ever_treated := as.integer(!is.na(adoption_year))]

dt[, group := fcase(
  ever_treated == 0,                "Untreated",
  post_treated == 1,                "Treated After",
  ever_treated == 1 & post_treated == 0, "Treated Before"
)]

# ---- Variables to summarise ------------------------------------------
vars <- c("fatal_crashes", "serious_crashes", "total_crashes",
          "fatal_share", "population", "median_income", "pct_urban")

# ---- Helper: Mean, SD, N for a numeric vector ------------------------
calc_stats <- function(x) {
  c(
    Mean = mean(x, na.rm = TRUE),
    SD   = sd(x,   na.rm = TRUE),
    N    = sum(!is.na(x))
  )
}

# ---- Compute stats for each group ------------------------------------
desc_table <- rbindlist(lapply(vars, function(v) {
  s_all  <- calc_stats(dt[[v]])
  s_post <- calc_stats(dt[group == "Treated After",  ][[v]])
  s_pre  <- calc_stats(dt[group == "Treated Before", ][[v]])
  s_untr <- calc_stats(dt[group == "Untreated",      ][[v]])

  data.table(
    Variable          = v,
    All_Mean          = s_all["Mean"],
    All_SD            = s_all["SD"],
    TreatedAfter_Mean = s_post["Mean"],
    TreatedAfter_SD   = s_post["SD"],
    TreatedBefore_Mean = s_pre["Mean"],
    TreatedBefore_SD  = s_pre["SD"],
    Untreated_Mean    = s_untr["Mean"],
    Untreated_SD      = s_untr["SD"]
  )
}))

# ---- Save outputs ----------------------------------------------------
dir.create(file.path(root, "analysis/output/tables"),
           showWarnings = FALSE, recursive = TRUE)

# CSV — full numeric detail
fwrite(desc_table,
       file.path(root, "analysis/output/tables/descriptive_table.csv"))

# LaTeX — publication-ready via datasummary
# Build a tidy long-form version that datasummary can handle
dt_long <- melt(
  dt[, c("group", vars), with = FALSE],
  id.vars      = "group",
  variable.name = "variable",
  value.name    = "value"
)

# datasummary requires a formula; we use datasummary_balance-style output
# but datasummary gives us more column control here.
pretty_labels <- c(
  fatal_crashes   = "Fatal crashes",
  serious_crashes = "Serious crashes",
  total_crashes   = "Total crashes",
  fatal_share     = "Fatal share",
  population      = "Population",
  median_income   = "Median income",
  pct_urban       = "Pct. urban"
)
dt_long[, variable := factor(variable, levels = vars,
                              labels = pretty_labels[vars])]

# Use datasummary to produce the LaTeX table
datasummary(
  variable * (Mean + SD) ~ group,
  data  = dt_long,
  title = "Descriptive Statistics by Treatment Group",
  notes = "Unit of observation is a state--year. \\textit{Treated Before} and \\textit{Treated After} refer to pre- and post-adoption periods for eventually-treated states.",
  output = file.path(root, "analysis/output/tables/descriptive_table.tex")
)

# ---- Console summary -------------------------------------------------
cat("\nDescriptive Statistics\n")
cat("======================\n")
print(desc_table, digits = 3)
cat("\n  Saved descriptive_table.csv and descriptive_table.tex\n")
