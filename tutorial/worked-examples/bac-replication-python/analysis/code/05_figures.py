# 05_figures.py - Publication figures

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Load event study coefficients
coef_hr = pd.read_csv(ANALYSIS / "output" / "tables" / "es_coefficients_hr.csv")
coef_nhr = pd.read_csv(ANALYSIS / "output" / "tables" / "es_coefficients_nhr.csv")

# Ensure output directory exists
(ANALYSIS / "output" / "figures").mkdir(parents=True, exist_ok=True)

# =============================================================================
# Figure 1: Hit-and-Run Event Study
# =============================================================================
fig, ax = plt.subplots(figsize=(10, 6))

coef_hr = coef_hr.sort_values('event_time')

# Plot with confidence bands
ax.fill_between(coef_hr['event_time'], coef_hr['ci_lower'], coef_hr['ci_upper'],
                alpha=0.3, color='steelblue')
ax.plot(coef_hr['event_time'], coef_hr['coefficient'], 'o-',
        color='steelblue', markersize=6, linewidth=2)

ax.axhline(y=0, color='gray', linestyle='--', linewidth=0.8)
ax.axvline(x=-0.5, color='red', linestyle='--', linewidth=0.8, alpha=0.7)

ax.set_xlabel('Years Since 0.08 BAC Law Adoption', fontsize=12)
ax.set_ylabel('Coefficient (log HR fatalities)', fontsize=12)
ax.set_title('Event Study: Hit-and-Run Fatalities', fontsize=14)

ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(ANALYSIS / "output" / "figures" / "event_study_hr.png", dpi=300, bbox_inches='tight')
plt.close()

# =============================================================================
# Figure 2: Non-Hit-and-Run Event Study (placebo)
# =============================================================================
fig, ax = plt.subplots(figsize=(10, 6))

coef_nhr = coef_nhr.sort_values('event_time')

ax.fill_between(coef_nhr['event_time'], coef_nhr['ci_lower'], coef_nhr['ci_upper'],
                alpha=0.3, color='darkgreen')
ax.plot(coef_nhr['event_time'], coef_nhr['coefficient'], 'o-',
        color='darkgreen', markersize=6, linewidth=2)

ax.axhline(y=0, color='gray', linestyle='--', linewidth=0.8)
ax.axvline(x=-0.5, color='red', linestyle='--', linewidth=0.8, alpha=0.7)

ax.set_xlabel('Years Since 0.08 BAC Law Adoption', fontsize=12)
ax.set_ylabel('Coefficient (log non-HR fatalities)', fontsize=12)
ax.set_title('Event Study: Non-Hit-and-Run Fatalities (Placebo)', fontsize=14)

ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(ANALYSIS / "output" / "figures" / "event_study_nhr.png", dpi=300, bbox_inches='tight')
plt.close()

# =============================================================================
# Figure 3: Combined Event Study (both outcomes)
# =============================================================================
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

# Hit-Run
ax1.fill_between(coef_hr['event_time'], coef_hr['ci_lower'], coef_hr['ci_upper'],
                 alpha=0.3, color='steelblue')
ax1.plot(coef_hr['event_time'], coef_hr['coefficient'], 'o-',
         color='steelblue', markersize=6, linewidth=2)
ax1.axhline(y=0, color='gray', linestyle='--', linewidth=0.8)
ax1.axvline(x=-0.5, color='red', linestyle='--', linewidth=0.8, alpha=0.7)
ax1.set_xlabel('Years Since Law Adoption', fontsize=11)
ax1.set_ylabel('Coefficient', fontsize=11)
ax1.set_title('(A) Hit-and-Run Fatalities', fontsize=12)
ax1.spines['top'].set_visible(False)
ax1.spines['right'].set_visible(False)
ax1.grid(True, alpha=0.3)

# Non-Hit-Run
ax2.fill_between(coef_nhr['event_time'], coef_nhr['ci_lower'], coef_nhr['ci_upper'],
                 alpha=0.3, color='darkgreen')
ax2.plot(coef_nhr['event_time'], coef_nhr['coefficient'], 'o-',
         color='darkgreen', markersize=6, linewidth=2)
ax2.axhline(y=0, color='gray', linestyle='--', linewidth=0.8)
ax2.axvline(x=-0.5, color='red', linestyle='--', linewidth=0.8, alpha=0.7)
ax2.set_xlabel('Years Since Law Adoption', fontsize=11)
ax2.set_ylabel('Coefficient', fontsize=11)
ax2.set_title('(B) Non-Hit-and-Run Fatalities', fontsize=12)
ax2.spines['top'].set_visible(False)
ax2.spines['right'].set_visible(False)
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(ANALYSIS / "output" / "figures" / "event_study_combined.png", dpi=300, bbox_inches='tight')
plt.close()

print("  Created figures:")
print("    - event_study_hr.png")
print("    - event_study_nhr.png")
print("    - event_study_combined.png")
