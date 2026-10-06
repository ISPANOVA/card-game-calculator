"""Renders the app icon PNGs: python3 tool/art/render.py (from the project root)."""
import pathlib, sys
from playwright.sync_api import sync_playwright

root = pathlib.Path(__file__).resolve().parents[2]
art = root / 'tool' / 'art'
out = root / 'assets' / 'icon'
out.mkdir(parents=True, exist_ok=True)
with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_page(viewport={'width': 1024, 'height': 1024})
    for kind, name in [('full', 'app_icon.png'), ('fg', 'app_icon_foreground.png')]:
        pg.goto((art / 'icon.html').as_uri() + '?kind=' + kind)
        pg.wait_for_timeout(200)
        pg.locator('svg').screenshot(path=str(out / name), omit_background=True)
        print('wrote', out / name)
    b.close()
