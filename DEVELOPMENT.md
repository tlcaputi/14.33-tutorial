# 14.33 Tutorial Development Guide

**Repository:** https://github.com/tlcaputi/14.33-tutorial
**Live Site:** https://theodorecaputi.com/teaching/14.33/tutorial/index.html

## Overview

This repository contains the tutorial materials for MIT Economics course 14.33 (Research & Communication). It is designed to be:
- **Standalone** - Can be used independently or cloned separately
- **Submodule-ready** - Included in the main website via Git submodule
- **Educational** - Complete replication packages demonstrating research workflows

## Repository Structure

```
14.33-tutorial/
├── README.md                    # User-facing documentation
├── DEVELOPMENT.md               # This file
├── .gitignore
│
├── tutorial/                    # Main tutorial content
│   ├── index.html              # Tutorial index (uses layout from parent)
│   ├── getting-started.html
│   ├── data-fundamentals.html
│   ├── regression.html
│   ├── causal-inference.html
│   ├── sessions/               # In-class session materials
│   │   ├── session1.html
│   │   ├── session2.html
│   │   └── session3.html
│   ├── scripts/                # Code examples
│   │   ├── session1/
│   │   │   ├── session1.do
│   │   │   ├── session1.R
│   │   │   └── session1.py
│   │   ├── session2/
│   │   └── session3/
│   ├── examples/               # Worked examples
│   │   └── bac-replication.html
│   ├── worked-examples/        # Complete replication packages
│   │   ├── bac-replication-stata/
│   │   │   ├── build/
│   │   │   │   ├── input/      # Raw data (gitignored)
│   │   │   │   ├── output/     # Cleaned data (gitignored)
│   │   │   │   └── code/
│   │   │   ├── analysis/
│   │   │   │   ├── output/     # Tables
│   │   │   │   ├── figures/    # Plots
│   │   │   │   └── code/
│   │   │   └── master.do
│   │   ├── bac-replication-stata.zip
│   │   ├── bac-replication-r/
│   │   ├── bac-replication-r.zip
│   │   ├── bac-replication-python/
│   │   └── bac-replication-python.zip
│   └── data/                   # Example datasets
│
├── files/                      # Course materials
│   ├── setup.sh               # macOS/Linux setup script
│   ├── setup.ps1              # Windows setup script
│   ├── syllabus.pdf
│   └── schedule.pdf
│
├── poll/                       # Interactive polling tools
│   ├── presenter.html
│   ├── student.html
│   └── teach.html
│
├── style.css                   # Tutorial-specific styles
├── tutorial.js                 # Interactive features
└── prism-stata.js             # Stata syntax highlighting
```

## Development Workflow

### Local Development

This repository is typically used as part of the main website via submodule, but can also be developed standalone:

```bash
# Clone standalone
git clone https://github.com/tlcaputi/14.33-tutorial.git
cd 14.33-tutorial

# Make changes
# Edit files...

# Commit and push
git add .
git commit -m "Description of changes"
git push origin master
```

### As Part of Website

When included as submodule in `tlcaputi.github.io`:

```bash
# Navigate to submodule
cd teaching/14.33

# Make changes
# Edit files...

# Commit to tutorial repo
git add .
git commit -m "Update tutorial content"
git push origin master

# Update submodule reference in parent repo
cd ../..
git add teaching/14.33
git commit -m "Update tutorial submodule"
git push origin master
```

## File Conventions

### HTML Files

Tutorial pages use **front matter** for Eleventy processing:
```html
---
layout: layouts/tutorial.html
title: Page Title | 14.33
current_page: getting-started
---
```

**Important:** Layout files (`layouts/tutorial.html`) are in the **parent website repository**, not here.

### Code Examples

Code examples are provided in three languages:
- `*.do` - Stata
- `*.R` - R
- `*.py` - Python

Use consistent formatting and comments across languages.

### Replication Packages

Each replication package follows this structure:
```
package-name/
├── build/
│   ├── input/          # Raw data (gitignored)
│   ├── output/         # Cleaned data (gitignored)
│   └── code/           # Data cleaning scripts
├── analysis/
│   ├── output/         # Tables/results
│   ├── figures/        # Plots
│   └── code/           # Analysis scripts
└── master.[do|R|py]    # Main execution script
```

**Data files are gitignored** to keep repository size manageable. Scripts download data automatically.

## Gitignore Rules

```gitignore
# Private notes
.CHANGELOG/

# Data files (too large, downloaded by scripts)
tutorial/worked-examples/*/build/input/*.dta
tutorial/worked-examples/*/build/input/*.csv
tutorial/worked-examples/*/build/output/*.dta
tutorial/worked-examples/*/build/output/*.csv

# Logs
*.log
```

## Content Guidelines

