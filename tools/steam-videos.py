#!/usr/bin/env python3
"""game mode's startup and suspend videos, from the boot screen's 16:10 frames.

the underwater loop comes in and goes out like water: a whirlpool that unwinds
(or winds up), rings spreading out, a blur and a fade. the warp happens at the
frames' own pixel size, then the picture is scaled up with sharp pixels.

needs numpy, pillow and ffmpeg (with libvpx-vp9). run by hand, not in the build:
  tools/steam-videos.py
writes system_files/usr/share/nekozame-os/steam/{startup,suspend}.webm
"""
import os
import subprocess

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
FRAMES = os.path.join(HERE, "..", "system_files/usr/share/plymouth/themes/nekozame/frames-16x10")
OUT = os.path.join(HERE, "..", "system_files/usr/share/nekozame-os/steam")
LOOP, LOOP_FPS, FPS = 48, 16, 30          # the boot loop: 48 frames at 16 fps
SIZE = (1280, 800)                        # the deck's screen

frames = [np.asarray(Image.open(os.path.join(FRAMES, f"frame-{i}.png")).convert("RGB")) for i in range(LOOP)]
H, W = frames[0].shape[:2]
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
cx, cy = W / 2, H / 2
dx, dy = xx - cx, yy - cy
r = np.hypot(dx, dy)
theta = np.arctan2(dy, dx)
R = np.hypot(cx, cy)
falloff = np.clip(1 - r / R, 0, 1)        # strongest in the middle, still at the edges


def smooth(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def water(img, p, t):
    """p = 0: the picture as it is; p = 1: deep in the whirlpool, blurred and dark."""
    if p <= 0:
        return img
    twist = p * 7.0 * falloff ** 2                                   # radians, the whirlpool
    rings = p * 7.0 * np.sin(r / 13.0 - t * 9.0) * falloff           # pixels, the rings
    rr = r + rings
    sx = np.clip(cx + rr * np.cos(theta + twist), 0, W - 1).astype(np.intp)
    sy = np.clip(cy + rr * np.sin(theta + twist), 0, H - 1).astype(np.intp)
    out = Image.fromarray(img[sy, sx])
    if p > 0.02:
        out = out.filter(ImageFilter.GaussianBlur(radius=7.0 * p))
    dark = 1 - p ** 1.3
    return (np.asarray(out).astype(np.float32) * dark).astype(np.uint8)


def render(name, seconds, amount, crf):
    """amount(t) says how far into the water the picture is at time t."""
    ff = subprocess.Popen(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
         "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
         "-vf", f"scale={SIZE[0]}:{SIZE[1]}:flags=neighbor,format=yuv420p",
         "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", str(crf), "-row-mt", "1", "-an",
         os.path.join(OUT, name)], stdin=subprocess.PIPE)
    for n in range(round(seconds * FPS)):
        t = n / FPS
        img = frames[int(t * LOOP_FPS) % LOOP]
        ff.stdin.write(water(img, amount(t), t).tobytes())
    ff.stdin.close()
    if ff.wait():
        raise SystemExit(f"ffmpeg failed on {name}")


os.makedirs(OUT, exist_ok=True)
# startup: out of the whirlpool, one loop, back into it as steam appears
render("startup.webm", 3.0,
       lambda t: max(1 - smooth(t / 0.8), smooth((t - 2.2) / 0.8)), crf=28)
# suspend: one second, into the whirlpool
render("suspend.webm", 1.0, lambda t: smooth(t / 0.9), crf=30)
print("wrote", ", ".join(sorted(os.listdir(OUT))))
