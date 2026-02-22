#!/usr/bin/env python3
"""Full UI audit: all pages, desktop + mobile, section-by-section screenshots."""
import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

BASE = "http://localhost:8183/teaching/14.33/tutorial"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "audit2")

PAGES = [
    "index.html",
    "getting-started.html",
    "project-organization.html",
    "causal-inference.html",
    "finding-project.html",
    "data-fundamentals.html",
    "descriptive-analysis.html",
    "basic-regression.html",
    "regression.html",
    "causal-methods.html",
    "advanced.html",
    "sessions/session1.html",
    "sessions/session2.html",
    "sessions/session3.html",
    "project-walkthrough.html",
    "examples/bac-replication.html",
    "worked-examples/texting-bans-event-study.html",
    "auxiliary-latex.html",
    "auxiliary-programming-tips.html",
    "publication-quality.html",
]

def screenshot_sections(driver, url, page_name, width, height, out_dir):
    driver.set_window_size(width, height)
    driver.get(url)
    time.sleep(1.5)
    total = driver.execute_script("return document.body.scrollHeight")
    n = max(1, total // height)
    taken = 0
    for i in range(min(n, 10)):
        driver.execute_script(f"window.scrollTo(0, {i * height})")
        time.sleep(0.3)
        path = os.path.join(out_dir, f"{page_name}_s{i+1}.png")
        driver.save_screenshot(path)
        taken += 1
    return taken

def main():
    opts = Options()
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--force-device-scale-factor=1")
    driver = webdriver.Chrome(options=opts)

    total_screenshots = 0
    for vp, w, h in [("desktop", 1440, 900), ("mobile", 375, 812)]:
        d = os.path.join(OUT, vp)
        os.makedirs(d, exist_ok=True)
        for p in PAGES:
            name = p.replace("/", "_").replace(".html", "")
            url = f"{BASE}/{p}"
            n = screenshot_sections(driver, url, name, w, h, d)
            total_screenshots += n
            print(f"  {vp}/{name}: {n} sections")

    driver.quit()
    print(f"\nDone! {total_screenshots} screenshots saved to {OUT}")

if __name__ == "__main__":
    main()