### Writing Style
- Clear, concise explanations
- Assume reader is economics student with basic stats knowledge
- Provide examples for every concept
- Include code in all three languages when possible

### Code Style
- **Stata:** Use consistent indentation, comment blocks with `/**/`
- **R:** Follow tidyverse style guide
- **Python:** Follow PEP 8

### Replication Packages
- Must run from start to finish without errors
- Download all data automatically (no manual downloads)
- Produce all tables and figures
- Include descriptive comments

## Testing

### Before Committing

1. **Check HTML syntax:**
   ```bash
   # Visual check in browser
   open tutorial/getting-started.html
   ```

2. **Test code examples:**
   ```bash
   # Stata
   stata -b do tutorial/scripts/session1/session1.do

   # R
   Rscript tutorial/scripts/session1/session1.R

   # Python
   python tutorial/scripts/session1/session1.py
   ```

3. **Verify replication packages:**
   ```bash
   cd tutorial/worked-examples/bac-replication-stata
   stata -b do master.do
   # Check that output/ and figures/ are populated
   ```

### Integration Testing

When used as submodule, test the full website build:
```bash
cd /path/to/gh-website
npx @11ty/eleventy --serve
# Visit http://localhost:8080/teaching/14.33/tutorial/index.html
```

## Adding New Content

### New Tutorial Page

1. Create HTML file in `tutorial/`:
   ```html
   ---
   layout: layouts/tutorial.html
   title: New Topic | 14.33
   current_page: new-topic
   ---

   <h1>New Topic</h1>
   <p>Content...</p>
   ```

2. Add to navigation in parent repo's `_data/tutorialNav.json`

3. Test locally

4. Commit and push

### New Replication Package

1. Create directory structure:
   ```bash
   mkdir -p tutorial/worked-examples/my-replication/{build/{code,input,output},analysis/{code,output,figures}}
   ```

2. Add `.gitkeep` files:
   ```bash
   echo "# Output files" > tutorial/worked-examples/my-replication/analysis/output/.gitkeep
   echo "# Generated figures" > tutorial/worked-examples/my-replication/analysis/figures/.gitkeep
   ```

3. Create master script (e.g., `master.do`):
   ```stata
   * Master Do-File: My Replication

   clear all
   set more off

   global root_dir "`c(pwd)'"

   * Run build scripts
   do build/code/01_download_data.do
   do build/code/02_clean_data.do

   * Run analysis
   do analysis/code/01_regressions.do
   do analysis/code/02_tables.do
   do analysis/code/03_figures.do
   ```

4. Add code scripts

5. Test end-to-end

6. Create zip file:
   ```bash
   cd tutorial/worked-examples
   zip -r my-replication.zip my-replication/
   ```

7. Commit everything

## Git History

This repository was created on **2026-02-06** with a **clean history** - no references to the parent website. The commit history should remain clean and focused on tutorial content only.

**Current commits:**
- `0520a40` - Initial commit: 14.33 tutorial materials
- `fd65ec8` - Update site title to 'Research and Communication in Economics'

## Important Notes

### No Website Dependencies

This repository should **never reference** the parent website:
- No links to `theodorecaputi.com` in code
- No assumptions about being in `teaching/14.33/`
- All paths should be relative
- README should describe standalone usage

### Layout Files Not Included

HTML layout templates are in the **parent repository** at:
- `_includes/layouts/tutorial.html`
- `_includes/layouts/tutorial-index.html`
- `_includes/focused-nav.liquid`
- `_includes/tutorial-nav.liquid`

To change layouts, edit those files in the parent repo.

### Data Files

Large data files are **not committed**. Replication packages download data automatically using:
- Stata: `copy` command or API calls
- R: `download.file()` or package functions
- Python: `urllib`, `requests`, or package functions

### Private Notes

The `.CHANGELOG/` directory is gitignored for private development notes. Use it freely for personal documentation, but don't commit it.

## Deployment

This repository is deployed as part of the main website via GitHub Pages:

1. Changes pushed to this repo
2. Parent repo's submodule reference is updated
3. GitHub Actions in parent repo triggers
4. Eleventy builds site including submodule content
5. Deployed to https://theodorecaputi.com

**No direct deployment** from this repository - it's always deployed via the parent.

## Resources

- **Live Site:** https://theodorecaputi.com/teaching/14.33/tutorial/index.html
- **Parent Repository:** https://github.com/tlcaputi/tlcaputi.github.io
- **Submodule Guide:** `14.33-SUBMODULE-GUIDE.md` in parent repo
- **Migration History:** `.CHANGELOG/2026-02-06_14.33-submodule-migration.md` in parent repo

## Questions?

For questions about:
- **Tutorial content:** Issues in this repository
- **Website integration:** Issues in parent repository
- **Course logistics:** Contact course staff

---

**Last Updated:** 2026-02-06
**Maintainer:** Theodore Caputi
