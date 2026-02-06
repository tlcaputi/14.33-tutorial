# 14.33 Research & Communication Tutorial

An interactive tutorial for learning data analysis and empirical research methods in economics.

## Overview

This tutorial covers fundamental concepts and practical skills for conducting empirical research in economics, including:

- **Data fundamentals** - Working with datasets, data cleaning, and manipulation
- **Descriptive analysis** - Summary statistics and exploratory data analysis
- **Regression analysis** - OLS, fixed effects, and panel data methods
- **Causal inference** - Difference-in-differences, event studies, and causal identification
- **Project organization** - Best practices for reproducible research
- **Programming** - Code examples in Stata, R, and Python

## Contents

- **`tutorial/`** - Main tutorial pages organized by topic
- **`tutorial/sessions/`** - Session-specific materials and exercises
- **`tutorial/scripts/`** - Code examples for each session (Stata, R, Python)
- **`tutorial/worked-examples/`** - Complete replication packages demonstrating research workflows
- **`files/`** - Course materials (syllabus, setup scripts)
- **`poll/`** - Interactive polling tools for classroom use

## Worked Examples

The `tutorial/worked-examples/` directory contains complete, self-contained replication packages demonstrating empirical research workflows:

### Blood Alcohol Content (BAC) Laws Replication
Replicates the analysis from Carpenter & Dobkin (2009) examining the effect of minimum legal drinking age laws.

- **bac-replication-stata/** - Stata implementation
- **bac-replication-r/** - R implementation
- **bac-replication-python/** - Python implementation

Each package includes:
- `/build/` - Data download and cleaning scripts
- `/analysis/` - Analysis code (regressions, tables, figures)
- `master.[do|R|py]` - Main script to run the entire analysis

**Data source**: NHTSA Fatality Analysis Reporting System (FARS)

### Additional Examples
- **bac-hit-and-run/** - Extension analyzing hit-and-run fatalities
- **texting-bans-event-study** - Event study of texting-while-driving bans

## Getting Started

### Prerequisites

Choose your preferred statistical software:

- **Stata** - Version 16 or higher recommended
- **R** - Version 4.0+ with packages: `tidyverse`, `fixest`, `modelsummary`
- **Python** - Version 3.8+ with packages: `pandas`, `statsmodels`, `linearmodels`

### Setup

1. Run the appropriate setup script from the `files/` directory:
   ```bash
   # macOS/Linux
   bash files/setup.sh

   # Windows (PowerShell)
   .\files\setup.ps1
   ```

2. Open the tutorial at `tutorial/index.html` in your web browser

## Running Replication Packages

Each replication package is self-contained:

```bash
# Example: Run the Stata replication
cd tutorial/worked-examples/bac-replication-stata
stata -b do master.do
```

Results will be saved to `analysis/output/` (tables) and `analysis/figures/` (plots).

## Project Organization

Each replication package follows the structure:

```
project/
├── build/
│   ├── code/          # Data download and cleaning
│   ├── input/         # Raw data (created by scripts)
│   └── output/        # Cleaned datasets
├── analysis/
│   ├── code/          # Analysis scripts
│   ├── output/        # Tables and results
│   └── figures/       # Plots and visualizations
└── master.[do|R|py]   # Main script
```

## Topics Covered

1. **Getting Started** - Software setup, project organization
2. **Data Fundamentals** - Reading, cleaning, and manipulating data
3. **Descriptive Analysis** - Summary statistics, visualization
4. **Basic Regression** - OLS, interpretation, standard errors
5. **Causal Inference** - Treatment effects, difference-in-differences
6. **Causal Methods** - Event studies, instrumental variables
7. **Advanced Topics** - Robustness checks, heterogeneity analysis

## Session Materials

The tutorial includes three hands-on sessions:

- **Session 1** - Data basics and summary statistics
- **Session 2** - Regression and difference-in-differences
- **Session 3** - Event studies and visualization

Each session includes code examples in all three languages (Stata, R, Python).

## Resources

- **LaTeX Tips** - `tutorial/auxiliary-latex.html`
- **Programming Tips** - `tutorial/auxiliary-programming-tips.html`
- **Finding Projects** - `tutorial/finding-project.html`

## License

This tutorial is provided for educational purposes.

## Acknowledgments

Tutorial materials developed for MIT Economics course 14.33 (Research & Communication).
