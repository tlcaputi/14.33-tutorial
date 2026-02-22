"""Main script — runs all build and analysis scripts in order."""
import os, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).parent.resolve()
os.environ["PROJECT_ROOT"] = str(ROOT)

scripts = [
    "build/code/01_filter_crashes.py",
    "build/code/02_collapse_crashes.py",
    "build/code/03_reshape_crashes.py",
    "build/code/04_append_demographics.py",
    "build/code/05_collapse_demographics.py",
    "build/code/06_merge_datasets.py",
    "analysis/code/01_descriptive_table.py",
    "analysis/code/02_dd_regression.py",
    "analysis/code/03_event_study.py",
    "analysis/code/04_dd_table.py",
    "analysis/code/05_iv.py",
    "analysis/code/06_rd.py",
]

for i, script in enumerate(scripts, 1):
    print(f"\n[{i}/{len(scripts)}] Running: {script}")
    result = subprocess.run([sys.executable, str(ROOT / script)], cwd=str(ROOT))
    if result.returncode != 0:
        print(f"ERROR: {script} failed")
        sys.exit(1)

print("\nAll scripts completed successfully.")
