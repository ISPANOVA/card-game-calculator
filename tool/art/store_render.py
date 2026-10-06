"""Renders the Play Store feature graphic and 512 icon into store/."""
import pathlib
from playwright.sync_api import sync_playwright
root = pathlib.Path(__file__).resolve().parents[2]
out = root / 'store'; out.mkdir(exist_ok=True)
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={'width': 1024, 'height': 500})
    pg.goto((root / 'tool/art/feature.html').as_uri()); pg.wait_for_timeout(500)
    pg.locator('#f').screenshot(path=str(out / 'feature_graphic_1024x500.png'))
    b.close()
from PIL import Image
im = Image.open(root / 'assets/icon/app_icon.png').convert('RGB').resize((512, 512), Image.LANCZOS)
im.save(out / 'play_icon_512.png')
Image.open(out / 'feature_graphic_1024x500.png').convert('RGB').save(out / 'feature_graphic_1024x500.png')
print('ok')
