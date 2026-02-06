# Tutorial Unification Plan

## Goal
Create a consistent, unified tutorial system where all tutorials share the same structure, navigation patterns, and code presentation style.

## Status: COMPLETE

All tutorials have been unified with consistent structure, navigation, and styling.

---

## Tutorials Updated

### 1. Intro to Data Analysis (Reference Guide)
**Files:** getting-started.html, data-fundamentals.html, descriptive-analysis.html, applied-micro.html, regression.html, advanced.html
**Status:** COMPLETE
**Done:**
- [x] Language toggle in sidebar (consistent button style)
- [x] Stata/R/Python code tabs
- [x] Focused sidebar with hierarchical structure
- [x] Fixed "14.33 Home" link to main site

### 2. Stata Session 1
**File:** sessions/session1.html
**Status:** COMPLETE
**Done:**
- [x] Language toggle in sidebar
- [x] Stata/R/Python code tabs
- [x] Focused sidebar
- [x] Section quizzes (Reshaping: 1, Merging: 3)
- [x] Hierarchical structure (Introduction, Reading, Reshaping, Merging)

### 3. Stata Session 2
**File:** sessions/session2.html
**Status:** COMPLETE
**Done:**
- [x] Language toggle in sidebar
- [x] Convert all code blocks to Stata/R/Python tabs
- [x] Add section quizzes (Loops: 1, Project Org: 1, Regression: 1)
- [x] Restructure: Loops & Locals, Project Organization, Regression
- [x] Update focused-session-nav for session2

### 4. Diff-in-Diff Tutorial (Session 3)
**File:** sessions/session3.html
**Status:** COMPLETE
**Done:**
- [x] Language toggle in sidebar
- [x] Convert all code blocks to Stata/R/Python tabs
- [x] Add section quizzes (TWFE: 1, Event Study: 1)
- [x] Update focused-session-nav for session3

### 5. BAC Replication (Worked Example)
**File:** examples/bac-replication.html
**Status:** COMPLETE
**Done:**
- [x] Converted to use layout system
- [x] Added focused sidebar
- [x] Consistent styling with other tutorials

---

## Infrastructure Updates

### Deleted Files
- `teaching/14.33/index.html` - Redundant landing page removed

### Updated Navigation Files
- `_includes/focused-nav.liquid` - Hierarchical nav for reference guide pages, consistent language toggle
- `_includes/focused-session-nav.liquid` - Hierarchical nav for sessions, consistent language toggle
- `_includes/tutorial-nav.liquid` - Fixed "14.33 Home" link

### New Layout Files
- `_includes/layouts/example.html` - Layout for worked examples

---

## Sidebar Structure (Consistent Across All)

```
[Sidebar]
├── Back link (← 14.33 Home) → links to main site #teaching
├── Tutorials header (links to tutorial index)
├── Language Toggle (Stata | R | Python)
│   └── Consistent button style with accent colors
├── Navigation Sections (hierarchical)
│   ├── Section 1
│   │   ├── Subsection 1.1
│   │   ├── Subsection 1.2
│   │   └── ...
│   ├── Section 2
│   │   └── ...
│   └── ...
└── Footer (← All Tutorials)
```

---

## Code Block Standard

Every code block has this structure:
```html
<div class="code-block">
  <div class="code-header">
    <div class="code-tabs">
      <button class="code-tab active" data-lang="stata">Stata</button>
      <button class="code-tab" data-lang="r">R</button>
      <button class="code-tab" data-lang="python">Python</button>
    </div>
    <button class="copy-btn" onclick="copyCode(this)">Copy</button>
  </div>
  <pre class="code-content stata active"><code>...</code></pre>
  <pre class="code-content r"><code>...</code></pre>
  <pre class="code-content python"><code>...</code></pre>
</div>
```

---

## Section Quiz Standard

```html
<div class="section-quiz" style="background: #f8f9fa; border: 2px solid var(--primary); border-radius: 12px; padding: 20px; margin: 24px 0;">
  <h4 style="color: var(--primary); margin-top: 0;">Quick Check: [Topic]</h4>
  <p><strong>Question:</strong> [Question text]</p>
  <div style="display: flex; gap: 12px; flex-wrap: wrap; margin: 12px 0;">
    <button onclick="checkAnswer(this, false)">Wrong Answer</button>
    <button onclick="checkAnswer(this, true)">Correct Answer</button>
  </div>
  <p class="quiz-feedback" style="display: none;"></p>
</div>
```

---

## Color Scheme

- **Stata:** #1a5276 (dark blue)
- **R:** #276dc3 (medium blue)
- **Python:** #e6a817 (gold/yellow)
- **Primary (MIT):** #a31f34 (red)
- **Quiz correct:** #28a745 (green)
- **Quiz incorrect:** #dc3545 (red)

---

## Summary of Changes Made

1. **Deleted redundant 14.33 index page** - Main site now links directly to tutorial index
2. **Updated all "14.33 Home" links** - Now point to main site `#teaching` tab
3. **Consistent language toggle** - Same button style across all pages with accent colors
4. **Hierarchical navigation** - All sidebars use expandable sections with subsections
5. **Multi-language code blocks** - Sessions 2 and 3 now have Stata/R/Python tabs
6. **Inline quizzes** - Added to Sessions 1, 2, and 3 where appropriate
7. **Layout system** - BAC example now uses proper layout with sidebar
8. **Removed "Module X" naming** - Sessions use descriptive section names instead
