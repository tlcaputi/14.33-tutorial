#!/usr/bin/env python3
"""Full UI audit after CSS/JS fix."""
import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

BASE = "http://localhost:8184/teaching/14.33/tutorial"
OUT = "/Users/theo/MIT Dropbox/Theodore Caputi/job-market/14.33-tutorial-new/ui-audit/post_fix"

PAGES = [
    "index.html",
    "getting-started.html",
    "basic-regression.html",
    "project-walkthrough.html",
    "causal-methods.html",
    "sessions/session1.html",
    "examples/bac-replication.html",
]

def main():
    os.makedirs(os.path.join(OUT, "desktop"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "mobile"), exist_ok=True)

    opts = Options()
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--force-device-scale-factor=1")
    driver = webdriver.Chrome(options=opts)

    for page in PAGES:
        name = page.replace("/", "_").replace(".html", "")
        url = f"{BASE}/{page}"

        # Desktop
        driver.set_window_size(1440, 900)
        driver.get(url)
        time.sleep(2)
        driver.save_screenshot(os.path.join(OUT, "desktop", f"{name}_top.png"))
        driver.execute_script("window.scrollTo(0, 500)")
        time.sleep(0.3)
        driver.save_screenshot(os.path.join(OUT, "desktop", f"{name}_mid.png"))
        driver.execute_script("window.scrollTo(0, 1200)")
        time.sleep(0.3)
        driver.save_screenshot(os.path.join(OUT, "desktop", f"{name}_bot.png"))
        print(f"  desktop/{name}: 3 screenshots")

        # Mobile
        driver.set_window_size(375, 812)
        driver.get(url)
        time.sleep(2)
        driver.save_screenshot(os.path.join(OUT, "mobile", f"{name}_top.png"))
        driver.execute_script("window.scrollTo(0, 500)")
        time.sleep(0.3)
        driver.save_screenshot(os.path.join(OUT, "mobile", f"{name}_mid.png"))
        print(f"  mobile/{name}: 2 screenshots")

    driver.quit()
    print(f"\nDone! Screenshots in {OUT}")

if __name__ == "__main__":
    main()
