# 03_event_study.R
# Event study analysis

cat("Running 03_event_study.R...\n")

# Load packages
pacman::p_load(data.table, fixest, ggplot2)

# Read analysis panel
dt <- fread(file.path(root, "build/output/analysis_panel.csv"))

# Create event time variable
dt[, event_time := fifelse(
  is.na(adoption_year),
  -1000,  # Never-treated cohort
  year - adoption_year
)]

# Event study regression using i() syntax
event_study <- feols(
  fatal_crashes ~ i(event_time, ref = c(-1, -1000)) + log_pop | state_fips + year,
  data = dt,
  cluster = ~state_fips
)

# Print results
cat("\n")
cat("Event Study Results:\n")
print(summary(event_study))

# Extract coefficients for plotting
all_names <- names(coef(event_study))
et_idx <- grepl("^event_time::", all_names)
coef_data <- data.table(
  event_time = as.integer(gsub("event_time::", "", all_names[et_idx])),
  coef = coef(event_study)[et_idx],
  se = se(event_study)[et_idx]
)
# Add reference period
coef_data <- rbind(coef_data, data.table(event_time = -1L, coef = 0, se = 0))
coef_data <- coef_data[order(event_time)]
coef_data[, ci_lower := coef - 1.96 * se]
coef_data[, ci_upper := coef + 1.96 * se]

# Create event study plot with ggplot2
event_plot <- ggplot(coef_data, aes(x = event_time, y = coef)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "steelblue") +
  geom_point(color = "steelblue", size = 2.5) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", linewidth = 0.5) +
  labs(
    title = "Event Study: Effect of Policy on Fatal Crashes",
    x = "Years Relative to Policy Adoption",
    y = "Effect on Fatal Crashes",
    caption = "Reference period: t = -1 | 95% confidence intervals"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10)
  )

# Save plot
dir.create(file.path(root, "analysis/output"), showWarnings = FALSE, recursive = TRUE)
ggsave(
  file.path(root, "analysis/output/event_study_plot.png"),
  plot = event_plot,
  width = 10,
  height = 6,
  dpi = 300
)

cat("\n  Saved event_study_plot.png\n")
