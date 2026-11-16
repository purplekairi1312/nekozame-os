# Emulation on nekozame

nekozame's emulation is built around one idea: **your library lives in one place, and every machine plays from it.** Your games, BIOS files, art and saves sit on a NAS (or any network share). Each nekozame machine reads them from there, and keeps nothing but the emulators locally. You can pick up a game on the Steam Deck, carry on at your desk, and your save is already there.

It's made of a few parts:

| Part | What it does |
|---|---|
| `nekozame-emu` | Installs the emulators, launches games, puts your library in Steam, sets up the frontend |
| `nekozame-saves` | Syncs your saves with the NAS, the newest winning, nothing ever thrown away |
| nekozame-emu-frontend | The frontend for browsing the whole library: nekozame's build of [ES-DE](https://es-de.org), with nekozame's theme |
| Steam | Every game as its own entry, with its art, sorted into collections and tabs |

This guide sets up the whole thing the way nekozame is meant to be used. Every step is optional: with no NAS, everything works from local folders too.

---

## 1. Your library

### The layout

nekozame uses the folder layout ES-DE, EmuDeck and most NAS setups already use:

```
Emulation/
├── roms/                    one folder per system: roms/psx, roms/snes, roms/megadrivejp...
├── bios/                    BIOS and firmware files
├── saves/                   one folder per emulator (synced by nekozame-saves)
└── tools/downloaded_media/  art: covers, screenshots... (ES-DE's layout)
```

The folder names are ES-DE's system names. `nekozame-emu systems` lists every system nekozame knows and how many games you have for each.

### How file names work

**Your file name is the game's name, everywhere.** In Steam, in the frontend, on the pages, the name shown is the file's name without its extension. Nothing is renamed, shortened or replaced with a "proper" title unless you ask for it (`"names": "scraped"`, below).

That's on purpose: the name carries what tells versions apart. With the usual [No-Intro](https://no-intro.org) and [Redump](http://redump.org) naming:

```
Beat Mania (Japan).m3u
Beatmania (Europe).chd
Beatmania featuring Dreams Come True (Japan).chd
Sonic the Hedgehog (USA, Europe).md
Sonic the Hedgehog (Japan, Korea).md
Super Mario World (USA) (Rev 1).sfc
```

- **The brackets stay**: region `(Japan)`, version `(Rev 1)`, language `(En,Fr,De)`, `(Beta)`, `(Translated En)`... A scraper would call all of these "Beatmania" or "Sonic the Hedgehog" and you couldn't tell which one you're starting. In Steam, the name is also printed under each cover (`"labels"`), because covers of different versions often look the same.
- **One game, one entry**: games on several discs are best kept as an `.m3u` playlist (a text file listing the discs) next to the disc files, like `Beat Mania (Japan)/Beat Mania (Japan).m3u`. nekozame shows the playlist as the game, not each disc. The same goes for a `.cue` and its `.bin` files, and a `.gdi` and its tracks. When the same game is there in two formats (a `.chd` and a `.cue`), Steam gets only one: the first in nekozame's order for that system. The frontend shows both, so keep one format per game.
- **Art is found by name**: `nekozame-emu art` fetches covers and screenshots from libretro's thumbnail library, which is named after No-Intro and Redump. Files named that way get their art; others may not.
- **The region in the name is what nekozame-emu-frontend will use for region flags**, and for which box a generated 3D box gets. These are coming.
- **Renaming a file** makes it a new game to Steam (its entry, art and playtime start over), and to the frontend. Rename before adding games to Steam, not after.

