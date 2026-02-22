#!/usr/bin/env python3
"""Detailed CSS/JS audit for tutorial pages."""
import time
import json
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

BASE = "http://localhost:8184/teaching/14.33/tutorial"
OUT = "/Users/theo/MIT Dropbox/Theodore Caputi/job-market/14.33-tutorial-new/ui-audit"

def main():
    opts = Options()
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--force-device-scale-factor=1")
    opts.set_capability("goog:loggingPrefs", {"browser": "ALL"})

    driver = webdriver.Chrome(options=opts)
    driver.set_window_size(1440, 900)

    pages = [
        "index.html",
        "getting-started.html",
        "basic-regression.html",
        "project-walkthrough.html",
    ]

    for page in pages:
        url = f"{BASE}/{page}"
        driver.get(url)
        time.sleep(2)

        name = page.replace(".html", "")

        # Screenshot top of page
        driver.save_screenshot(f"{OUT}/css_check_{name}_top.png")

        # Scroll down and screenshot
        driver.execute_script("window.scrollTo(0, 600)")
        time.sleep(0.5)
        driver.save_screenshot(f"{OUT}/css_check_{name}_mid.png")

        # Check stylesheet loading
        sheets = driver.execute_script(
            "return Array.from(document.styleSheets).map(function(s) { return s.href || 'inline'; })"
        )
        print(f"\n=== {page} ===")
        print(f"  Stylesheets ({len(sheets)}):")
        for s in sheets:
            print(f"    {s}")

        # Check specific elements
        checks = {
            "sidebar exists": "!!document.querySelector('.sidebar')",
            "tutorial-sidebar exists": "!!document.querySelector('.tutorial-sidebar')",
            "code-block count": "document.querySelectorAll('.code-block').length",
            "code-tab count": "document.querySelectorAll('.code-tab').length",
            "code-tab.active count": "document.querySelectorAll('.code-tab.active').length",
            "key-principle count": "document.querySelectorAll('.key-principle').length",
            "common-mistake count": "document.querySelectorAll('.common-mistake').length",
            "callout elements": "document.querySelectorAll('[class*=\"callout\"]').length",
            "Prism loaded": "typeof Prism !== 'undefined'",
            "copyCode exists": "typeof copyCode !== 'undefined'",
            "switchLanguage exists": "typeof switchLanguage !== 'undefined'",
        }

        for label, js in checks.items():
            try:
                result = driver.execute_script(f"return {js}")
                print(f"  {label}: {result}")
            except Exception as e:
                print(f"  {label}: ERROR - {e}")

        # Check computed styles on key elements
        style_checks = [
            ("body bg", "getComputedStyle(document.body).backgroundColor"),
            ("body font", "getComputedStyle(document.body).fontFamily"),
            ("h1 color", "document.querySelector('h1') ? getComputedStyle(document.querySelector('h1')).color : 'NO H1'"),
            ("h1 font", "document.querySelector('h1') ? getComputedStyle(document.querySelector('h1')).fontFamily : 'NO H1'"),
        ]

        for label, js in style_checks:
            try:
                result = driver.execute_script(f"return {js}")
                print(f"  {label}: {result}")
            except Exception as e:
                print(f"  {label}: ERROR - {e}")

        # Check if key-principle has styling
        kp_style = driver.execute_script("""
            var kp = document.querySelector('.key-principle');
            if (!kp) return 'NO KEY PRINCIPLE FOUND';
            var cs = getComputedStyle(kp);
            return {
                bg: cs.backgroundColor,
                border: cs.border,
                borderLeft: cs.borderLeft,
                padding: cs.padding,
                margin: cs.margin
            };
        """)
        print(f"  key-principle style: {kp_style}")

        # Check if code-block has styling
        cb_style = driver.execute_script("""
            var cb = document.querySelector('.code-block');
            if (!cb) return 'NO CODE BLOCK FOUND';
            var cs = getComputedStyle(cb);
            return {
                bg: cs.backgroundColor,
                border: cs.border,
                borderRadius: cs.borderRadius,
                overflow: cs.overflow
            };
        """)
        print(f"  code-block style: {cb_style}")

        # Check callout styling
        callout_style = driver.execute_script("""
            var co = document.querySelector('[class*="callout"]');
            if (!co) return 'NO CALLOUT FOUND';
            var cs = getComputedStyle(co);
            return {
                className: co.className,
                bg: cs.backgroundColor,
                border: cs.border,
                borderLeft: cs.borderLeft,
                padding: cs.padding
            };
        """)
        print(f"  callout style: {callout_style}")

    # Check browser console
    logs = driver.get_log("browser")
    print("\n=== BROWSER CONSOLE LOGS ===")
    for entry in logs:
        print(f"  [{entry['level']}] {entry['message']}")
    if not logs:
        print("  (no console messages)")

    # Check for failed resource loads
    failed = driver.execute_script("""
        return performance.getEntriesByType('resource')
            .filter(function(r) { return r.responseStatus >= 400; })
            .map(function(r) { return r.name + ' -> ' + r.responseStatus; });
    """)
    print("\n=== FAILED RESOURCES ===")
    if failed:
        for f in failed:
            print(f"  {f}")
    else:
        print("  (none)")

    # Get page source to check what's actually in the HTML
    driver.get(f"{BASE}/getting-started.html")
    time.sleep(1)
    src = driver.page_source
    # Check for style/script references
    import re
    link_tags = re.findall(r'<link[^>]*>', src)
    script_tags = re.findall(r'<script[^>]*>', src)
    print("\n=== HTML HEAD REFERENCES (getting-started) ===")
    print("  Link tags:")
    for t in link_tags:
        print(f"    {t}")
    print("  Script tags:")
    for t in script_tags:
        print(f"    {t}")

    driver.quit()
    print("\nDone!")

if __name__ == "__main__":
    main()
