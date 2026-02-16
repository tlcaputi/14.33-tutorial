# 05_rd.R
# Regression discontinuity analysis: MLDA and mortality
# Inspired by Carpenter & Dobkin (2009)

cat("Running 05_rd.R...\n")

# Load packages
pacman::p_load(data.table, fixest, ggplot2, rdrobust)

# Read RD data
dt <- fread(file.path(root, "analysis/code/rd_data.csv"))

cat("\nDataset:", nrow(dt), "observations\n")
cat("Variables:", paste(names(dt), collapse = ", "), "\n")

# Running variable is days_from_21 (already centered at 0)
# Treatment: over_21
# Outcome: mortality_rate

# Linear RD within bandwidth
bandwidth <- 365  # 1 year
dt_bw <- dt[abs(days_from_21) <= bandwidth]

cat("\nUsing bandwidth: +/-", bandwidth, "days\n")
cat("Observations in bandwidth:", nrow(dt_bw), "\n")

# Create interaction
dt_bw[, days_x_over21 := days_from_21 * over_21]

rd_linear <- feols(
  mortality_rate ~ over_21 + days_from_21 + days_x_over21,
  data = dt_bw,
  vcov = "hetero"
)

# Polynomial RD (quadratic)
dt_bw[, days_sq := days_from_21^2]
dt_bw[, days_sq_x_over21 := days_sq * over_21]

rd_poly <- feols(
  mortality_rate ~ over_21 + days_from_21 + days_x_over21 +
    days_sq + days_sq_x_over21,
  data = dt_bw,
  vcov = "hetero"
)

# Print results
cat("\nLinear RD Results (bandwidth =", bandwidth, "days):\n")
print(summary(rd_linear))

cat("\nPolynomial RD Results (quadratic):\n")
print(summary(rd_poly))

# rdrobust (if available)
if (requireNamespace("rdrobust", quietly = TRUE)) {
  rd_robust <- rdrobust(
    y = dt$mortality_rate,
    x = dt$days_from_21,
    c = 0
  )

  cat("\nrdrobust Results:\n")
  print(summary(rd_robust))
}

# Create RD plot
# Bin the data
dt_plot <- copy(dt[abs(days_from_21) <= 730])  # 2 years
dt_plot[, bin := floor(days_from_21 / 30) * 30 + 15]

rd_plot_data <- dt_plot[, .(
  mean_mortality = mean(mortality_rate, na.rm = TRUE),
  se_mortality = sd(mortality_rate, na.rm = TRUE) / sqrt(.N)
), by = .(bin)]

rd_plot <- ggplot(rd_plot_data, aes(x = bin, y = mean_mortality)) +
  geom_point(aes(color = bin >= 0), size = 2.5, alpha = 0.7) +
  geom_smooth(data = rd_plot_data[bin < 0], method = "lm", se = TRUE,
              color = "#2C3E50", fill = "#2C3E50", alpha = 0.15) +
  geom_smooth(data = rd_plot_data[bin >= 0], method = "lm", se = TRUE,
              color = "#C0392B", fill = "#C0392B", alpha = 0.15) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.8) +
  scale_color_manual(
    values = c("TRUE" = "#C0392B", "FALSE" = "#2C3E50"),
    labels = c("Below 21", "21 and over"),
    name = "Age group"
  ) +
  labs(
    title = "Regression Discontinuity: MLDA and Mortality",
    x = "Days from 21st birthday",
    y = "Mortality rate",
    caption = paste0("Bin width: 30 days | Bandwidth: +/- 730 days")
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10),
    legend.position = "bottom"
  )

# Create output directory
dir.create(file.path(root, "analysis/output"), showWarnings = FALSE, recursive = TRUE)

# Save plot
ggsave(
  file.path(root, "analysis/output/rd_plot.png"),
  plot = rd_plot,
  width = 10,
  height = 6,
  dpi = 300
)

# Create regression table
rd_table <- etable(
  rd_linear, rd_poly,
  title = "Regression Discontinuity Results: MLDA and Mortality",
  headers = c("Linear RD", "Polynomial RD"),
  file = file.path(root, "analysis/output/rd_table.tex"),
  replace = TRUE
)

cat("\n  Saved rd_plot.png and rd_table.tex\n")
