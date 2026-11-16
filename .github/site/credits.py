#!/usr/bin/env python3
# writes docs/credits.md: every image and drawing in nekozame's frontend theme, from
# the CREDITS.txt files that ship with them.
#
#   credits.py NEKOZAME_OS EMU_FRONTEND OUT
import os
import re
import sys

OS, FE, OUT = sys.argv[1:4]
ESDE = os.path.join(OS, "system_files/usr/share/nekozame-os/es-de")
GH_OS = "https://github.com/purplekairi1312/nekozame-os/blob/main/system_files/usr/share/nekozame-os/es-de"
GH_FE = "https://github.com/purplekairi1312/nekozame-emu-frontend/blob/main"


def lines(path):
    for line in open(path, encoding="utf-8"):
        m = re.match(r"([A-Za-z0-9._-]+\.(?:jpg|png|svg)): (.+)", line.strip())
        if m:
            yield m.group(1), m.group(2)


def split(rest):
    """'License, who, url (changes)' into its parts"""
    url = re.search(r"https?://\S+", rest)
    before, after = rest[:url.start()].rstrip(", "), rest[url.end():].strip()
    lic, _, who = before.partition(", ")
    if lic.startswith("Public domain (") and not who:  # 'Public domain (a U.S. patent drawing)'
        lic, who = "Public domain", lic[len("Public domain ("):-1]
    who = re.sub(r"^(photo by|by) ", "", who).rstrip(".")
    who = {"a U.S. patent drawing": "US patent drawing", "NPS": "National Park Service",
           "NOAA": "NOAA", "David Burdick": "David Burdick, NOAA"}.get(who, who)
    who = who.replace(", Siebold Collection, Naturalis Biodiversity Center", "")
    changes = after.strip("()") or "resized, color graded"
    link = url.group(0).replace("(", "%28").replace(")", "%29")  # brackets in a link break markdown
    return lic, who, link, changes[0].upper() + changes[1:]


def cell(text):
    return text.replace("|", "\\|")


def table(rows, path):
    out = ["| Image | By | License | Source | Changes |", "|---|---|---|---|---|"]
    for name, rest in rows:
        lic, who, url, changes = split(rest)
        out.append(f"| [{name}]({path}/{name}) | {cell(who)} | {lic} | [Wikimedia Commons]({url}) | {cell(changes)} |")
    return "\n".join(out)


photos = list(lines(os.path.join(ESDE, "photos/CREDITS.txt")))
groups = [
    ("Photos of the sea", "US government photos: NOAA, its Photo Library and National Marine Sanctuaries, and the National Park Service.",
     [p for p in photos if not p[0].startswith(("kawahara-", "machine-", "patent-"))]),
    ("The sharks and rays", "Painted by Kawahara Keiga (川原慶賀) for Philipp Franz von Siebold, 1823-1829. Scans from the Siebold Collection of the Naturalis Biodiversity Center.",
     [p for p in photos if p[0].startswith("kawahara-")]),
    ("Photos of the consoles", "By Evan-Amos, from Wikimedia Commons.",
     [p for p in photos if p[0].startswith("machine-")]),
    ("Patent drawings of the consoles", "Drawings from US design and utility patents.",
     [p for p in photos if p[0].startswith("patent-")]),
]
core = list(lines(os.path.join(ESDE, "nekozame/core/CREDITS.txt")))
flags = list(lines(os.path.join(FE, "resources/flags/CREDITS.txt")))

md = ["# Credits", "",
      "Every image and drawing in nekozame's emulation frontend and its theme, with who made it, its license and where it's from.", "",
      "- The pages are printed by nekozame-emu on your machine from these. Some are resized, cropped, color graded or have their backdrop made white; the Changes column says what.",
      "- The covers, screenshots and boxes of your games come from your own library and its scraped art. They aren't part of nekozame.", ""]
for title, about, rows in groups:
    md += [f"## {title}", "", about, "", table(rows, f"{GH_OS}/photos"), ""]
md += ["## The theme's own graphics", "",
       "| Image | By | License | Source | Changes |", "|---|---|---|---|---|"]
for name, rest in core:
    lic, who, url, changes = split(rest) if "http" in rest else ("", "", "", rest)
    md.append(f"| [{name}]({GH_OS}/nekozame/core/{name}) | Kawahara Keiga (川原慶賀) | Public domain | [Wikimedia Commons]({url}) | "
              "Only the paper's grain, fibres and mottling kept, with a spine's fold added |")
for name, what in [("sky-nekozame.svg", "the nekozame color scheme's sky"), ("sky-lilac.svg", "the lilac scheme's sky"),
                   ("sky-sakura.svg", "the sakura scheme's sky"), ("sky-ocean.svg", "the ocean scheme's sky"),
                   ("sky-sunset.svg", "the sunset scheme's sky"), ("default-cover.svg", "the cover for games without one"),
                   ("block.svg", "the color blocks behind the text")]:
    md.append(f"| [{name}]({GH_OS}/nekozame/core/{name}) | Made for nekozame | GPL-3.0-or-later, with the theme | This repo | {what} |")
md += ["", "## nekozame's art", "",
       "By purplekairi1312, © 2026, [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).", "",
       f"- The frontend's loading screen and icon: [splash.png]({GH_FE}/resources/graphics/splash.png), [org.es_de.frontend.svg]({GH_FE}/es-app/assets/org.es_de.frontend.svg) ([LICENSE-ART]({GH_FE}/LICENSE-ART))",
       "- The nekozame os logo, catshark, boot animation and wallpapers ([LICENSE-ART](https://github.com/purplekairi1312/nekozame-os/blob/main/LICENSE-ART))", "",
       "## The flags", "", "The region flags shown for each game. All public domain, from Wikimedia Commons.", "",
       "| Image | License | Source |", "|---|---|---|"]
for name, rest in flags:
    lic, _, url = rest.partition(", ")
    md.append(f"| [{name}]({GH_FE}/resources/flags/{name}) | {lic} | [Wikimedia Commons]({url}) |")
md += ["", "## Fonts", "",
       "- [Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans) and [Noto Sans CJK JP](https://github.com/notofonts/noto-cjk) by Google, [SIL Open Font License](https://openfontlicense.org/). The pages use the copies installed on your system.",
       "- ES-DE's own fonts and sounds keep their licenses, in [licenses](" + GH_FE + "/licenses).", "",
       "## The music", "",
       '"dolphin sanctuary" by purplekairi1312, released by [Passed Recordings](https://passedrecordings.co.uk/) on [Passed Oceans](https://passedrecordings.bandcamp.com/album/passed-oceans). © 2026 purplekairi1312, all rights reserved ([its license](' + GH_OS + "/music/LICENSE)).", ""]
open(OUT, "w", encoding="utf-8").write("\n".join(md))
print(f"{len(photos)} photos, {len(core) + 7} theme graphics, {len(flags)} flags")
