"""the machines for the pages: museum photos cropped to the machine with their white made
pure white, and patent drawings cropped to a figure and turned to read"""
import json, os, re, sys
os.environ["SDL_VIDEODRIVER"] = "dummy"
import pygame as pg
pg.display.init(); pg.display.set_mode((1, 1))
from picks import PICK
SKIP = {"amstradcpc", "apple2", "dos", "pc88", "pc98", "pcenginecd", "zxspectrum",  # rooms behind them, not white
        # other photographers' (other light, other angles): only evan-amos's museum set, so all match
        "amiga", "msx", "colecovision", "pokemini", "megacd", "megacdjp", "sega32x", "sega32xjp"}
PATENTS = {  # sheet, crop (fractions), turn (degrees, pygame's sense)
    "atari2600": ("pat/atari2600-2.jpg", (0.03, 0.10, 0.56, 0.97), -90),
    "atari5200": ("pat/atari5200-2.jpg", (0.0, 0.11, 0.66, 1.0), -90),
    "vectrex": ("pat/vectrex-2.jpg", (0.02, 0.045, 0.96, 0.338), 0),
    "odyssey2": ("pat/odyssey2-2.jpg", (0.02, 0.07, 0.96, 0.53), 0),
    "arcade": ("pat/arcade-1.png", (0.02, 0.07, 0.98, 0.93), 0),
}
out = sys.argv[1]
os.makedirs(out, exist_ok=True)

def on_white(path):
    im = pg.image.load(path).convert_alpha()
    bg = pg.Surface(im.get_size()); bg.fill((255, 255, 255)); bg.blit(im, (0, 0))
    return bg

def whiten_and_crop(im, pad=24, cut=232):
    """the background (what's at the edges) to white; then cropped to what isn't white"""
    w, h = im.get_size()
    edge = [im.get_at((x, y))[:3] for x in range(0, w, 7) for y in (2, h - 3)] + \
           [im.get_at((x, y))[:3] for y in range(0, h, 7) for x in (2, w - 3)]
    edge.sort(key=sum); paper = edge[len(edge) * 2 // 3]  # the paper/backdrop, lightly
    k = [255 / max(60, c) for c in paper]
    px = pg.PixelArray(im)
    x0, y0, x1, y1 = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, _ = im.unmap_rgb(px[x, y])
            r, g, b = min(255, int(r * k[0])), min(255, int(g * k[1])), min(255, int(b * k[2]))
            if min(r, g, b) > cut:
                r = g = b = 255
            else:
                x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x), max(y1, y)
            px[x, y] = (r, g, b)
    del px
    if x1 <= x0:
        return im
    box = pg.Rect(x0, y0, x1 - x0 + 1, y1 - y0 + 1).inflate(pad * 2, pad * 2).clip(im.get_rect())
    return im.subsurface(box).copy()

def soften(im, edge=22):
    """the edges faded to white, so no box shows where the photo ends"""
    w, h = im.get_size()
    fade = pg.Surface((w, h), pg.SRCALPHA)
    for i in range(edge):
        a = int(255 * (1 - i / edge) ** 2)
        pg.draw.rect(fade, (255, 255, 255, a), (i, i, w - 2 * i, h - 2 * i), 1)
    im.blit(fade, (0, 0))
    return im

def shrink(im, most=1200):
    w, h = im.get_size(); k = min(1, most / max(w, h))
    return pg.transform.smoothscale(im, (int(w * k), int(h * k))) if k < 1 else im

done = []
for sysname, f in PICK.items():
    if sysname in SKIP:
        continue
    src = "src/" + re.sub(r"[^\w.-]", "_", f)
    im = shrink(on_white(src), 1400)
    im = shrink(whiten_and_crop(im, cut=238))
    pg.image.save(im, os.path.join(out, f"machine-{sysname}.jpg")); done.append(sysname)
ERASE = {"vectrex": [(0.0, 0.283, 0.47, 0.34), (0.47, 0.323, 0.78, 0.34)]}  # the next figure's label, painted out
for sysname, (f, (a, b, c, d), turn) in PATENTS.items():
    im = on_white(f); w, h = im.get_size()
    for (ea, eb, ec, ed) in ERASE.get(sysname, []):
        im.fill((255, 255, 255), (int(ea * w), int(eb * h), int((ec - ea) * w), int((ed - eb) * h)))
    im = im.subsurface(pg.Rect(int(a * w), int(b * h), int((c - a) * w), int((d - b) * h))).copy()
    if turn:
        im = pg.transform.rotate(im, turn)
    im = shrink(whiten_and_crop(im, pad=16, cut=200))
    pg.image.save(im, os.path.join(out, f"patent-{sysname}.jpg")); done.append("patent-" + sysname)
print(len(done), "made")
