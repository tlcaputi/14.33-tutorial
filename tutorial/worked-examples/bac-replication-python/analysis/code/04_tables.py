# 04_tables.py - Publication tables

import pandas as pd
import numpy as np

# Load results from previous scripts
twfe_results = pd.read_csv(ANALYSIS / "output" / "tables" / "twfe_results.csv")
twfe_results = twfe_results.set_index('outcome')
es_hr = pd.read_csv(ANALYSIS / "output" / "tables" / "es_coefficients_hr.csv")
es_nhr = pd.read_csv(ANALYSIS / "output" / "tables" / "es_coefficients_nhr.csv")

# Create formatted Table 2 (main regression results)
def format_coef(coef, se, sig_levels=[0.01, 0.05, 0.10]):
    """Format coefficient with significance stars."""
    z = abs(coef / se) if se > 0 else 0
    stars = ''
    if z > 2.576: stars = '***'
    elif z > 1.96: stars = '**'
    elif z > 1.645: stars = '*'
    return f"{coef:.4f}{stars}", f"({se:.4f})"

# Create LaTeX table
latex_table = r"""
\begin{table}[htbp]
\centering
\caption{Effect of 0.08 BAC Laws on Traffic Fatalities}
\label{tab:main_results}
\begin{threeparttable}
\begin{tabular}{lcc}
\toprule
 & Hit-Run & Non-Hit-Run \\
 & (1) & (2) \\
\midrule
"""

hr_coef, hr_se = format_coef(twfe_results.loc['Hit-Run', 'coefficient'],
                              twfe_results.loc['Hit-Run', 'std_error'])
nhr_coef, nhr_se = format_coef(twfe_results.loc['Non-Hit-Run', 'coefficient'],
                                twfe_results.loc['Non-Hit-Run', 'std_error'])

latex_table += f"Treated & {hr_coef} & {nhr_coef} \\\\\n"
latex_table += f" & {hr_se} & {nhr_se} \\\\\n"
latex_table += r"\addlinespace" + "\n"
latex_table += r"\midrule" + "\n"
latex_table += f"State FE & Yes & Yes \\\\\n"
latex_table += f"Year FE & Yes & Yes \\\\\n"
latex_table += f"Observations & {int(twfe_results.loc['Hit-Run', 'n_obs']):,} & {int(twfe_results.loc['Non-Hit-Run', 'n_obs']):,} \\\\\n"
latex_table += f"R-squared & {twfe_results.loc['Hit-Run', 'r2']:.3f} & {twfe_results.loc['Non-Hit-Run', 'r2']:.3f} \\\\\n"
latex_table += r"""
\bottomrule
\end{tabular}
\begin{tablenotes}
\small
\item \textit{Notes:} Standard errors clustered by state in parentheses. * p<0.10, ** p<0.05, *** p<0.01.
\end{tablenotes}
\end{threeparttable}
\end{table}
"""

# Save LaTeX table
with open(ANALYSIS / "output" / "tables" / "table2_regression.tex", 'w') as f:
    f.write(latex_table)

# Create event study table
es_table = r"""
\begin{table}[htbp]
\centering
\caption{Event Study Coefficients}
\label{tab:event_study}
\begin{threeparttable}
\begin{tabular}{lcc}
\toprule
Event Time & Hit-Run & Non-Hit-Run \\
\midrule
"""

for et in sorted(es_hr['event_time'].unique()):
    hr_row = es_hr[es_hr['event_time'] == et].iloc[0]
    nhr_row = es_nhr[es_nhr['event_time'] == et].iloc[0]

    hr_coef_str, _ = format_coef(hr_row['coefficient'], hr_row['std_error'])
    nhr_coef_str, _ = format_coef(nhr_row['coefficient'], nhr_row['std_error'])

    es_table += f"$t = {int(et):+d}$ & {hr_coef_str} & {nhr_coef_str} \\\\\n"

es_table += r"""
\bottomrule
\end{tabular}
\begin{tablenotes}
\small
\item \textit{Notes:} Reference period is $t=-1$. * p<0.10, ** p<0.05, *** p<0.01.
\end{tablenotes}
\end{threeparttable}
\end{table}
"""

with open(ANALYSIS / "output" / "tables" / "table3_event_study.tex", 'w') as f:
    f.write(es_table)

print("  Created LaTeX tables:")
print("    - table2_regression.tex")
print("    - table3_event_study.tex")
