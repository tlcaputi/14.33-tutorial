# 01_event_study.py — TWFE and event study regressions
# =============================================================================
# 1. Simple TWFE: ln_fatalities ~ treated + controls | state + year
# 2. Event study: bin event_time to [-6, +6], create dummies, run regression
# 3. Export coefficients + 95% CIs to CSV
# =============================================================================

import pandas as pd
import numpy as np
from linearmodels.panel import PanelOLS

# ── Load data ────────────────────────────────────────────────
analysis_data = pd.read_parquet(BUILD / "output" / "analysis_data.parquet")
analysis_data["ln_fatalities"] = np.log(analysis_data["fatalities"])

# ── Simple TWFE ──────────────────────────────────────────────
analysis_data["treated_int"] = analysis_data["treated"].astype(int)

panel = analysis_data.set_index(["state", "year"])

# Build formula with available controls
controls = ["treated_int"]
if "unemployment" in analysis_data.columns and analysis_data["unemployment"].notna().sum() > 0:
    controls.append("unemployment")
if "income" in analysis_data.columns and analysis_data["income"].notna().sum() > 0:
    controls.append("income")

formula_twfe = "ln_fatalities ~ " + " + ".join(controls) + " + EntityEffects + TimeEffects"
print(f"    TWFE formula: {formula_twfe}")

twfe_model = PanelOLS.from_formula(formula_twfe, data=panel, drop_absorbed=True)
twfe_results = twfe_model.fit(cov_type="clustered", cluster_entity=True)

print(f"    TWFE coefficient on treated: {twfe_results.params['treated_int']:.4f} "
      f"(SE: {twfe_results.std_errors['treated_int']:.4f})")

# ── Event study ──────────────────────────────────────────────
# Bin event time to [-6, +6]
analysis_data["event_time_binned"] = np.where(
    analysis_data["event_time"] == -1000, -1000,
    np.clip(analysis_data["event_time"], -6, 6)
)

# Create dummies (exclude t=-1 as reference, never-treated get 0)
et_cols = []
for k in range(-6, 7):
    if k == -1:
        continue
    label = f"et_m{abs(k)}" if k < 0 else f"et_p{k}"
    analysis_data[label] = ((analysis_data["event_time_binned"] == k) &
                            (analysis_data["event_time"] != -1000)).astype(int)
    et_cols.append(label)

# Re-index for panel
panel_es = analysis_data.set_index(["state", "year"])

# Build event study formula
rhs = et_cols.copy()
if "unemployment" in analysis_data.columns and analysis_data["unemployment"].notna().sum() > 0:
    rhs.append("unemployment")
if "income" in analysis_data.columns and analysis_data["income"].notna().sum() > 0:
    rhs.append("income")

formula_es = "ln_fatalities ~ " + " + ".join(rhs) + " + EntityEffects + TimeEffects"
print(f"    Event study formula: {formula_es[:80]}...")

es_model = PanelOLS.from_formula(formula_es, data=panel_es, drop_absorbed=True)
es_results = es_model.fit(cov_type="clustered", cluster_entity=True)

# ── Export coefficients ──────────────────────────────────────
event_times_map = {}
for k in range(-6, 7):
    if k == -1:
        continue
    label = f"et_m{abs(k)}" if k < 0 else f"et_p{k}"
    event_times_map[label] = k

ci = es_results.conf_int()
coef_rows = []
for col in et_cols:
    coef_rows.append({
        "event_time": event_times_map[col],
        "coefficient": es_results.params[col],
        "std_error": es_results.std_errors[col],
        "ci_lower": ci.loc[col, "lower"],
        "ci_upper": ci.loc[col, "upper"],
    })

coef_df = pd.DataFrame(coef_rows).sort_values("event_time")

out_path = ANALYSIS / "output" / "event_study_coefs.csv"
coef_df.to_csv(out_path, index=False)
print(f"    Saved coefficients to {out_path}")

# Print results table
print("\n    Event Study Coefficients:")
print(f"    {'Time':>6}  {'Coef':>10}  {'SE':>10}  {'CI Lower':>10}  {'CI Upper':>10}")
print("    " + "-" * 52)
for _, row in coef_df.iterrows():
    print(f"    {int(row['event_time']):>6}  {row['coefficient']:>10.4f}  "
          f"{row['std_error']:>10.4f}  {row['ci_lower']:>10.4f}  {row['ci_upper']:>10.4f}")
