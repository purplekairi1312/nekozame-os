#!/usr/bin/env python3
# scene.py OUTDIR: the picture the looks' previews show, drawn here pixel by pixel at a
# console's own size: scene-320.png (Mega Drive, PS1), scene-256.png (SNES, NES) and
# scene-240.png (a GBA's screen). a sunset in bands, a striped sun, a dithered sea (what
# composite blends into a smooth colour), a catshark, text, colour bars and 1-pixel stripes
# (where composite shows its rainbows and dot crawl).
import os
import sys
from PIL import Image, ImageDraw

SKY = [(67, 58, 85), (90, 79, 110), (138, 118, 168), (217, 184, 214), (255, 192, 229), (255, 212, 238), (255, 241, 176)]
SEA, SEA2 = (67, 58, 85), (104, 92, 127)
SHARK, BELLY, SPOTS = (138, 118, 168), (217, 184, 214), (90, 79, 110)
BARS = [(255, 255, 255), (255, 241, 176), (184, 245, 242), (220, 248, 188), (255, 192, 229), (255, 179, 200), (184, 228, 255), (0, 0, 0)]
# 5x7 letters, for the text
FONT = {
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "E": ["11111", "10000", "11110", "10000", "10000", "10000", "11111"],
    "K": ["10001", "10010", "11100", "10100", "10010", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "Z": ["11111", "00010", "00100", "01000", "10000", "10000", "11111"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
}


def text(d, s, x, y, size, color, shadow):
    for i, ch in enumerate(s):
        for r, row in enumerate(FONT[ch]):
            for c, bit in enumerate(row):
                if bit == "1":
                    px, py = x + (i * 6 + c) * size, y + r * size
                    d.rectangle([px + 1, py + 1, px + size, py + size], fill=shadow)
                    d.rectangle([px, py, px + size - 1, py + size - 1], fill=color)


def shark(d, x, y, s):
    """a catshark swimming right: long body, small fins, a spotted back"""
    body = [(x, y + 6 * s), (x + 10 * s, y + 2 * s), (x + 34 * s, y), (x + 50 * s, y + 3 * s),
            (x + 58 * s, y + 7 * s), (x + 50 * s, y + 10 * s), (x + 30 * s, y + 12 * s), (x + 10 * s, y + 10 * s)]
    d.polygon(body, fill=SHARK)
    d.polygon([(x + 14 * s, y + 9 * s), (x + 50 * s, y + 7 * s), (x + 30 * s, y + 12 * s)], fill=BELLY)
    d.polygon([(x - 10 * s, y), (x + 2 * s, y + 6 * s), (x - 8 * s, y + 13 * s)], fill=SHARK)  # tail
    d.polygon([(x + 30 * s, y), (x + 36 * s, y - 6 * s), (x + 40 * s, y + 1 * s)], fill=SHARK)  # fin
    for sx, sy in ((14, 4), (20, 3), (26, 2), (18, 7), (24, 6), (32, 3), (38, 3)):
        d.rectangle([x + sx * s, y + sy * s, x + sx * s + s - 1, y + sy * s + s - 1], fill=SPOTS)
    d.rectangle([x + 50 * s, y + 4 * s, x + 51 * s, y + 5 * s], fill=(255, 255, 255))  # eye


def scene(w, h):
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    horizon = h * 5 // 8
    band = horizon // len(SKY)
    for i, c in enumerate(SKY):
        d.rectangle([0, i * band, w, (i + 1) * band], fill=c)
    # the sun, cut by stripes
    cx, cy, r = w * 3 // 4, horizon - h // 12, h // 6
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 179, 200))
    for i, yy in enumerate(range(cy + 2, cy + r, 5)):
        d.rectangle([cx - r, yy, cx + r, yy + 1 + i // 2], fill=SKY[-1])
    d.rectangle([0, horizon, w, h], fill=SEA)
    # the sea, dithered: a checkerboard of two colours, thinning out with depth
    for yy in range(horizon, h - 24):
        for xx in range(0, w):
            if (xx + yy) % 2 == 0 and (yy - horizon) % 6 < 3:
                im.putpixel((xx, yy), SEA2)
    shark(d, w // 6, horizon + 14, max(1, w // 160))
    text(d, "NEKOZAME", w // 2 - 24 * (w // 160) - 4, h // 6, max(1, w // 160) + 1, (255, 255, 255), SPOTS)
    # colour bars, and 1-pixel stripes
    bar = w // len(BARS)
    for i, c in enumerate(BARS):
        d.rectangle([i * bar, h - 24, (i + 1) * bar - 1, h - 13], fill=c)
    for xx in range(0, w):
        d.line([xx, h - 12, xx, h - 1], fill=(255, 255, 255) if xx % 2 == 0 else (0, 0, 0))
    return im


out = sys.argv[1] if len(sys.argv) > 1 else "."
os.makedirs(out, exist_ok=True)
for w, h in ((320, 240), (256, 240), (240, 160)):
    scene(w, h).save(os.path.join(out, f"scene-{w}.png"))
print("drawn:", out)
