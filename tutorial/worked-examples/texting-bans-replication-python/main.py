#!/usr/bin/env python3
"""
Replication Package: Texting Bans and Traffic Fatalities
========================================================
Event study analysis of state texting-while-driving bans
using FARS data (2007-2022).

Requirements:
    pip install pandas numpy requests linearmodels matplotlib

Usage:
    python main.py
"""

from pathlib import Path
import time

ROOT = Path(__file__).parent.resolve()
BUILD = ROOT / "build"
ANALYSIS = ROOT / "analysis"

# Create output directories
(BUILD / "output").mkdir(parents=True, exist_ok=True)
(ANALYSIS / "output").mkdir(parents=True, exist_ok=True)

print("=" * 60)
print("Texting Bans and Traffic Fatalities — Replication Package")
print("=" * 60)

# ── Phase 1: Build data ──────────────────────────────────────
build_scripts = [
    "01_download_fars.py",
    "02_clean_fars.py",
    "03_merge_controls.py",
]

print("\n── Phase 1: Building data ──")
for i, script in enumerate(build_scripts, 1):
    path = BUILD / "code" / script
    print(f"\n  [{i}/{len(build_scripts)}] Running {script}...")
    t0 = time.time()
    exec(open(path).read())
    print(f"  Done ({time.time() - t0:.1f}s)")

# ── Phase 2: Analysis ────────────────────────────────────────
analysis_scripts = [
    "01_event_study.py",
    "02_figures.py",
]

print("\n── Phase 2: Running analysis ──")
for i, script in enumerate(analysis_scripts, 1):
    path = ANALYSIS / "code" / script
    print(f"\n  [{i}/{len(analysis_scripts)}] Running {script}...")
    t0 = time.time()
    exec(open(path).read())
    print(f"  Done ({time.time() - t0:.1f}s)")

# ── Summary ───────────────────────────────────────────────────
print("\n" + "=" * 60)
print("Complete! Output files:")
print(f"  {ANALYSIS / 'output' / 'event_study_coefs.csv'}")
print(f"  {ANALYSIS / 'output' / 'event_study.png'}")
print("=" * 60)
