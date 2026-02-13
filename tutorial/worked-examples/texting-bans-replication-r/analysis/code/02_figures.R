# 02_figures.R -- Event study plot
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

# ── Load coefficients ────────────────────────────────────────
coef_df <- read_csv(file.path(ANALYSIS, "output", "event_study_coefs.csv"),
                    show_col_types = FALSE)

# Add reference period (t = -1)
coef_df <- coef_df %>%
  bind_rows(tibble(event_time = -1, coefficient = 0,
                   std_error = 0, ci_lower = 0, ci_upper = 0)) %>%
  arrange(event_time)

# ── Create plot ──────────────────────────────────────────────
p <- ggplot(coef_df, aes(x = event_time, y = coefficient)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red", alpha = 0.7) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray", alpha = 0.5) +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = "navy", size = 0.5, shape = 18) +
  scale_x_continuous(breaks = -6:6) +
  labs(
    x = "Years Relative to Texting Ban",
    y = "Effect on Log Fatalities",
    title = "Event Study: Texting Bans and Traffic Fatalities",
    caption = "Coefficients relative to t = \u22121. 95% CIs shown. Clustered SEs at state level."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(hjust = 0.5, size = 14),
    plot.caption = element_text(color = "gray50", size = 9)
  )

out_path <- file.path(ANALYSIS, "output", "event_study.png")
ggsave(out_path, p, width = 10, height = 6, dpi = 300)
cat(sprintf("    Saved plot to %s\n", out_path))
