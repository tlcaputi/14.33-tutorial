# 03_event_study.R
# Event study (dynamic DiD)
#
# Instead of a single post_treated coefficient, we estimate a separate
# effect for each year relative to policy adoption. This does two things:
#   1. Tests the parallel trends ASSUMPTION: pre-period coefficients should
#      be near zero (no pre-trends).
#   2. Traces out how the policy EFFECT EVOLVES over time.
#
# Time-to-treatment variable:
#   time_to_treat = year - adoption_year  (NA for never-treated states)
# Reference category: t = -1 (one year before adoption)
# Endpoints binned at -5 and +5 to avoid sparse tails.
#
# Outputs:
#   analysis/output/figures/event_study.png

cat("Running 03_event_study.R...\n")

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

pacman::p_load(data.table, fixest, ggplot2)

# ---- Read data -------------------------------------------------------
dt <- fread(file.path(root, "build/output/analysis_panel.csv"))
dt[, log_fatal := log(fatal_crashes + 1)]

# ---- Create time_to_treat and ever_treated ---------------------------
# ever_treated = 1 if a state ever adopts, 0 if never-treated.
# never-treated states get time_to_treat = -1000 (a sentinel value that
# fixest's i() function can exclude from the interaction dummies).
dt[, ever_treated := as.integer(!is.na(adoption_year))]

dt[, time_to_treat := fifelse(
  ever_treated == 1,
  as.integer(year - adoption_year),
  -1000L   # sentinel: never-treated, contributes to FE estimation only
)]

# ---- Bin endpoints to avoid sparse tails ----------------------------
# Observations at t <= -5 are grouped into a single "= -5" cell,
# and t >= 5 into a single "= +5" cell. This keeps the plot clean.
dt[time_to_treat != -1000 & time_to_treat < -5, time_to_treat := -5L]
dt[time_to_treat != -1000 & time_to_treat >  5, time_to_treat :=  5L]

# ---- Event study regression ------------------------------------------
# i(time_to_treat, ever_treated, ref = c(-1, -1000)) creates dummies
# for each value of time_to_treat interacted with ever_treated,
# omitting t = -1 (reference) and the never-treated sentinel (-1000).
#
# The never-treated states are included in the regression; they identify
# the year fixed effects but receive a zero on every event-time dummy.
es_model <- feols(
  log_fatal ~ i(time_to_treat, ever_treated, ref = c(-1, -1000)) |
    state_fips + year,
  data = dt,
  vcov = ~state_fips
)

cat("\nEvent Study Coefficients:\n")
print(summary(es_model))

# ---- Extract coefficients for plotting -------------------------------
# iplot() from fixest can do this automatically, but we build the plot
# manually with ggplot2 so we have full control over the aesthetics.
coef_names <- names(coef(es_model))

# Pull the time values out of the coefficient names
# (they look like "time_to_treat::-5:ever_treated", etc.)
coef_dt <- data.table(
  name = coef_names,
  coef = coef(es_model),
  se   = se(es_model)
)
coef_dt <- coef_dt[grepl("time_to_treat", name)]

# Parse the time index from the name string
coef_dt[, time := as.integer(
  gsub(".*time_to_treat::(-?[0-9]+).*", "\\1", name)
)]

# Add the reference period (t = -1, coef = 0 by construction)
coef_dt <- rbind(
  coef_dt[, .(time, coef, se)],
  data.table(time = -1L, coef = 0, se = 0)
)
coef_dt <- coef_dt[order(time)]

# 95% confidence intervals
coef_dt[, ci_lower := coef - 1.96 * se]
coef_dt[, ci_upper := coef + 1.96 * se]

# ---- Plot ------------------------------------------------------------
event_plot <- ggplot(coef_dt, aes(x = time, y = coef)) +
  # Shaded confidence band (ribbon is preferred over error bars)
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = "steelblue", alpha = 0.20) +
  # Point estimates connected by a line
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_point(color = "steelblue", size = 2.5) +
  # Reference lines
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  geom_vline(xintercept = -0.5, linetype = "dashed",
             color = "firebrick", linewidth = 0.5) +
  scale_x_continuous(breaks = -5:5) +
  labs(
    x       = "Years relative to policy adoption",
    y       = "Effect on log fatal crashes",
    caption = "Reference period: t = \u22121. 95% confidence intervals shown.\nEndpoints binned at \u22125 and +5. Standard errors clustered by state."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.title  = element_text(size = 11),
    axis.text   = element_text(size = 10),
    plot.caption = element_text(size = 8, color = "grey40")
  )

# ---- Save figure -----------------------------------------------------
dir.create(file.path(root, "analysis/output/figures"),
           showWarnings = FALSE, recursive = TRUE)

ggsave(
  file.path(root, "analysis/output/figures/event_study.png"),
  plot   = event_plot,
  width  = 9,
  height = 5.5,
  dpi    = 300
)

cat("\n  Saved event_study.png\n")
