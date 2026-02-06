# 05_figures.R - Publication figures

library(ggplot2)
library(dplyr)
library(readr)

# Load event study coefficients
coef_hr <- read_csv(file.path(analysis, "output", "tables", "es_coefficients_hr.csv"),
                    show_col_types = FALSE)
coef_nhr <- read_csv(file.path(analysis, "output", "tables", "es_coefficients_nhr.csv"),
                     show_col_types = FALSE)

# Sort by event time
coef_hr <- coef_hr %>% arrange(event_time)
coef_nhr <- coef_nhr %>% arrange(event_time)

# =============================================================================
# Figure 1: Hit-and-Run Event Study
# =============================================================================
p_hr <- ggplot(coef_hr, aes(x = event_time, y = coefficient)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.3, fill = "steelblue") +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "steelblue", size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.7) +
  labs(
    title = "Event Study: Hit-and-Run Fatalities",
    x = "Years Since 0.08 BAC Law Adoption",
    y = "Coefficient (log HR fatalities)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave(file.path(analysis, "output", "figures", "event_study_hr.png"),
       plot = p_hr, width = 10, height = 6, dpi = 300)

# =============================================================================
# Figure 2: Non-Hit-and-Run Event Study (placebo)
# =============================================================================
p_nhr <- ggplot(coef_nhr, aes(x = event_time, y = coefficient)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.3, fill = "darkgreen") +
  geom_line(color = "darkgreen", linewidth = 1) +
  geom_point(color = "darkgreen", size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.7) +
  labs(
    title = "Event Study: Non-Hit-and-Run Fatalities (Placebo)",
    x = "Years Since 0.08 BAC Law Adoption",
    y = "Coefficient (log non-HR fatalities)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave(file.path(analysis, "output", "figures", "event_study_nhr.png"),
       plot = p_nhr, width = 10, height = 6, dpi = 300)

# =============================================================================
# Figure 3: Combined Event Study (both outcomes)
# =============================================================================
# Combine data
coef_hr$outcome <- "Hit-and-Run"
coef_nhr$outcome <- "Non-Hit-and-Run"
coef_combined <- bind_rows(coef_hr, coef_nhr)

p_combined <- ggplot(coef_combined, aes(x = event_time, y = coefficient, color = outcome, fill = outcome)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, color = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.7) +
  facet_wrap(~outcome, ncol = 2) +
  scale_color_manual(values = c("Hit-and-Run" = "steelblue", "Non-Hit-and-Run" = "darkgreen")) +
  scale_fill_manual(values = c("Hit-and-Run" = "steelblue", "Non-Hit-and-Run" = "darkgreen")) +
  labs(
    x = "Years Since Law Adoption",
    y = "Coefficient"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )

ggsave(file.path(analysis, "output", "figures", "event_study_combined.png"),
       plot = p_combined, width = 14, height = 5, dpi = 300)

cat("  Created figures:\n")
cat("    - event_study_hr.png\n")
cat("    - event_study_nhr.png\n")
cat("    - event_study_combined.png\n")
