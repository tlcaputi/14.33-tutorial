#===============================================================================
#    Session 3: Diff-in-Diff and Event Studies
#    Course: 14.33 Economics Research and Communication
#
#    This script demonstrates:
#    1. Setting up panel data for DiD
#    2. Creating treatment timing variables
#    3. Running two-way fixed effects (TWFE)
#    4. Running event study specifications
#===============================================================================

# Clear environment
rm(list = ls())

# Load packages
pacman::p_load(tidyverse, haven, fixest, ggfixest, ggplot2)

# Set working directory (adjust as needed)
# setwd("/Users/yourname/Dropbox/14.33")

#===============================================================================
# STEP 1: Load and explore data
#===============================================================================

# Load the data (adjust path as needed)
df <- read_dta("bacon_example_diff_in_diff_review.dta")

# Explore structure
table(df$year)
table(df$stfips)

# Examine key variables
summary(df$asmrs)   # Female suicide rate (outcome Y)
summary(df[c("pcinc", "asmrh", "cases")])  # Controls

#===============================================================================
# STEP 2: Create treatment timing variable
#===============================================================================

# Create adoption year mapping
# NA = never adopted (control state)
adoption_years <- c(
  `1` = 1971, `4` = 1973, `6` = 1970, `8` = 1971, `9` = 1973,
  `11` = 1977, `12` = 1971, `13` = 1973, `16` = 1971, `17` = 1984,
  `18` = 1973, `19` = 1970, `20` = 1969, `21` = 1972, `23` = 1973,
  `25` = 1975, `26` = 1972, `27` = 1974, `29` = 1973, `30` = 1975,
  `31` = 1972, `32` = 1973, `33` = 1971, `34` = 1971, `35` = 1973,
  `38` = 1971, `39` = 1974, `41` = 1973, `42` = 1980, `44` = 1976,
  `45` = 1969, `46` = 1985, `48` = 1974, `53` = 1973, `55` = 1977,
  `56` = 1977
)

# Add adoption year to dataframe
df <- df %>%
  mutate(nfd = adoption_years[as.character(stfips)])

# Check: how many states adopted vs never adopted?
table(df$nfd, useNA = "ifany")

#===============================================================================
# STEP 3: Create post-treatment indicator for TWFE
#===============================================================================

# Create post-treatment indicator
# = 1 if year >= year state adopted no-fault divorce
# = 0 otherwise (including never-adopters)
df <- df %>%
  mutate(treat_post = ifelse(!is.na(nfd) & year >= nfd, 1, 0))

# Verify
table(df$treat_post, useNA = "ifany")

#===============================================================================
# STEP 4: Two-Way Fixed Effects (TWFE) Regression
#===============================================================================

# Basic TWFE: state + year fixed effects
model_twfe_basic <- feols(asmrs ~ treat_post | stfips + year,
                          cluster = ~stfips, data = df)
summary(model_twfe_basic)

# With controls
model_twfe_controls <- feols(asmrs ~ treat_post + pcinc + asmrh + cases | stfips + year,
                             cluster = ~stfips, data = df)
summary(model_twfe_controls)

# Compare models side by side
etable(model_twfe_basic, model_twfe_controls,
       headers = c("No Controls", "With Controls"))

#===============================================================================
# STEP 5: Event Study Specification
#===============================================================================

# Create time relative to treatment
# Negative = years before treatment
# 0 = year of treatment
# Positive = years after treatment
#
# IMPORTANT: Never-treated states don't have a meaningful "time to treatment"
# Set them to -1000 (outside data range), then exclude with ref = c(-1, -1000)
# See: https://lrberge.github.io/fixest/articles/fixest_walkthrough.html
df <- df %>%
  mutate(
    time_to_treat = year - nfd,
    # Set never-treated to -1000 (outside data range)
    time_to_treat = ifelse(is.na(time_to_treat), -1000, time_to_treat),
    # Create treatment indicator (1 if ever treated, 0 if never)
    treated = ifelse(!is.na(nfd), 1, 0)
  )

# Check the distribution
table(df$time_to_treat)

# Event study using fixest's i() syntax
# i(time_to_treat, treated, ref = c(-1, -1000)) excludes:
#   - t = -1 (reference period)
#   - t = -1000 (never-treated states)
model_es <- feols(
  asmrs ~ i(time_to_treat, treated, ref = c(-1, -1000)) + pcinc + asmrh + cases | stfips + year,
  cluster = ~stfips,
  data = df
)
summary(model_es)

#===============================================================================
# STEP 6: Create Event Study Plot
#===============================================================================

# Quick plot with ggiplot (one line!)
library(ggfixest)
p <- ggiplot(model_es,
        xlab = "Years Relative to No-Fault Divorce Adoption",
        ylab = "Effect on Female Suicide Rate",
        main = "Event Study: No-Fault Divorce and Female Suicide")
ggsave("output/event_study_quick.png", p, width = 10, height = 6, dpi = 300)

# Or create a more customized ggplot
# First extract coefficients
es_coefs <- data.frame(
  time = as.numeric(gsub("time_to_treat::", "", names(coef(model_es)))),
  estimate = coef(model_es),
  se = se(model_es)
) %>%
  filter(!is.na(time)) %>%  # Remove control variable coefficients
  mutate(
    ci_lower = estimate - 1.96 * se,
    ci_upper = estimate + 1.96 * se
  )

# Add reference period (t = -1)
es_coefs <- bind_rows(
  es_coefs,
  data.frame(time = -1, estimate = 0, se = NA, ci_lower = 0, ci_upper = 0)
) %>%
  arrange(time)

# Create the plot
p <- ggplot(es_coefs, aes(x = time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "steelblue") +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "steelblue", size = 2) +
  labs(
    x = "Years Relative to No-Fault Divorce Adoption",
    y = "Effect on Female Suicide Rate",
    title = "Event Study: No-Fault Divorce and Female Suicide",
    caption = "Notes: Reference period is t = -1. Shaded area shows 95% confidence interval.\nStandard errors clustered at the state level."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

# Save the plot
ggsave("output/event_study_plot.png", p, width = 10, height = 6, dpi = 300)

#===============================================================================
# NOTES
#===============================================================================

# Key things to check:
# 1. Pre-treatment coefficients should be near zero (parallel trends)
# 2. Look for anticipation effects (significant coefficients before t=0)
# 3. Post-treatment coefficients show the treatment effect over time

# Modern DiD methods for staggered adoption:
# - Goodman-Bacon decomposition: bacondecomp package
# - Callaway & Sant'Anna: did package
# - Sun & Abraham: fixest::sunab()
# - Imputation estimator: did2s package

# Example with Sun & Abraham (2021) estimator:
# model_sa <- feols(asmrs ~ sunab(nfd, year) | stfips + year,
#                   cluster = ~stfips, data = df)

cat("Session 3 complete!\n")
