"""Main script — runs all build and analysis scripts in order.

Usage: cd into the pkg-python/ folder, then run:
    python main.py
"""
import os, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).parent.resolve()
os.environ["PROJECT_ROOT"] = str(ROOT)

# Create output directories (zip may strip empty folders)
(ROOT / "build" / "output").mkdir(parents=True, exist_ok=True)
(ROOT / "analysis" / "output" / "tables").mkdir(parents=True, exist_ok=True)
(ROOT / "analysis" / "output" / "figures").mkdir(parents=True, exist_ok=True)

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

# ─── Compile LaTeX tables to PDF ─────────────────────────────────────────────
import shutil

tables_dir = ROOT / "analysis" / "output" / "tables"
tex_files = sorted(tables_dir.glob("*.tex"))

if tex_files and shutil.which("pdflatex"):
    print(f"\n{'='*60}")
    print("COMPILING LATEX TABLES TO PDF")
    print(f"{'='*60}")
    for tex_file in tex_files:
        wrapper = tex_file.with_suffix(".compile.tex")
        wrapper.write_text(
            "\\documentclass[border=10pt]{standalone}\n"
            "\\usepackage{booktabs,amsmath,threeparttable,makecell}\n"
            "\\begin{document}\n"
            f"\\input{{{tex_file.name}}}\n"
            "\\end{document}\n"
        )
        result = subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", wrapper.name],
            cwd=str(tables_dir),
            capture_output=True,
        )
        pdf_out = wrapper.with_suffix(".pdf")
        target = tex_file.with_suffix(".pdf")
        if pdf_out.exists():
            pdf_out.rename(target)
            print(f"  Compiled: {target.name}")
        else:
            print(f"  WARNING: Failed to compile {tex_file.name}")
        # Clean up auxiliary files
        for ext in [".compile.tex", ".compile.aux", ".compile.log"]:
            f = tables_dir / (tex_file.stem + ext)
            if f.exists():
                f.unlink()
elif not tex_files:
    print("\nNo .tex files found — skipping PDF compilation.")
else:
    print("\npdflatex not found — skipping PDF compilation.")
    print("Install LaTeX to compile tables: https://www.tug.org/texlive/")

print("\nAll scripts completed successfully.")
