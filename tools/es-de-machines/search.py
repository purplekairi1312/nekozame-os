"""commons: evan-amos's public-domain photos matching a search, with their licence checked"""
import json, sys, time, urllib.parse, urllib.request
UA = {"User-Agent": "nekozame-os theme builder (https://github.com/purplekairi1312/nekozame-os)"}
API = "https://commons.wikimedia.org/w/api.php?"
def get(params):
    for i in range(6):
        try:
            with urllib.request.urlopen(urllib.request.Request(API + urllib.parse.urlencode(params), headers=UA), timeout=30) as r:
                return json.load(r)
        except Exception as e:
            time.sleep(3 + i * 4)
    return {}
def search(q, n=40):
    d = get({"action": "query", "format": "json", "generator": "search", "gsrsearch": q, "gsrnamespace": 6, "gsrlimit": n,
             "prop": "imageinfo", "iiprop": "url|extmetadata|size", "iiextmetadatafilter": "Artist|LicenseShortName"})
    out = []
    for p in (d.get("query", {}).get("pages", {}) or {}).values():
        ii = (p.get("imageinfo") or [{}])[0]; md = ii.get("extmetadata", {})
        artist = md.get("Artist", {}).get("value", ""); lic = md.get("LicenseShortName", {}).get("value", "")
        if "Evan-Amos" in artist and "public domain" in lic.lower():
            out.append((p["title"], ii.get("width"), ii.get("height"), ii.get("url")))
    return out
if __name__ == "__main__":
    for q in sys.argv[1:]:
        res = search(q + " Evan-Amos")
        print(f"## {q}: {len(res)}")
        for t, w, h, u in sorted(res):
            print(f"   {t}  {w}x{h}")
        time.sleep(1)
