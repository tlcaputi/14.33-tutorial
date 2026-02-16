import numpy as np
import matplotlib.pyplot as plt
import matplotlib

# --- Generate fake event study data ---
np.random.seed(42)
periods = np.arange(-5, 6)
coefs = np.array([-0.1, 0.05, -0.15, 0.08, 0.02, 0, 0.8, 1.5, 2.1, 2.4, 2.6])
ses = np.array([0.35, 0.30, 0.28, 0.25, 0.20, 0, 0.22, 0.25, 0.30, 0.35, 0.40])
ci_lo = coefs - 1.96 * ses
ci_hi = coefs + 1.96 * ses


# ===== STEP 1: Default matplotlib plot =====
fig, ax = plt.subplots()
ax.plot(periods, coefs, marker='o')
ax.axhline(0, color='black')
ax.set_title('Event Study')
ax.set_xlabel('period')
ax.set_ylabel('estimate')
fig.savefig('fig_step1_default_py.png', dpi=150)
plt.close()


# ===== STEP 2: Add confidence intervals =====
fig, ax = plt.subplots(figsize=(8, 6))
ax.errorbar(periods, coefs, yerr=1.96*ses, fmt='o-', capsize=3)
ax.axhline(0, color='black', linewidth=0.8)
ax.set_title('Event Study')
ax.set_xlabel('period')
ax.set_ylabel('estimate')
fig.savefig('fig_step2_with_ci_py.png', dpi=150)
plt.close()


# ===== STEP 3: Better styling =====
fig, ax = plt.subplots(figsize=(8, 6))
ax.axhline(0, color='gray', linewidth=0.5, linestyle='--')
ax.axvline(-0.5, color='gray', linewidth=0.5, linestyle='--')
ax.errorbar(periods, coefs, yerr=1.96*ses, fmt='o-', color='steelblue',
            capsize=3, markersize=6, linewidth=1.2)
ax.set_xlabel('Years Relative to Policy Adoption', fontsize=11)
ax.set_ylabel('Estimated Effect', fontsize=11)
ax.set_title('Effect of Policy on Fatality Rate', fontsize=13)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.set_xticks(periods)
fig.tight_layout()
fig.savefig('fig_step3_themed_py.png', dpi=150)
plt.close()


# ===== STEP 4: Publication quality =====
fig, ax = plt.subplots(figsize=(8, 5.5))

# Reference lines
ax.axhline(0, color='#b0b0b0', linewidth=0.4)
ax.axvline(-0.5, color='#b0b0b0', linewidth=0.4, linestyle='--')

# Confidence band
ax.fill_between(periods, ci_lo, ci_hi, alpha=0.15, color='#2c5f8a', linewidth=0)

# Point estimates
ax.plot(periods, coefs, color='#2c5f8a', linewidth=0.9, zorder=3)
ax.scatter(periods, coefs, color='#2c5f8a', s=25, zorder=4)

# Annotations
ax.text(-3, -0.7, 'Pre-treatment', color='gray', fontsize=10, fontstyle='italic')
ax.text(3, 3.0, 'Post-treatment', color='gray', fontsize=10, fontstyle='italic')

# Axis formatting
ax.set_xlabel('Years Relative to Policy Adoption', fontsize=11, labelpad=10)
ax.set_ylabel('Estimated Effect on Fatality Rate', fontsize=11, labelpad=10)
ax.set_xticks(periods)
ax.tick_params(colors='#4a4a4a', labelsize=10)

# Remove clutter
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_color('#d0d0d0')
ax.spines['bottom'].set_color('#d0d0d0')
ax.yaxis.grid(True, color='#e8e8e8', linewidth=0.3)
ax.xaxis.grid(False)
ax.set_axisbelow(True)

fig.tight_layout(pad=1.5)
fig.savefig('fig_step4_publication_py.png', dpi=300)
plt.close()

print('All Python figures saved.')
