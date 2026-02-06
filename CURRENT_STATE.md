# 14.33 Tutorial - Current State

Last Updated: 2026-02-01

## Overview
The 14.33 Economics Research and Communication tutorial provides Stata and R code examples for students. It's hosted at `theodorecaputi.com/teaching/14.33/tutorial/`.

## Directory Structure
```
gh-website/teaching/14.33/
├── index.html              # Course homepage
├── style.css               # Shared styles for course + tutorial
├── tutorial.js             # Tutorial JavaScript (tab switching, copy buttons)
├── tutorial.html           # Redirect to tutorial/index.html
├── files/
│   ├── syllabus.pdf
│   └── schedule.pdf
└── tutorial/
    ├── index.html          # Tutorial home
    ├── getting-started.html
    ├── data-fundamentals.html
    ├── descriptive-analysis.html
    ├── applied-micro.html
    ├── regression.html
    └── advanced.html
```

## Key Features

### Language Toggle
- Global toggle in sidebar switches between Stata and R code
- Uses `data-lang` attributes on code tabs
- JavaScript in `tutorial.js` handles switching

### Mobile Responsiveness
- Sidebar becomes slide-out menu at 900px
- Comparison grids stack at 900px
- Code blocks extend full-width with horizontal scroll
- Tested on iPhone 13 Pro Max (428px viewport)

### Code Blocks
Structure:
```html
<div class="code-block">
  <div class="code-header">
    <div class="code-tabs">
      <button class="code-tab active" data-lang="stata">Stata</button>
      <button class="code-tab" data-lang="r">R</button>
    </div>
    <button class="copy-btn">Copy</button>
  </div>
  <pre class="code-content stata active"><code>...</code></pre>
  <pre class="code-content r"><code>...</code></pre>
</div>
```

### Comparison Grids
Use `.comparison-grid` class for side-by-side comparisons that stack on mobile:
```html
<div class="comparison-grid">
  <div>Left content</div>
  <div>Right content</div>
</div>
```

## CSS Breakpoints
- **900px**: Tutorial becomes single column, sidebar slides out, comparison grids stack
- **600px**: Further size reductions, boxes go full-width

## Code Validation
All code has been tested:
- **R**: 47 blocks parse successfully with `parse()`
- **Stata**: 53 blocks have no syntax errors (tested with local Stata SE)

To re-run validation:
```bash
# R syntax check
Rscript -e "parse(file = '/tmp/tutorial_r_code.R')"

# Stata syntax check (requires license)
/Applications/Stata/StataSE.app/Contents/MacOS/stata-se -b do /tmp/test_stata_syntax.do
```

## Common Issues

### Mobile overflow
If content overflows on mobile:
1. Check for inline `style="grid-template-columns: 1fr 1fr"` - convert to `.comparison-grid` class
2. Ensure code blocks have `max-width: 100%` and `overflow-x: auto`
3. Add `overflow-x: hidden` to parent containers

### CSS not updating
GitHub Pages and browsers cache aggressively:
- Add query string: `?v=timestamp`
- Use incognito mode
- Hard refresh: Cmd+Shift+R

### Stata commands not recognized
User-written commands need installation:
```stata
ssc install estout      // for esttab, estpost
ssc install reghdfe     // for fixed effects
ssc install coefplot    // for coefficient plots
```

## Related Files
- Main site: `gh-website/index.html`
- Hugo site teaching page: `theodorecaputihugo/content/teaching.md`
- Changelog: `.CHANGELOG/2026-02-01_tutorial-mobile-fixes.md`

## Deployment
The site auto-deploys via GitHub Pages when pushed to `master`:
```bash
cd gh-website
git add -A
git commit -m "Description"
git push origin master
```

Site URL: https://theodorecaputi.com
