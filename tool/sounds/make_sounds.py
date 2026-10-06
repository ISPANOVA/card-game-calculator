"""Synthesizes the app's sound effects (original, no samples):
python3 tool/sounds/make_sounds.py  ->  assets/sounds/*.wav"""
import pathlib
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter

SR = 44100
rng = np.random.default_rng(7)
out = pathlib.Path(__file__).resolve().parents[2] / 'assets' / 'sounds'
out.mkdir(parents=True, exist_ok=True)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def band(x, lo, hi):
    b, a = butter(2, [lo / (SR / 2), hi / (SR / 2)], btype='band')
    return lfilter(b, a, x)


def env(n, attack, decay):
    e = np.exp(-np.arange(n) / (SR * decay))
    a = int(SR * attack)
    if a:
        e[:a] *= np.linspace(0, 1, a)
    return e


def snap(dur=0.05, lo=1800, hi=7000, decay=0.008, gain=1.0):
    n = int(SR * dur)
    x = band(rng.standard_normal(n), lo, hi) * env(n, 0.0005, decay)
    return x * gain


def place(buf, sig, at):
    i = int(SR * at)
    end = min(len(buf), i + len(sig))
    buf[i:end] += sig[: end - i]


def bell(freq, dur, decay, partials=((1, 1), (2.0, 0.35), (3.01, 0.18), (4.2, 0.08))):
    tt = t(dur)
    x = sum(a * np.sin(2 * np.pi * freq * m * tt) for m, a in partials)
    return x * env(len(tt), 0.004, decay)


def save(name, x, peak=0.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    # short fade-out so nothing clicks
    f = min(len(x), int(SR * 0.01))
    x[-f:] *= np.linspace(1, 0, f)
    wavfile.write(out / f'{name}.wav', SR, (x * 32767).astype(np.int16))
    print(name, f'{len(x) / SR:.2f}s')


# tap: one card laid on the table
tap = snap(0.06, 1500, 6500, 0.006) + 0.35 * snap(0.06, 300, 1200, 0.012)
save('tap', tap, 0.7)

# shuffle: a riffle of cards, faster towards the end, then a soft square-up
sh = np.zeros(int(SR * 1.05))
times = np.cumsum(np.linspace(0.045, 0.018, 34))
times = times / times[-1] * 0.78
for i, at in enumerate(times):
    place(sh, snap(0.04, 2000 + 60 * i, 8000, 0.005, 0.6 + 0.4 * rng.random()), at)
place(sh, snap(0.09, 400, 2500, 0.02, 1.6), 0.86)
save('shuffle', sh, 0.8)

# chips: a few clay chips clinking onto a pile
ch = np.zeros(int(SR * 0.6))
for at, f, g in [(0.0, 3100, 1.0), (0.07, 3650, 0.8), (0.12, 2900, 0.7), (0.2, 3400, 0.55), (0.26, 3800, 0.4)]:
    tone = bell(f, 0.25, 0.035, ((1, 1), (1.53, 0.5), (2.41, 0.3)))
    place(ch, tone * g, at)
    place(ch, snap(0.03, 3000, 9000, 0.004, 0.5 * g), at)
save('chips', ch, 0.75)

# win: a bright little fanfare
win = np.zeros(int(SR * 1.9))
notes = [(523.25, 0.0), (659.25, 0.13), (783.99, 0.26), (1046.5, 0.42)]
for f, at in notes:
    place(win, bell(f, 1.3, 0.45), at)
for f in [523.25, 659.25, 783.99, 1046.5]:
    place(win, 0.5 * bell(f, 1.4, 0.6), 0.62)
for i in range(10):  # sparkle
    place(win, 0.18 * bell(2000 + 180 * i, 0.3, 0.05), 0.62 + 0.06 * i)
save('win', win, 0.8)

# saaydeh: two deep hits then a rising shimmer (×2!)
sa = np.zeros(int(SR * 1.5))
for at, f in [(0.0, 130.81), (0.18, 196.0)]:
    tt = t(0.5)
    hit = np.sin(2 * np.pi * f * tt) * env(len(tt), 0.002, 0.18) + 0.4 * snap(len(tt) / SR, 80, 600, 0.03)
    place(sa, hit, at)
tt = t(0.9)
sweep = np.sin(2 * np.pi * (600 * tt + 900 * tt ** 2)) * np.sin(np.pi * tt / 0.9) * 0.35
place(sa, sweep, 0.38)
for i, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0]):
    place(sa, 0.35 * bell(f, 0.6, 0.18), 0.55 + 0.09 * i)
save('saaydeh', sa, 0.8)
