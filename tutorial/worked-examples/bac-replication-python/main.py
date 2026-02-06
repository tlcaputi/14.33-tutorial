#!/usr/bin/env python3
"""
==============================================================================
    BAC Replication Package: French & Gumus (2024)
    "Hit-and-Run or Hit-and-Stay? Unintended Effects of a Stricter BAC Limit"

    This is a FULLY FUNCTIONAL replication package that:
    1. Downloads all FARS data (1982-2008) from NHTSA
    2. Downloads economic data from FRED
    3. Creates all policy control variables
    4. Runs TWFE event study and DiD regressions
    5. Produces all tables and figures

    Run time: ~15-20 minutes (mostly data download)
==============================================================================
"""

from pathlib import Path
import os

# ============ CHANGE THIS PATH TO YOUR PROJECT FOLDER ============
ROOT = Path(__file__).parent.resolve()
# =================================================================

# Define paths (don't change these)
BUILD = ROOT / "build"
ANALYSIS = ROOT / "analysis"

# Make paths available globally
os.chdir(ROOT)

print("="*70)
print("BAC Replication Package - French & Gumus (2024)")
print("="*70)
print(f"Project root: {ROOT}")
print()

# Run build scripts in order
print("PHASE 1: Building data...")
print("-"*70)

print("\n[1/3] Downloading FARS data (1982-2008)...")
exec(open(BUILD / "code" / "01_download_fars.py").read())

print("\n[2/3] Cleaning FARS data...")
exec(open(BUILD / "code" / "02_clean_fars.py").read())

print("\n[3/3] Merging control variables...")
exec(open(BUILD / "code" / "03_merge_controls.py").read())

# Run analysis scripts
print("\n" + "="*70)
print("PHASE 2: Running analysis...")
print("-"*70)

print("\n[1/5] Summary statistics...")
exec(open(ANALYSIS / "code" / "01_summary_stats.py").read())

print("\n[2/5] TWFE regression...")
exec(open(ANALYSIS / "code" / "02_twfe_regression.py").read())

print("\n[3/5] Event study...")
exec(open(ANALYSIS / "code" / "03_event_study.py").read())

print("\n[4/5] Tables...")
exec(open(ANALYSIS / "code" / "04_tables.py").read())

print("\n[5/5] Figures...")
exec(open(ANALYSIS / "code" / "05_figures.py").read())

print("\n" + "="*70)
print("DONE! All results saved to:")
print(f"  Tables:  {ANALYSIS / 'output' / 'tables'}")
print(f"  Figures: {ANALYSIS / 'output' / 'figures'}")
print("="*70)
