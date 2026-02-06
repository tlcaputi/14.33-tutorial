#===============================================================================
#   R Session 2: Loops, Organization, and Regression
#   14.33 Economics Research and Communication
#
#   This script covers:
#   - Loops (for, lapply/map)
#   - Variables and functions
#   - Project organization
#   - OLS regression
#   - Fixed effects (with fixest)
#   - Instrumental variables
#   - Exporting results (with modelsummary)
#===============================================================================

rm(list = ls())

# Load packages
pacman::p_load(tidyverse, fixest, modelsummary)

#===============================================================================
# PART 1: LOOPS
#===============================================================================

# Basic for loop
for (i in 1:5) {
  print(paste("Iteration", i))
}

# Loop with step size
for (i in seq(5, 25, by = 5)) {
  print(paste("Value:", i))
}

# Loop over a vector
vars <- c("mpg", "hp", "wt")
for (var in vars) {
  print(paste("Variable:", var))
}

# Better: use lapply/map (functional approach)
data(mtcars)
map(vars, ~ summary(mtcars[[.x]]))

#===============================================================================
# PART 2: VARIABLES AND FUNCTIONS
#===============================================================================

# Store a value
myvar <- 7
print(myvar)

# Store a list of controls
controls <- c("hp", "wt")

# Use in a model
model <- lm(mpg ~ hp + wt, data = mtcars)
summary(model)

# Extract coefficients
coef_hp <- coef(model)["hp"]
print(paste("HP coefficient:", round(coef_hp, 4)))

#===============================================================================
# PART 3: PROJECT ORGANIZATION
#===============================================================================

# Example master script structure:
# rm(list = ls())
#
# # Set paths
# root <- "/Users/me/Dropbox/project"
# build <- file.path(root, "build")
# analysis <- file.path(root, "analysis")
#
# # Load packages
# library(tidyverse)
# library(fixest)
#
# # Run scripts
# source(file.path(build, "code", "01_import.R"))
# source(file.path(build, "code", "02_clean.R"))
# source(file.path(analysis, "code", "01_regressions.R"))

#===============================================================================
# PART 4: REGRESSION
#===============================================================================

data(mtcars)

# Simple OLS with fixest (much faster than lm for large data)
model <- feols(mpg ~ hp, data = mtcars)
summary(model)

# Multiple regression
model <- feols(mpg ~ hp + wt + qsec, data = mtcars)
summary(model)

# Heteroskedasticity-robust standard errors
model <- feols(mpg ~ hp + wt + qsec, data = mtcars, vcov = "hetero")
summary(model)

# Clustered standard errors
model <- feols(mpg ~ hp + wt, data = mtcars, vcov = ~cyl)
summary(model)

#===============================================================================
# PART 5: INTERACTIONS
#===============================================================================

# : adds just the interaction
model <- feols(mpg ~ hp + am:wt, data = mtcars)

# * adds interaction AND main effects
model <- feols(mpg ~ hp + am * wt, data = mtcars)
summary(model)

#===============================================================================
# PART 6: FIXED EFFECTS
#===============================================================================

# One-way fixed effects (by cylinder)
model_fe <- feols(mpg ~ hp + wt | cyl, data = mtcars)
summary(model_fe)

# Two-way fixed effects
model_twfe <- feols(mpg ~ hp + wt | cyl + gear, data = mtcars)
summary(model_twfe)

# With clustered standard errors
model_fe_cl <- feols(mpg ~ hp + wt | cyl, data = mtcars, vcov = ~cyl)
summary(model_fe_cl)

#===============================================================================
# PART 7: INSTRUMENTAL VARIABLES
#===============================================================================

# IV syntax with fixest: Y ~ controls | FE | endogenous ~ instruments
# Example (not causally meaningful, just syntax demo)
model_iv <- feols(mpg ~ wt | 0 | hp ~ disp + drat, data = mtcars)
summary(model_iv)

# Check first-stage F-statistic
fitstat(model_iv, "ivf")

#===============================================================================
# PART 8: EXPORTING RESULTS
#===============================================================================

# Run multiple models
m1 <- feols(mpg ~ hp, data = mtcars, vcov = "hetero")
m2 <- feols(mpg ~ hp + wt, data = mtcars, vcov = "hetero")
m3 <- feols(mpg ~ hp + wt + qsec, data = mtcars, vcov = "hetero")

# Display table
modelsummary(
  list("(1)" = m1, "(2)" = m2, "(3)" = m3),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  gof_omit = "IC|Log"
)

# Export to LaTeX
# modelsummary(list(m1, m2, m3), output = "results.tex")

# Export to Word
# modelsummary(list(m1, m2, m3), output = "results.docx")

#===============================================================================
# PART 9: RUNNING MULTIPLE REGRESSIONS
#===============================================================================

# Run same regression for different outcomes
outcomes <- c("mpg", "qsec")
models <- map(outcomes, ~ feols(
  as.formula(paste(.x, "~ hp + wt")),
  data = mtcars,
  vcov = "hetero"
))
names(models) <- outcomes
etable(models)

#===============================================================================
# PRACTICE EXERCISE
#===============================================================================

cat("\n\nPRACTICE EXERCISE:\n")
cat("1. Create a vector called 'controls' containing c('wt', 'qsec')\n")
cat("2. Run: feols(mpg ~ hp + wt + qsec | cyl, data = mtcars, vcov = ~cyl)\n")
cat("3. Use a loop to print summary stats for mpg, wt, and hp\n\n")

# Solution:
controls <- c("wt", "qsec")
model_practice <- feols(mpg ~ hp + wt + qsec | cyl, data = mtcars, vcov = ~cyl)
summary(model_practice)

for (v in c("mpg", "wt", "hp")) {
  cat(paste("\nSummary for", v, ":\n"))
  print(summary(mtcars[[v]]))
}

cat("\n\nSession 2 script complete!\n")
