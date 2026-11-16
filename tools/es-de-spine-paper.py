"""the spine's paper: a blank strip of one of 川原慶賀's sheets (naturalis, public domain),
only its grain, fibres and mottling kept, as light and shadow over the spine; with the
fold where the magazine bends round its spine."""
import math, os, sys
os.environ["SDL_VIDEODRIVER"] = "dummy"
import pygame as pg
pg.display.init(); pg.font.init(); pg.display.set_mode((1, 1))
src, out, top = sys.argv[1], sys.argv[2], int(sys.argv[3])
sheet = pg.image.load(src).convert()
strip = sheet.subsurface((40, top, 1840, 184)).copy()
strip = pg.transform.rotate(strip, -90)                      # 192 x 1920, upright
strip = pg.transform.smoothscale(strip, (120, 1200))
W, H = strip.get_size()
lum = [[0.0] * H for _ in range(W)]
for x in range(W):
    for y in range(H):
        r, g, b, _ = strip.get_at((x, y))
        lum[x][y] = 0.3 * r + 0.59 * g + 0.11 * b
blur = pg.transform.smoothscale(pg.transform.smoothscale(strip, (6, 60)), (W, H))
lo = [[0.0] * H for _ in range(W)]
tot = 0
for x in range(W):
    for y in range(H):
        r, g, b, _ = blur.get_at((x, y))
        lo[x][y] = 0.3 * r + 0.59 * g + 0.11 * b
        tot += lo[x][y]
mean = tot / (W * H)
tex = pg.Surface((W, H), pg.SRCALPHA)
for x in range(W):
    # the fold: a soft shadow just inside the bend, a thin light on it, and the spine
    # rounding away toward its outer edge
    fold = -70 * math.exp(-((x - 9) / 5.0) ** 2) + 45 * math.exp(-((x - 2) / 1.6) ** 2) \
           - 28 * max(0, (x - 92) / 28) ** 2 + 10 * math.exp(-((x - 60) / 30.0) ** 2)
    for y in range(H):
        v = (lum[x][y] - lo[x][y]) * 3.0 + (lo[x][y] - mean) * 0.9 + fold
        a = int(min(110, abs(v)))
        tex.set_at((x, y), (255, 255, 255, a) if v > 0 else (24, 14, 30, a))
pg.image.save(tex, out)
# a look: over the spine's pink and its dark block, with white letters
look = pg.Surface((W * 2 + 20, 600)); look.fill((255, 255, 255))
for i, (bg, blk) in enumerate((((176, 46, 104), (40, 26, 52)), ((26, 60, 124), (10, 22, 48)))):
    s = pg.Surface((W, 600)); s.fill(bg); s.fill(blk, (0, 60, W, 300))
    f = pg.font.SysFont("notosanscjkjp", 52, bold=True)
    for j, ch in enumerate("Apple"):
        t = f.render(ch, True, (255, 255, 255)); s.blit(t, ((W - t.get_width()) // 2, 70 + j * 56))
    s.blit(tex.subsurface((0, 300, W, 600)), (0, 0))
    look.blit(s, (i * (W + 20), 0))
pg.image.save(pg.transform.scale(look, (look.get_width() * 2, 1200)), out.replace(".png", "-look.png"))
print("ok", mean)
