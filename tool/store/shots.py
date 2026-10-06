"""Takes the Play Store screenshots from the web build made with
--dart-define=SHOTS=true:  python tool/store/shots.py build/web store/screens
"""
import functools, http.server, pathlib, sys, threading
from playwright.sync_api import sync_playwright

site, out = pathlib.Path(sys.argv[1]).resolve(), pathlib.Path(sys.argv[2]).resolve()
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(site))
server = http.server.ThreadingHTTPServer(('127.0.0.1', 8123), handler)
threading.Thread(target=server.serve_forever, daemon=True).start()

SHOTS = ['home', 'trix', 'complex', 'est', 'round', 'rules']
with sync_playwright() as p:
    browser = p.chromium.launch()
    for lang in ['ar', 'en']:
        (out / lang).mkdir(parents=True, exist_ok=True)
        for i, shot in enumerate(SHOTS, 1):
            page = browser.new_page(viewport={'width': 360, 'height': 640}, device_scale_factor=3)
            page.goto(f'http://127.0.0.1:8123/?shot={shot}&lang={lang}')
            page.wait_for_selector('flutter-view, flt-glass-pane', state='attached', timeout=60000)
            page.wait_for_timeout(6000)  # fonts and fallback glyphs
            path = out / lang / f'{i}_{shot}.png'
            page.screenshot(path=str(path))
            print('wrote', path)
            page.close()
    browser.close()
server.shutdown()
