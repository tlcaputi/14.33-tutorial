"""
Analysis Script 01: Descriptive Statistics Table

Computes means and standard deviations for key variables across three
sample groups: Untreated states, Treated states before policy adoption,
and Treated states after policy adoption.

Output: analysis/output/tables/descriptive_table.csv
        analysis/output/tables/descriptive_table.tex
"""

import os
import pandas as pd
import numpy as np
from pathlib import Path

ROOT = Path(os.environ.get("PROJECT_ROOT", Path(__file__).parent.parent.parent))

# ─── Paths ────────────────────────────────────────────────────────────────────
input_file  = ROOT / "build/output/analysis_panel.csv"
output_file = ROOT / "analysis/output/tables/descriptive_table.csv"
output_tex  = ROOT / "analysis/output/tables/descriptive_table.tex"

print("=" * 60)
print("SCRIPT 01: DESCRIPTIVE STATISTICS TABLE")
print("=" * 60)

# ─── Load data ────────────────────────────────────────────────────────────────
print(f"\nReading: {input_file.relative_to(ROOT)}")
df = pd.read_csv(input_file)
print(f"Loaded {len(df):,} state-year observations")

# ─── Variables to summarize ───────────────────────────────────────────────────
# Choose a set of outcome and covariate variables that appear in the panel.
variables = [
    "fatal_crashes",
    "serious_crashes",
    "total_crashes",
    "fatal_share",
    "population",
    "median_income",
    "pct_urban",
]

# ─── Create group labels ──────────────────────────────────────────────────────
# post_treated = 1 only for treated states in post-adoption years.
# We reconstruct the three mutually exclusive groups from the raw columns so
# that this script is self-contained and transparent.

df["_group"] = "Untreated"
treated_mask = df["policy_adopted"] == 1
df.loc[treated_mask & (df["year"] >= df["adoption_year"]),  "_group"] = "Treated After"
df.loc[treated_mask & (df["year"] <  df["adoption_year"]),  "_group"] = "Treated Before"

group_order = ["Treated After", "Treated Before", "Untreated"]

for g in group_order:
    print(f"  {g}: {(df['_group'] == g).sum():,} obs")

# ─── Compute mean and SD for each group ───────────────────────────────────────
def group_stats(data, var):
    """Return mean and std for each group as a Series."""
    return data.groupby("_group")[var].agg(["mean", "std"])

rows = []
for var in variables:
    stats = group_stats(df, var)
    row = {"Variable": var}
    for g in group_order:
        row[f"{g}_mean"] = stats.loc[g, "mean"] if g in stats.index else np.nan
        row[f"{g}_sd"]   = stats.loc[g, "std"]  if g in stats.index else np.nan
    rows.append(row)

table = pd.DataFrame(rows)

# ─── Print formatted table ────────────────────────────────────────────────────
header_fmt = f"{'Variable':<20}" + "".join(
    f"  {'  ' + g:>22}" for g in group_order
)
sub_header = f"{'':20}" + "".join(
    f"  {'Mean':>11}  {'SD':>9}" for _ in group_order
)
divider = "=" * (20 + 24 * len(group_order))

print(f"\n{divider}")
print("DESCRIPTIVE STATISTICS")
print(divider)
print(header_fmt)
print(sub_header)
print("-" * len(divider))

for _, row in table.iterrows():
    line = f"{row['Variable']:<20}"
    for g in group_order:
        m = row[f"{g}_mean"]
        s = row[f"{g}_sd"]
        line += f"  {m:>11.2f}  {s:>9.2f}"
    print(line)

# Observation counts per group
print("-" * len(divider))
n_line = f"{'Observations':<20}"
for g in group_order:
    n = int((df["_group"] == g).sum())
    n_line += f"  {n:>11,}  {'':>9}"
print(n_line)
print(divider)

# ─── Save CSV output ─────────────────────────────────────────────────────────
output_file.parent.mkdir(parents=True, exist_ok=True)
table.to_csv(output_file, index=False)

# ─── Save LaTeX output ──────────────────────────────────────────────────────
pretty_names = {
    "fatal_crashes": "Fatal Crashes",
    "serious_crashes": "Serious Crashes",
    "total_crashes": "Total Crashes",
    "fatal_share": "Fatal Share",
    "population": "Population",
    "median_income": "Median Income",
    "pct_urban": "Pct.\\ Urban",
}

lines = []
lines.append(r"\begin{tabular}{l" + "cc" * len(group_order) + "}")
lines.append(r"\toprule")
# Group headers
hdr = " "
for g in group_order:
    hdr += rf" & \multicolumn{{2}}{{c}}{{{g}}}"
hdr += r" \\"
lines.append(hdr)
for i, g in enumerate(group_order):
    col_start = 2 + i * 2
    col_end = col_start + 1
    lines.append(rf"\cmidrule(lr){{{col_start}-{col_end}}}")
# Sub-header
sub = " "
for _ in group_order:
    sub += r" & Mean & SD"
sub += r" \\"
lines.append(sub)
lines.append(r"\midrule")
# Data rows
for _, row in table.iterrows():
    label = pretty_names.get(row["Variable"], row["Variable"])
    line = label
    for g in group_order:
        m = row[f"{g}_mean"]
        s = row[f"{g}_sd"]
        line += f" & {m:,.2f} & {s:,.2f}"
    line += r" \\"
    lines.append(line)
lines.append(r"\midrule")
# Observation counts
obs_line = "Observations"
for g in group_order:
    n = int((df["_group"] == g).sum())
    obs_line += f" & \\multicolumn{{2}}{{c}}{{{n:,}}}"
obs_line += r" \\"
lines.append(obs_line)
lines.append(r"\bottomrule")
lines.append(r"\end{tabular}")

with open(output_tex, "w") as f:
    f.write("\n".join(lines) + "\n")

print(f"\nSaved: {output_file.relative_to(ROOT)}")
print(f"Saved: {output_tex.relative_to(ROOT)}")
print(f"  Variables: {len(variables)}")
print(f"  Groups: {group_order}")
