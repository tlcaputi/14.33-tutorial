#!/usr/bin/env python3
"""Section-by-section screenshots for UI audit - readable sizes."""
import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

BASE = "http://localhost:8181/teaching/14.33/tutorial"
OUT = os.path.dirname(os.path.abspath(__file__))

# Key pages to audit with multiple scroll positions
PAGES = [
    "getting-started.html",
    "project-organization.html",
    "data-fundamentals.html",
    "basic-regression.html",
    "regression.html",
    "causal-methods.html",
    "causal-inference.html",
    "descriptive-analysis.html",
    "advanced.html",
    "finding-project.html",
    "project-walkthrough.html",
    "sessions/session1.html",
    "sessions/session2.html",
    "sessions/session3.html",
    "examples/bac-replication.html",
    "worked-examples/texting-bans-event-study.html",
    "auxiliary-latex.html",
    "auxiliary-programming-tips.html",
    "publication-quality.html",
]

def screenshot_sections(driver, url, page_name, viewport, out_dir):
    width, height = viewport
    driver.set_window_size(width, height)
    driver.get(url)
    time.sleep(1)

    total_height = driver.execute_script("return document.body.scrollHeight")
    sections = max(1, total_height // height)

    for i in range(min(sections, 8)):  # Max 8 screenshots per page
        scroll_y = i * height
        driver.execute_script(f"window.scrollTo(0, {scroll_y})")
        time.sleep(0.3)
        fname = f"{page_name}_s{i+1}.png"
        path = os.path.join(out_dir, fname)
        driver.save_screenshot(path)
        fsize = os.path.getsize(path) / 1024
        print(f"  {fname} ({fsize:.0f} KB)")

def main():
    opts = Options()
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--force-device-scale-factor=1")
    driver = webdriver.Chrome(options=opts)

    for vp_name, width, height in [("desk", 1440, 900), ("mob", 375, 812)]:
        vp_dir = os.path.join(OUT, f"sections_{vp_name}")
        os.makedirs(vp_dir, exist_ok=True)
        for page_path in PAGES:
            page_name = page_path.replace("/", "_").replace(".html", "")
            url = f"{BASE}/{page_path}"
            print(f"\n{vp_name}: {page_name}")
            screenshot_sections(driver, url, page_name, (width, height), vp_dir)

    driver.quit()
    print("\nDone!")

if __name__ == "__main__":
    main()