Two names never change: hidden files (starting with `.`, like macOS's `._` files) are skipped entirely, and the folder a game is in only matters for its system.

### Scraping

ES-DE's scraper (Main menu → Scraper) fetches art, descriptions, release dates and more from online databases like ScreenScraper (a free account helps a lot with its limits). nekozame sets it up so scraping fills in everything **except the name**: "Scrape actual game names" is off, so your file names stay. The art it fetches is saved next to the rest of your art in `media`, on the share, so every machine gets it.

If you'd rather see the scraped titles, set `"names": "scraped"` in `emulation.json`. Steam then uses the frontend's scraped name where there is one, and turn "Scrape actual game names" back on in the frontend.

> macOS leaves hidden `._` files on network shares. nekozame ignores them, but if you copy games from a Mac, it's worth cleaning them off the share now and then.

### Mounting the share

nekozame reads the library straight from the share: nothing is copied to the machine. Mount it once, permanently, with an entry in `/etc/fstab`. For an SMB share:

```
//nas.example/Emulation  /mnt/nas/Emulation  cifs  credentials=/etc/nekozame/smb-credentials,iocharset=utf8,actimeo=600,echo_interval=10,uid=1000,gid=1000,_netdev,nofail,x-systemd.automount,x-systemd.mount-timeout=20  0 0
```

And the login, readable only by root:

```sh
sudo mkdir -p /etc/nekozame /mnt/nas/Emulation
printf 'username=YOU\npassword=YOUR-PASSWORD\n' | sudo tee /etc/nekozame/smb-credentials >/dev/null
sudo chmod 600 /etc/nekozame/smb-credentials
sudo systemctl daemon-reload
```

Keep the password in that file, never in `fstab` itself: `fstab` can be read by anyone on the machine.

Each option is there for a reason:

| Option | Why |
|---|---|
| `actimeo=600` | Remembers each file's details for 10 minutes instead of 1 second. A big library is checked file by file, and over a network every check is a round trip: this made a 30,000-game library open in 35 seconds instead of 104. |
| `echo_interval=10` | Notices a dropped connection (after sleep, say) in about 20 seconds instead of up to two minutes. |
| `x-systemd.automount`, `nofail`, `_netdev` | Mounts the share when it's first used, and never holds up booting if the NAS is away. |
| `x-systemd.mount-timeout=20` | Gives up on an unreachable NAS after 20 seconds instead of hanging. |
| No `x-systemd.idle-timeout` | Don't let the share unmount itself when idle: after sleep, the frontend would freeze waiting for it to come back. |

### Playing away from home

To reach the NAS from anywhere, put both on a [Tailscale](https://tailscale.com) network and use the NAS's Tailscale name in `fstab` (`//nas.your-tailnet.ts.net/Emulation`). It then works the same at home and away. Away from home, every file check takes longer, which is why the options above matter.

---

## 2. Telling nekozame where things are

All of nekozame's emulation settings live in `~/.config/nekozame/emulation.json`. Every setting is optional. For a library on a share:

```json
{
  "roms":  ["/mnt/nas/Emulation/roms"],
  "bios":  "/mnt/nas/Emulation/bios",
  "media": ["/mnt/nas/Emulation/tools/downloaded_media"],
  "steam": {"roms": ["/mnt/nas/Emulation/roms"], "names": "file"},
  "drawings": "both"
}
```

| Setting | Default | What it does |
|---|---|---|
| `roms` | `["~/Emulation/roms"]` | Where your games are. Several places can be listed. |
| `bios` | `"~/Emulation/bios"` | BIOS and firmware; the emulators are pointed here. |
| `media` | `["~/Emulation/tools/downloaded_media"]` | Art: covers, screenshots, 3D boxes... |
| `steam.roms` | same as `roms` | Whose games go into Steam. |
| `steam.names` | `"file"` | Game names: `"file"` (your file names) or `"scraped"` (ES-DE's scraped titles). |
| `steam.labels` | `true` | The name printed under each cover in Steam, so versions of a game tell apart. |
| `loadToRam` | `true` | Disc games (PS1, Saturn, PC Engine CD, PS2, PSP) are read into memory before they start, so a game on a network share never stalls on a disc read. Starting takes a little longer; playing doesn't. |
| `music` | `true` | The frontend's music. |
| `musicVolume` | `40` | Its volume, 0 to 100. |
| `drawings` | `"sharks"` | What's printed on each frontend page: `"sharks"` (Kawahara Keiga's sharks and rays), `"machines"` (a museum photo of the system itself), or `"both"`. |

After changing a setting, run the step it belongs to again (below). They're all safe to run any number of times.

---

## 3. The emulators

```sh
nekozame-emu setup
```

This installs the emulators (from Flathub) for every system you have games for, and points them at your `bios` and `saves` folders. Run it again after adding a new system.

RetroArch plays most systems. The standalone emulators are PCSX2 (PS2), Dolphin (GameCube, Wii), PPSSPP (PSP), RPCS3 (PS3), shadPS4 (PS4), Ryujinx (Switch), Azahar (3DS), Cemu (Wii U), xemu (Xbox) and ScummVM.

Every game is launched through `nekozame-emu launch`, which syncs that emulator's saves before the game and again after it. Launching any other way skips the sync.

---

## 4. Saves

```sh
nekozame-saves setup
```

Choose where your saves live: a folder on the share (`/mnt/nas/Emulation/saves`), or a WebDAV server. Then every machine syncs with that one place.

- **How a save wins:** nekozame remembers each save as it was at the last sync. Changed on one side only: that side's copy goes to the other. Changed on both (you played on two machines in between): the newest wins, the other is kept, and you're told.
- **Nothing is thrown away:** before any save is replaced, on either side, the old one goes into its history (the last 20 of each). `nekozame-saves history PATH` lists them, `nekozame-saves restore PATH VERSION` puts one back.
- **Deleting a save** on one machine doesn't delete it elsewhere: the next sync brings it back.
- **RetroArch** has its own cloud sync, which can point at a WebDAV server on the NAS (Settings → Saving → Cloud Sync). When it's on, nekozame leaves RetroArch's saves to it, and uses the same server and login for the other emulators' saves, in a folder of its own.

`nekozame-saves status` shows where saves go and what the next sync would change.

---

## 5. Steam

```sh
nekozame-emu steam add
```

Puts every game in Steam as its own entry, with its art and launch command. With a big library this takes a while. Run it again after adding games: only the new ones are added.

- **Collections:** one per system (PlayStation, Mega Drive...) and one called **Emulation** with every game.
- **Tabs:** with Decky's TabMaster plugin (`ujust nekozame-decky` installs it), `nekozame-emu steam tabs` sets up two tabs:
  - **Apps:** your other non-Steam apps (Heroic, Tauon...), without the games and emulators.
  - **Emulation:** the games, plus the emulators themselves (kept in their own **Emulators** collection).

  Steam's own Non-Steam tab is hidden. Restart Decky (or the machine) for the tabs to show.
- **Steam forgets big collections when it restarts:** its cloud won't store thousands of games in one collection. The `nekozame-emu-collections` service puts them back a few seconds after every Steam start, and tidies away any stray copies of games. It's on by default.
- `nekozame-emu steam refresh` redoes the art and collections. `nekozame-emu steam remove` takes every game out of Steam again.

Games with no cover yet: `nekozame-emu art` fetches covers and screenshots from libretro's thumbnail library, matched by your file names.

---

## 6. The frontend

```sh
nekozame-emu esde on
```

For browsing a whole library (Steam gets slow with tens of thousands of entries), nekozame sets up its frontend, nekozame-emu-frontend: nekozame's build of ES-DE. It appears in Steam's Apps tab. `nekozame-emu esde off` takes it away again; your game lists and art stay.

It's set up the nekozame way:

- **Your file names** stay the game names, also after scraping.
- **nekozame's launcher** comes first for every system, so saves sync. ES-DE's other emulators stay available per game.
- **The nekozame theme:** every system is a page from a 90s Japanese game magazine, printed on your machine from public-domain photographs and your own games' screenshots. Each page has the machine's museum placard (what it was, what it did) in English or Japanese (UI Settings → Theme language), and its name running down the spine.
  - **Color schemes** (UI Settings → Color scheme): nekozame, lilac, sakura, ocean, sunset.
  - **Layouts** (UI Settings → Theme variant): game list, cover grid, review page, filmstrip, contents. Each comes in six versions for the picture beside the list: screenshot, title screen, cover, 3D box, disc or cartridge, or video.
  - **Drawings:** set by `"drawings"` above.
- **Menu colors:** nekozame and nekozame light, beside ES-DE's own (UI Settings → Menu color scheme).
- **Music:** "dolphin sanctuary" by purplekairi1312 plays quietly while you browse. It pauses during games and the screensaver. Turn it off with `"music": false`. The track is © 2026 purplekairi1312, all rights reserved, and is not covered by nekozame-os's license (see its `LICENSE`).
- **The screensaver** is a slideshow of your games' screenshots. The video screensaver hunts game after game for a video, and over a network share that freezes the frontend.

After adding games or changing `"drawings"`, print the pages again:

```sh
nekozame-emu esde on --again
```

---

## 7. When something's wrong

| What you see | Why, and what to do |
|---|---|
| The frontend takes minutes to open | It checks every game on the share at start. Check the mount has `actimeo=600` (section 1). A library of about 30,000 games opens in around 35 seconds. |
| The frontend froze after the machine slept | The share was still reconnecting. With `echo_interval=10` and no idle timeout (section 1), it recovers within about 20 seconds. |
| A black square on a dark screen in Game Mode, after pressing the power button | Steam is stuck showing its "app running" screen in front of the game. Restart Steam (or the machine). |
| The Apps tab is full of games | Steam forgot the Emulation collection when it restarted. Check `systemctl --user status nekozame-emu-collections`: it should be running, and puts the collection back after each Steam start. |
| The screensaver freezes the frontend | It's set to video. Choose the slideshow instead (UI Settings → Screensaver settings). `nekozame-emu esde on` sets it for you. |
| A game stalls for a moment while playing | It's reading its disc over the network. Check `"loadToRam"` is on, and run `nekozame-emu setup` again. |
| A save is missing or old | `nekozame-saves status`, then `nekozame-saves history PATH`: the earlier versions are all kept. |

---

## Credits

The frontend's photographs are from NOAA (public domain). The sharks and rays were painted by Kawahara Keiga (川原慶賀) for Philipp Franz von Siebold in the 1820s; the scans are from the Naturalis Biodiversity Center (public domain). The museum photos of the machines are by Evan-Amos (public domain, a few CC BY-SA). Every file's source and license is listed in `/usr/share/nekozame-os/es-de/photos/CREDITS.txt`.
