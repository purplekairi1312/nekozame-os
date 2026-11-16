import json, os, re, time, urllib.parse, urllib.request
from search import get, UA
from picks import PICK
os.makedirs("src", exist_ok=True)
files = sorted(set(PICK.values()))
meta = {}
for i in range(0, len(files), 25):
    d = get({"action": "query", "format": "json", "titles": "|".join("File:" + f for f in files[i:i + 25]), "prop": "imageinfo",
             "iiprop": "url|extmetadata", "iiurlwidth": 1600, "iiextmetadatafilter": "Artist|LicenseShortName"})
    norm = {n["to"]: n["from"] for n in d["query"].get("normalized", [])}
    for p in d["query"]["pages"].values():
        title = norm.get(p["title"], p["title"])[5:]
        ii = p["imageinfo"][0]; md = ii["extmetadata"]
        meta[title] = {"thumb": ii.get("thumburl") or ii["url"], "page": ii["descriptionurl"],
                       "license": md["LicenseShortName"]["value"],
                       "artist": re.sub(r"\s+", " ", re.sub("<[^>]+>", "", md.get("Artist", {}).get("value", ""))).strip()}
    time.sleep(1)
json.dump(meta, open("meta.json", "w"), indent=1, ensure_ascii=False)
for f, m in meta.items():
    out = "src/" + re.sub(r"[^\w.-]", "_", f)
    if os.path.exists(out) and os.path.getsize(out) > 0:
        continue
    for k in range(6):
        try:
            with urllib.request.urlopen(urllib.request.Request(m["thumb"], headers=UA), timeout=60) as r:
                open(out, "wb").write(r.read())
            break
        except Exception as e:
            time.sleep(4 + k * 6)
    time.sleep(1.5)
print(len(meta), "files;", sum(1 for f in os.listdir("src") if os.path.getsize("src/" + f) > 0), "downloaded")
print(sorted(set(m["license"] for m in meta.values())))
