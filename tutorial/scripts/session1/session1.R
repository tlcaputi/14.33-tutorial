#===============================================================================
#   R Session 1: Basics through Merging
#   14.33 Economics Research and Communication
#
#   This script covers:
#   - Basic R commands
#   - Exploring data
#   - Creating variables
#   - Importing CSV files
#   - Reshaping data (wide to long)
#   - Merging datasets
#===============================================================================

# Clear environment
rm(list = ls())

# Load packages
pacman::p_load(tidyverse, haven)

# Set your working directory (CHANGE THIS!)
# setwd("/Users/yourname/Dropbox/14.33/session1")

#===============================================================================
# PART 1: BASIC COMMANDS
#===============================================================================

# Load built-in dataset
data(mtcars)

# View the data
View(mtcars)

# Get an overview
str(mtcars)
glimpse(mtcars)

# Summary statistics
summary(mtcars)

# Summary of specific variables
summary(mtcars[c("mpg", "hp", "wt")])

# Frequency table
table(mtcars$cyl)

# Cross-tabulation
table(mtcars$cyl, mtcars$am)

#===============================================================================
# PART 2: CREATING VARIABLES
#===============================================================================

# Create a new variable
mtcars$hp_per_cyl <- mtcars$hp / mtcars$cyl

# Using dplyr (preferred)
mtcars <- mtcars %>%
  mutate(
    # Create a new variable
    wt_kg = wt * 453.592,

    # Create a binary indicator
    high_mpg = mpg > 20,

    # Conditional assignment
    efficiency = case_when(
      mpg < 15 ~ "Low",
      mpg < 25 ~ "Medium",
      TRUE ~ "High"
    )
  )

# Filter (like Stata's if condition)
mtcars %>%
  filter(cyl == 6) %>%
  summarize(mean_mpg = mean(mpg))

# Drop observations (filter to keep)
mtcars_clean <- mtcars %>%
  filter(!is.na(mpg))

# Keep only certain columns
mtcars_subset <- mtcars %>%
  select(mpg, hp, wt, cyl)

#===============================================================================
# PART 3: IMPORTING CSV DATA
#===============================================================================

# Import a CSV file
# data <- read_csv("mydata.csv")

# Common options:
# data <- read_csv("mydata.csv", col_names = TRUE)
# data <- read_csv("mydata.csv", skip = 1)  # Skip first row

# Read Stata files
# data <- read_dta("mydata.dta")

#===============================================================================
# PART 4: RESHAPING DATA
#===============================================================================

# Create example wide data
wide_data <- tibble(
  id = 1:3,
  income_2020 = c(50000, 60000, 45000),
  income_2021 = c(52000, 61000, 47000),
  income_2022 = c(54000, 63000, 48000)
)

# Look at wide format
print(wide_data)

# Reshape from wide to long using pivot_longer
long_data <- wide_data %>%
  pivot_longer(
    cols = starts_with("income_"),
    names_to = "year",
    names_prefix = "income_",
    values_to = "income"
  ) %>%
  mutate(year = as.numeric(year))

# Look at long format
print(long_data)

# Reshape back to wide (if needed)
wide_again <- long_data %>%
  pivot_wider(
    id_cols = id,
    names_from = year,
    names_prefix = "income_",
    values_from = income
  )

#===============================================================================
# PART 5: MERGING DATASETS
#===============================================================================

# Create master dataset (individuals)
individuals <- tibble(
  person_id = 1:4,
  state = c("MA", "MA", "CA", "NY"),
  income = c(50000, 60000, 70000, 55000)
)

# Create using dataset (state characteristics)
state_data <- tibble(
  state = c("MA", "CA", "TX"),
  min_wage = c(15.00, 15.50, 7.25),
  population = c(7000000, 39500000, 29500000)
)

# Left join: keep all individuals, add state data where available
merged <- individuals %>%
  left_join(state_data, by = "state")

# Check for unmatched (NY had no state data)
merged %>%
  filter(is.na(min_wage))

# Inner join: keep only matched
merged_inner <- individuals %>%
  inner_join(state_data, by = "state")

# View results
print(merged)
print(merged_inner)

#===============================================================================
# CLEANUP
#===============================================================================

cat("Session 1 script complete!\n")
