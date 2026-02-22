#!/usr/bin/env python3
"""Check if CSS/JS are loading and capture console errors."""
import time
import json
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

BASE = "http://localhost:8184/teaching/14.33/tutorial"

def main():
    opts = Options()
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--force-device-scale-factor=1")
    opts.set_capability("goog:loggingPrefs", {"browser": "ALL", "performance": "ALL"})

    driver = webdriver.Chrome(options=opts)
    driver.set_window_size(1440, 900)

    url = f"{BASE}/getting-started.html"
    driver.get(url)
    time.sleep(2)

    # Check console errors
    logs = driver.get_log("browser")
    print("=== BROWSER CONSOLE LOGS ===")
    for entry in logs:
        print(f"  [{entry['level']}] {entry['message']}")
    if not logs:
        print("  (no console messages)")

    # Check if CSS is loaded by testing computed styles
    print("\n=== CSS CHECK ===")
    checks = [
        ("sidebar bg color", "document.querySelector('.tutorial-sidebar') ? getComputedStyle(document.querySelector('.tutorial-sidebar')).backgroundColor : 'NO SIDEBAR'"),
        ("code-block exists", "document.querySelectorAll('.code-block').length"),
        ("code-tab active bg", "document.querySelector('.code-tab.active') ? getComputedStyle(document.querySelector('.code-tab.active')).backgroundColor : 'NO ACTIVE TAB'"),
        ("key-principle bg", "document.querySelector('.key-principle') ? getComputedStyle(document.querySelector('.key-principle')).backgroundColor : 'NO KEY PRINCIPLE'"),
        ("body font-family", "getComputedStyle(document.body).fontFamily"),
        ("h1 font-family", "document.querySelector('h1') ? getComputedStyle(document.querySelector('h1')).fontFamily : 'NO H1'"),
    ]
    for name, js in checks:
        result = driver.execute_script(f"return {js}")
        print(f"  {name}: {result}")

    # Check if JS is loaded by testing language switcher
    print("\n=== JS CHECK ===")
    js_checks = [
        ("copyCode function exists", "typeof copyCode"),
        ("lang toggle buttons", "document.querySelectorAll('.lang-toggle button').length"),
        ("code tabs clickable", "document.querySelectorAll('.code-tab').length"),
        ("Prism loaded", "typeof Prism"),
    ]
    for name, js in js_checks:
        result = driver.execute_script(f"return {js}")
        print(f"  {name}: {result}")

    # Check what CSS/JS files are linked
    print("\n=== LINKED RESOURCES ===")
    stylesheets = driver.execute_script("""
        return Array.from(document.querySelectorAll('link[rel=stylesheet]')).map(l => l.href)
    """)
    for s in stylesheets:
        print(f"  CSS: {s}")

    scripts = driver.execute_script("""
        return Array.from(document.querySelectorAll('script[src]')).map(s => s.src)
    """)
    for s in scripts:
        print(f"  JS: {s}")

    # Check if resources loaded successfully
    print("\n=== RESOURCE LOAD STATUS ===")
    all_resources = driver.execute_script("""
        return performance.getEntriesByType('resource')
            .filter(r => r.name.includes('style') || r.name.includes('.css') || r.name.includes('.js') || r.name.includes('prism') || r.name.includes('tutorial'))
            .map(r => ({name: r.name, status: r.responseStatus || 'unknown', size: r.transferSize}))
    """)
    for r in all_resources:
        print(f"  {r.get('name', '?')} -> status={r.get('status', '?')} size={r.get('size', '?')}")

    # Take a screenshot for visual check
    driver.save_screenshot("/Users/theo/MIT Dropbox/Theodore Caputi/job-market/14.33-tutorial-new/ui-audit/resource_check.png")
    print("\n  Screenshot saved: resource_check.png")

    driver.quit()

if __name__ == "__main__":
    main()
