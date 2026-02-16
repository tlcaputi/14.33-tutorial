"""
Main script for econometric analysis project walkthrough.

This script runs all build and analysis scripts in the correct order.
Sets the project root directory for all subsequent scripts.
"""

import os
import subprocess
import sys
from pathlib import Path

# Set project root directory
ROOT = Path(__file__).parent.resolve()

# Print header
print("=" * 80)
print("ECONOMETRIC ANALYSIS PROJECT - PYTHON WALKTHROUGH")
print("=" * 80)
print(f"\nProject root: {ROOT}\n")

# Define scripts to run in order
scripts = [
    # Build scripts
    "build/code/01_collapse_crashes.py",
    "build/code/02_merge_datasets.py",

    # Analysis scripts
    "analysis/code/01_descriptive_table.py",
    "analysis/code/02_dd_regression.py",
    "analysis/code/03_event_study.py",
    "analysis/code/04_iv.py",
    "analysis/code/05_rd.py",
]

# Run each script
for i, script in enumerate(scripts, 1):
    script_path = ROOT / script

    print(f"\n{'=' * 80}")
    print(f"[{i}/{len(scripts)}] Running: {script}")
    print(f"{'=' * 80}\n")

    # Run script using subprocess
    result = subprocess.run(
        [sys.executable, str(script_path)],
        cwd=str(ROOT),
        env={**dict(os.environ), "PROJECT_ROOT": str(ROOT)},
        capture_output=False
    )

    # Check if script succeeded
    if result.returncode != 0:
        print(f"\n*** ERROR: Script {script} failed with return code {result.returncode} ***")
        sys.exit(1)

    print(f"\n✓ Completed: {script}")

print("\n" + "=" * 80)
print("ALL SCRIPTS COMPLETED SUCCESSFULLY")
print("=" * 80)
