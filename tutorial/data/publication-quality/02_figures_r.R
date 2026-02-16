pacman::p_load(ggplot2, data.table)

set.seed(42)

# --- Generate fake event study data ---
periods <- -5:5
coefs <- c(-0.1, 0.05, -0.15, 0.08, 0.02, 0, 0.8, 1.5, 2.1, 2.4, 2.6)
ses <- c(0.35, 0.30, 0.28, 0.25, 0.20, 0, 0.22, 0.25, 0.30, 0.35, 0.40)

dt <- data.table(
  period = periods,
  estimate = coefs,
  se = ses
)
dt[, ci_lo := estimate - 1.96 * se]
dt[, ci_hi := estimate + 1.96 * se]


# ===== STEP 1: Default R plot (ugly) =====
png("fig_step1_default.png", width = 800, height = 600)
plot(dt$period, dt$estimate, type = "b",
     main = "Event Study",
     xlab = "period", ylab = "estimate")
abline(h = 0)
dev.off()


# ===== STEP 2: ggplot2 defaults =====
p2 <- ggplot(dt, aes(x = period, y = estimate)) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2) +
  geom_hline(yintercept = 0) +
  ggtitle("Event Study")
ggsave("fig_step2_ggplot_default.png", p2, width = 8, height = 6, dpi = 150)


# ===== STEP 3: Better theme, labels, vertical line =====
p3 <- ggplot(dt, aes(x = period, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "gray60", linetype = "dashed") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2, color = "steelblue") +
  geom_point(color = "steelblue", size = 3) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  labs(
    title = "Effect of Policy on Fatality Rate",
    x = "Years Relative to Policy Adoption",
    y = "Estimated Effect"
  ) +
  theme_minimal()
ggsave("fig_step3_themed.png", p3, width = 8, height = 6, dpi = 150)


# ===== STEP 4: Publication quality =====
p4 <- ggplot(dt, aes(x = period, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray70", linewidth = 0.4) +
  geom_vline(xintercept = -0.5, color = "gray70", linewidth = 0.4, linetype = "dashed") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#2c5f8a") +
  geom_line(color = "#2c5f8a", linewidth = 0.9) +
  geom_point(color = "#2c5f8a", size = 2.5) +
  annotate("text", x = -3, y = -0.7, label = "Pre-treatment", color = "gray50",
           size = 3.5, fontface = "italic") +
  annotate("text", x = 3, y = 3, label = "Post-treatment", color = "gray50",
           size = 3.5, fontface = "italic") +
  scale_x_continuous(breaks = -5:5) +
  labs(
    x = "Years Relative to Policy Adoption",
    y = "Estimated Effect on Fatality Rate"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3),
    axis.title.x = element_text(margin = margin(t = 10), size = 11),
    axis.title.y = element_text(margin = margin(r = 10), size = 11),
    axis.text = element_text(color = "gray30"),
    plot.margin = margin(20, 20, 20, 20)
  )
ggsave("fig_step4_publication.png", p4, width = 8, height = 5.5, dpi = 300)


cat("All R figures saved.\n")
