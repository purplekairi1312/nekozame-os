#!/usr/bin/env python3
# scene.py OUTDIR: the picture the looks' previews show: nekozame's wallpaper (the small
# logo, the catshark, the water) back at its own pixels (it's drawn at 360x270 and scaled up
# 12 times), cut to a console's size: scene-320.png (Mega Drive, PS1), scene-256.png (SNES,
# NES) and scene-240.png (a GBA's screen), from the middle.
import os
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
WALLPAPER = os.path.join(HERE, "../../system_files/usr/share/wallpapers/nekozame-small/contents/images/4320x3240.png")

out = sys.argv[1] if len(sys.argv) > 1 else "."
os.makedirs(out, exist_ok=True)
big = Image.open(WALLPAPER).convert("RGB")
own = big.resize((big.width // 12, big.height // 12), Image.NEAREST)  # 360x270, its pixels
for w, h in ((320, 240), (256, 240), (240, 160)):
    x, y = (own.width - w) // 2, (own.height - h) // 2
    own.crop((x, y, x + w, y + h)).save(os.path.join(out, f"scene-{w}.png"))
print("cut:", out)
