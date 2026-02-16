pacman::p_load(fixest, data.table)

set.seed(42)

# Generate fake state-year panel data for a DD analysis
n_states <- 50
n_years <- 10
years <- 2010:2019

dt <- CJ(state = 1:n_states, year = years)

# Randomly assign 25 states to treatment, with staggered adoption
treated_states <- sample(1:n_states, 25)
adopt_year <- sample(2013:2016, 25, replace = TRUE)
treat_info <- data.table(state = treated_states, adopt_year = adopt_year)
dt <- merge(dt, treat_info, by = "state", all.x = TRUE)
dt[is.na(adopt_year), adopt_year := 9999]

# Treatment indicator
dt[, treated := as.integer(year >= adopt_year)]

# State and year fixed effects + treatment effect of ~-2.5
state_fe <- rnorm(n_states, 0, 3)
year_fe <- seq(0, 4.5, length.out = n_years)
dt[, outcome := 50 + state_fe[state] + year_fe[year - 2009] - 2.5 * treated + rnorm(.N, 0, 2)]

# A second outcome
dt[, outcome2 := 30 + state_fe[state] * 0.5 + year_fe[year - 2009] * 0.8 - 1.8 * treated + rnorm(.N, 0, 1.5)]

# A covariate
dt[, population := round(runif(.N, 500000, 10000000))]
dt[, log_pop := log(population)]

# --- Run regressions ---
m1 <- feols(outcome ~ treated | state + year, data = dt)
m2 <- feols(outcome ~ treated + log_pop | state + year, data = dt)
m3 <- feols(outcome ~ treated | state + year, data = dt, vcov = ~state)
m4 <- feols(outcome2 ~ treated | state + year, data = dt, vcov = ~state)

# --- Export etable to .tex ---
etable(
  m1, m2, m3, m4,
  headers = list(":_sym:" = c("(1)", "(2)", "(3)", "(4)")),
  tex = TRUE,
  file = "etable_output.tex",
  replace = TRUE,
  style.tex = style.tex(
    depvar.title = "Dep. Var.:",
    fixef.title = "\\midrule",
    fixef.suffix = "",
    yesNo = c("Yes", ""),
    stats.title = "\\midrule"
  ),
  fitstat = ~ n + r2 + wr2,
  dict = c(
    outcome = "Fatality Rate",
    outcome2 = "Injury Rate",
    treated = "Policy Adopted",
    log_pop = "Log(Population)"
  ),
  se.below = TRUE,
  depvar = TRUE
)

cat("Saved etable_output.tex\n")
