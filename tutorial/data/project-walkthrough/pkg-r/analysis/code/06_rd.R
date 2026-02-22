# 06_rd.R
# Regression discontinuity (RD): minimum legal drinking age and mortality
#
# Inspired by Carpenter & Dobkin (2009). The running variable is
# days_from_21 (days since the individual's 21st birthday), centered at 0.
# The cutoff is at 0: individuals with days_from_21 >= 0 are legally
# allowed to drink (over_21 == 1).
#
# Identification: individuals just below 21 and just above 21 are similar
# in all observable and unobservable ways — except their legal drinking status.
# Any sharp jump in mortality at the cutoff is therefore causal.
#
# We estimate three variants:
#   rd_linear   — linear slope on each side (feols, bandwidth = +/-365 days)
#   rd_quadratic — quadratic polynomial on each side (feols, same bandwidth)
#   rd_robust    — data-driven bandwidth via rdrobust (Calonico et al.)
#
# Outputs:
#   analysis/output/figures/rd_plot.png
#   analysis/output/tables/rd_results.tex

cat("Running 06_rd.R...\n")

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

pacman::p_load(data.table, fixest, ggplot2, rdrobust)

# ---- Read data -------------------------------------------------------
dt <- fread(file.path(root, "analysis/code/rd_data.csv"))

cat("\nDataset:", nrow(dt), "observations\n")
cat("Variables:", paste(names(dt), collapse = ", "), "\n")
cat("\nRunning variable (days_from_21) range:",
    dt[, min(days_from_21)], "to", dt[, max(days_from_21)], "\n")
cat("Observations above cutoff (over_21 == 1):",
    dt[over_21 == 1, .N], "\n")

# ---- Restrict to bandwidth = +/-365 days ----------------------------
# Working within a bandwidth reduces the influence of non-local trends
# but may cost statistical power. We choose 365 days (one year).
bandwidth <- 365
dt_bw <- dt[abs(days_from_21) <= bandwidth]

cat("\nBandwidth: +/-", bandwidth, "days\n")
cat("In-bandwidth observations:", nrow(dt_bw), "\n")

# ---- Create interaction term -----------------------------------------
# The RD model allows a different linear slope on each side of the cutoff:
#   mortality = alpha + beta*over_21 + gamma*days_from_21 + delta*(days_from_21 * over_21) + ...
# beta is the discontinuity at the cutoff (our estimate of interest).
# gamma is the slope below the cutoff; gamma + delta is the slope above.
dt_bw[, days_x_over21 := days_from_21 * over_21]

# ---- Linear RD -------------------------------------------------------
rd_linear <- feols(
  mortality_rate ~ over_21 + days_from_21 + days_x_over21 + male + income,
  data = dt_bw,
  vcov = "hetero"
)

cat("\nLinear RD (bandwidth =", bandwidth, "days):\n")
print(summary(rd_linear))
cat("  Estimated discontinuity at cutoff: ",
    sprintf("%.4f", coef(rd_linear)["over_21"]), "\n")

# ---- Quadratic RD ----------------------------------------------------
# A quadratic polynomial gives more flexibility to fit the data, but
# polynomial RD is sensitive to overfitting. We use it as a robustness check.
dt_bw[, days_sq          := days_from_21^2]
dt_bw[, days_sq_x_over21 := days_sq * over_21]

rd_quadratic <- feols(
  mortality_rate ~ over_21 + days_from_21 + days_x_over21 +
                   days_sq + days_sq_x_over21 + male + income,
  data = dt_bw,
  vcov = "hetero"
)

cat("\nQuadratic RD:\n")
print(summary(rd_quadratic))

# ---- rdrobust: data-driven bandwidth ---------------------------------
# rdrobust (Calonico, Cattaneo & Titiunik, 2014) selects the bandwidth
# that optimally balances bias and variance. It also provides a bias-
# corrected point estimate and robust confidence intervals.
cat("\nrdrobust (data-driven bandwidth):\n")
rd_robust <- rdrobust(
  y = dt$mortality_rate,
  x = dt$days_from_21,
  c = 0   # cutoff at 0
)
print(summary(rd_robust))

cat("\n  rdrobust bandwidth:", rd_robust$bws[1, 1], "days\n")
cat("  rdrobust estimate: ", rd_robust$coef[1], "\n")
cat("  95% CI: [", rd_robust$ci[3, 1], ",", rd_robust$ci[3, 2], "]\n")

# ---- RD scatter plot -------------------------------------------------
# Bin individuals into 30-day windows and plot the average mortality rate
# per bin. Color the points by which side of the cutoff they fall on.
# Add separate geom_smooth lines for each side.

dt_plot <- copy(dt[abs(days_from_21) <= 730])  # +/-2 years for the plot
dt_plot[, bin := floor(days_from_21 / 30) * 30 + 15]
dt_plot[, side := fifelse(days_from_21 >= 0, "21 and over", "Under 21")]

bin_data <- dt_plot[, .(
  mean_mortality = mean(mortality_rate, na.rm = TRUE)
), by = .(bin, side)]

rd_plot <- ggplot(bin_data, aes(x = bin, y = mean_mortality, color = side)) +
  # Scatter: one dot per 30-day bin
  geom_point(size = 2.0, alpha = 0.75) +
  # Linear fit on each side of the cutoff
  geom_smooth(
    data   = bin_data[side == "Under 21"],
    method = "lm", se = FALSE, linewidth = 0.9
  ) +
  geom_smooth(
    data   = bin_data[side == "21 and over"],
    method = "lm", se = FALSE, linewidth = 0.9
  ) +
  # Mark the cutoff
  geom_vline(xintercept = 0, linetype = "dashed",
             color = "black", linewidth = 0.6) +
  scale_color_manual(
    values = c("Under 21" = "steelblue", "21 and over" = "firebrick"),
    name   = NULL
  ) +
  labs(
    x       = "Days from 21st birthday",
    y       = "Mortality rate",
    caption = "Each point is a 30-day bin. Bandwidth shown: +/- 730 days. Linear fit shown on each side."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position  = "bottom",
    axis.title       = element_text(size = 11),
    axis.text        = element_text(size = 10),
    plot.caption     = element_text(size = 8, color = "grey40")
  )

# ---- Save outputs ----------------------------------------------------
dir.create(file.path(root, "analysis/output/figures"),
           showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(root, "analysis/output/tables"),
           showWarnings = FALSE, recursive = TRUE)

ggsave(
  file.path(root, "analysis/output/figures/rd_plot.png"),
  plot   = rd_plot,
  width  = 9,
  height = 5.5,
  dpi    = 300
)

etable(
  rd_linear, rd_quadratic,
  title   = "Regression Discontinuity: MLDA and Mortality",
  headers = c("Linear", "Quadratic"),
  dict    = c(
    over_21          = "Over 21 (discontinuity)",
    days_from_21     = "Days from 21st birthday",
    days_x_over21    = "Days $\\times$ Over 21",
    days_sq          = "Days$^2$",
    days_sq_x_over21 = "Days$^2$ $\\times$ Over 21",
    male             = "Male",
    income           = "Income",
    mortality_rate   = "Mortality rate"
  ),
  notes  = paste0(
    "Bandwidth: +/-", bandwidth, " days. ",
    "Heteroskedasticity-robust standard errors. ",
    "rdrobust estimate (data-driven bandwidth): ",
    sprintf("%.4f", rd_robust$coef[1]), "."
  ),
  file    = file.path(root, "analysis/output/tables/rd_results.tex"),
  replace = TRUE
)

cat("\n  Saved rd_plot.png and rd_results.tex\n")
