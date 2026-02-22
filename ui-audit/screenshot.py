#!/usr/bin/env python3
"""Full-page Selenium screenshots for tutorial UI audit."""
import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service

BASE = "http://localhost:8181/teaching/14.33/tutorial"
OUT = os.path.dirname(os.path.abspath(__file__))

PAGES = [
    ("index", "index.html"),
    ("getting-started", "getting-started.html"),
    ("project-organization", "project-organization.html"),
    ("causal-inference", "causal-inference.html"),
    ("finding-project", "finding-project.html"),
    ("data-fundamentals", "data-fundamentals.html"),
    ("descriptive-analysis", "descriptive-analysis.html"),
    ("basic-regression", "basic-regression.html"),
    ("causal-methods", "causal-methods.html"),
    ("advanced", "advanced.html"),
    ("session1", "sessions/session1.html"),
    ("session2", "sessions/session2.html"),
    ("session3", "sessions/session3.html"),
    ("project-walkthrough", "project-walkthrough.html"),
    ("bac-replication", "examples/bac-replication.html"),
    ("texting-bans", "worked-examples/texting-bans-event-study.html"),
    ("auxiliary-latex", "auxiliary-latex.html"),
    ("auxiliary-programming-tips", "auxiliary-programming-tips.html"),
    ("publication-quality", "publication-quality.html"),
]

VIEWPORTS = [
    ("desktop", 1440, 900),
    ("mobile", 375, 812),
]

def take_full_page_screenshot(driver, path):
    """Take full-page screenshot by setting window to full document height."""
    total_height = driver.execute_script("return document.body.scrollHeight")
    viewport_width = driver.execute_script("return window.innerWidth")
    driver.set_window_size(viewport_width, total_height + 200)
    time.sleep(0.5)
    driver.save_screenshot(path)

def main():
    opts = Options()
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--force-device-scale-factor=1")

    driver = webdriver.Chrome(options=opts)

    for vp_name, width, height in VIEWPORTS:
        vp_dir = os.path.join(OUT, vp_name)
        os.makedirs(vp_dir, exist_ok=True)

        for page_name, page_path in PAGES:
            url = f"{BASE}/{page_path}"
            driver.set_window_size(width, height)
            driver.get(url)
            time.sleep(1)  # Wait for rendering

            out_path = os.path.join(vp_dir, f"{page_name}.png")
            take_full_page_screenshot(driver, out_path)
            fsize = os.path.getsize(out_path) / 1024
            print(f"  {vp_name}/{page_name}.png ({fsize:.0f} KB)")

    driver.quit()
    print("\nDone! Screenshots saved to:", OUT)

if __name__ == "__main__":
    main()
