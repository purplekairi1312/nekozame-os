import json, sys, time, urllib.parse
from search import get
def check(titles):
    ok = {}
    for i in range(0, len(titles), 40):
        d = get({"action": "query", "format": "json", "titles": "|".join(titles[i:i + 40]), "prop": "imageinfo",
                 "iiprop": "url|extmetadata|size", "iiextmetadatafilter": "Artist|LicenseShortName"})
        norm = {n["from"]: n["to"] for n in d.get("query", {}).get("normalized", [])}
        pages = {p["title"]: p for p in d.get("query", {}).get("pages", {}).values()}
        for t in titles[i:i + 40]:
            p = pages.get(norm.get(t, t), {})
            ii = (p.get("imageinfo") or [{}])[0]; md = ii.get("extmetadata", {})
            a = md.get("Artist", {}).get("value", ""); l = md.get("LicenseShortName", {}).get("value", "")
            ok[t] = (bool(ii), "Evan-Amos" in a, "public domain" in l.lower(), ii.get("width"), ii.get("height"))
        time.sleep(1)
    return ok
