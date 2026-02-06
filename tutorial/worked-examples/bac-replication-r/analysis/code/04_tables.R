# 04_tables.R - Publication tables

library(dplyr)
library(readr)

# Load results from previous scripts
twfe_results <- read_csv(file.path(analysis, "output", "tables", "twfe_results.csv"),
                         show_col_types = FALSE)
es_hr <- read_csv(file.path(analysis, "output", "tables", "es_coefficients_hr.csv"),
                  show_col_types = FALSE)
es_nhr <- read_csv(file.path(analysis, "output", "tables", "es_coefficients_nhr.csv"),
                   show_col_types = FALSE)

# Helper function to format coefficient with significance stars
format_coef <- function(coef, se) {
  z <- abs(coef / se)
  stars <- ""
  if (!is.na(z)) {
    if (z > 2.576) stars <- "***"
    else if (z > 1.96) stars <- "**"
    else if (z > 1.645) stars <- "*"
  }
  list(coef = sprintf("%.4f%s", coef, stars), se = sprintf("(%.4f)", se))
}

# Create LaTeX table for TWFE results
hr_row <- twfe_results %>% filter(outcome == "Hit-Run")
nhr_row <- twfe_results %>% filter(outcome == "Non-Hit-Run")

hr_fmt <- format_coef(hr_row$coefficient, hr_row$std_error)
nhr_fmt <- format_coef(nhr_row$coefficient, nhr_row$std_error)

latex_table <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of 0.08 BAC Laws on Traffic Fatalities}\n",
  "\\label{tab:main_results}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Hit-Run & Non-Hit-Run \\\\\n",
  " & (1) & (2) \\\\\n",
  "\\midrule\n",
  sprintf("Treated & %s & %s \\\\\n", hr_fmt$coef, nhr_fmt$coef),
  sprintf(" & %s & %s \\\\\n", hr_fmt$se, nhr_fmt$se),
  "\\addlinespace\n",
  "\\midrule\n",
  "State FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s \\\\\n",
          format(hr_row$n_obs, big.mark = ","),
          format(nhr_row$n_obs, big.mark = ",")),
  sprintf("R-squared & %.3f & %.3f \\\\\n", hr_row$r2, nhr_row$r2),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered by state in parentheses. * p<0.10, ** p<0.05, *** p<0.01.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

# Save LaTeX table
writeLines(latex_table, file.path(analysis, "output", "tables", "table2_regression.tex"))

# Create event study table
es_table <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study Coefficients}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Event Time & Hit-Run & Non-Hit-Run \\\\\n",
  "\\midrule\n"
)

for (et in sort(unique(es_hr$event_time))) {
  hr_row <- es_hr %>% filter(event_time == et)
  nhr_row <- es_nhr %>% filter(event_time == et)

  hr_fmt <- format_coef(hr_row$coefficient, hr_row$std_error)
  nhr_fmt <- format_coef(nhr_row$coefficient, nhr_row$std_error)

  es_table <- paste0(es_table,
                     sprintf("$t = %+d$ & %s & %s \\\\\n",
                             as.integer(et), hr_fmt$coef, nhr_fmt$coef))
}

es_table <- paste0(es_table,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item \\textit{Notes:} Reference period is $t=-1$. * p<0.10, ** p<0.05, *** p<0.01.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(es_table, file.path(analysis, "output", "tables", "table3_event_study.tex"))

cat("  Created LaTeX tables:\n")
cat("    - table2_regression.tex\n")
cat("    - table3_event_study.tex\n")
