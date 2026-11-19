#!/usr/bin/env python3
# shapes.py OUT.png: the picture's three shapes on a widescreen, side by side, for the setup's
# "what shape" question: the console's own (4:3, bars at the sides), widescreen (more of the
# scene, as widescreen hacks show more of the game) and stretched. nekozame's wallpaper at its
# own pixels (its 16:9 version is drawn at 320x180, scaled up 12 times); the console's shape is
# its middle 4:3.
import os
import sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
IMAGES = os.path.join(HERE, "../../system_files/usr/share/wallpapers/nekozame-small/contents/images")
SCREEN = (640, 360)  # each frame: a 16:9 screen
LABEL = 40
BG, TEXT = (67, 58, 85), (255, 212, 238)


def own(name):
    big = Image.open(os.path.join(IMAGES, name)).convert("RGB")
    return big.resize((big.width // 12, big.height // 12), Image.NEAREST)


def font(size):
    for f in ("/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/google-noto/NotoSans-Bold.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "shapes.png"
    wide = own("3840x2160.png")
    four = wide.crop(((wide.width - wide.height * 4 // 3) // 2, 0, (wide.width + wide.height * 4 // 3) // 2, wide.height))
    w, h = SCREEN
    frames = []
    console = Image.new("RGB", SCREEN, (0, 0, 0))
    cw = h * 4 // 3
    console.paste(four.resize((cw, h), Image.NEAREST), ((w - cw) // 2, 0))
    frames.append(("The console's own shape", console))
    frames.append(("Widescreen", wide.resize(SCREEN, Image.NEAREST)))
    frames.append(("Stretched", four.resize(SCREEN, Image.NEAREST)))
    gap = 16
    sheet = Image.new("RGB", (len(frames) * w + (len(frames) - 1) * gap, h + LABEL), BG)
    d, f = ImageDraw.Draw(sheet), font(24)
    for i, (label, im) in enumerate(frames):
        x = i * (w + gap)
        sheet.paste(im, (x, 0))
        d.text((x + 12, h + 6), label, fill=TEXT, font=f)
    sheet.save(out, optimize=True)
    print(out, sheet.size, os.path.getsize(out) // 1024, "KB")


main()
