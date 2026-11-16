# nekozame os

<p align="center"><img src="https://git.sr.ht/~purplekairi1312/nekozame-os/blob/main/docs/logo.gif" alt="nekozame os logo: a pixelated catshark swimming above the chrome letters nekozame os and 猫鮫 in a bubble, underwater" width="640"></p>

Opinionated immutable distro.

- [niri](https://github.com/niri-wm/niri) with [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell), login screen included
- Mac-style keys: Super works like Cmd (Super+C/V/X to copy and paste, Super+Q to close), Ctrl+Alt moves windows, Alt+1-9 switches workspaces. The same on a Mac with [nekozame-mac](https://git.sr.ht/~purplekairi1312/nekozame-mac). Super+Shift+/ shows them all
- Gaming, and emulation for a local library or one on a network share, saves synced between machines ([how it works](docs/emulation.md)) (and NVIDIA drivers on the NVIDIA image)
- Doom Emacs as `$EDITOR`, always running as a daemon, emacs keys (evil mode or another editor if you want)
- Low-latency audio with realtime priority for everyone, and music production on request: Bitwig, Reaper or Renoise (proprietary, paid), Ardour or LMMS (free software), a checklist of about 700 plugins from Audinux that every DAW finds, and yabridge for Microsoft Windows plugins
- Sunshine always on, so you can stream it from anywhere over Tailscale with Moonlight
- Zen, ready for privacy: Dark Reader, uBlock Origin, Privacy Badger, LibRedirect, ClearURLs, Consent-O-Matic and nekojs (LibreJS made simple), DuckDuckGo, HTTPS-only, no telemetry, no WebRTC leaks (Helium optional, with the same)
- Microsoft Windows VMs with quickemu (`quickget windows 11`) on top of libvirt and virt-manager
- A little catshark swimming as your boot screen and wallpaper, sharp on any screen shape, with the nekozame logo small, big or not at all (`ujust nekozame-wallpaper`) <3

On your first login, a short setup turns all of it on and asks about the optional bits. Run it again with `ujust nekozame-setup`; everything else is under `ujust`.

[All the software](PACKAGES.md)

## Install

Pick the image for your machine:

| Machine | Image |
|---|---|
| PC or laptop with AMD or Intel graphics | `nekozame-os` |
| PC with an NVIDIA GPU (GTX 16xx, RTX) | `nekozame-os-nvidia` |
| Steam Deck | `nekozame-os-deck`: boots into Game Mode. Desktop Mode is KDE with the nekozame look; `ujust nekozame-niri` adds niri. No DX dev tools. |

### From an ISO

For a new install. It erases the disk you install to.

| Image | Download | Checksum |
|---|---|---|
| nekozame-os | [nekozame-os.iso](https://archive.org/download/nekozame-os-iso/nekozame-os.iso) | [sha256](https://archive.org/download/nekozame-os-iso/nekozame-os.iso-CHECKSUM) |
| nekozame-os-nvidia | [nekozame-os-nvidia.iso](https://archive.org/download/nekozame-os-iso/nekozame-os-nvidia.iso) | [sha256](https://archive.org/download/nekozame-os-iso/nekozame-os-nvidia.iso-CHECKSUM) |
| nekozame-os-deck | [nekozame-os-deck.iso](https://archive.org/download/nekozame-os-iso/nekozame-os-deck.iso) | [sha256](https://archive.org/download/nekozame-os-iso/nekozame-os-deck.iso-CHECKSUM) |

- They're hosted for free on the [Internet Archive](https://archive.org/details/nekozame-os-iso), which also has a torrent for each one.
- Write it to a USB stick with [Fedora Media Writer](https://flathub.org/apps/org.fedoraproject.MediaWriter) or Ventoy, and boot from it.
- They're made from the `:stable` image every Sunday. After installing, the system updates itself from the signed image.

### From another Fedora Atomic system

From Bazzite or any Universal Blue or Fedora Atomic image. Your files, Flatpaks and settings stay.

```sh
IMAGE=nekozame-os   # or nekozame-os-nvidia, nekozame-os-deck

# Drop anything you layered yourself
sudo rpm-ostree reset

# First time: unsigned, then reboot
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/purplekairi1312/$IMAGE:stable
systemctl reboot

# Then the signed image, then reboot
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/purplekairi1312/$IMAGE:stable
systemctl reboot
```

- The first rebase is unsigned because your system doesn't have nekozame's signing key yet; the image brings it. From then on, every update is checked against it.
- Going back: `sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-dx:stable` (or `bazzite-dx-nvidia`, `bazzite-deck`, matching your image).

## Customizing

- `ujust nekozame-setup` runs the first-login setup again: the optional bits, like music production, Helium or Sunshine.
- `ujust` lists everything else.
- niri: your config is `~/.config/niri/config.kdl`, and it's yours to change. nekozame's shortcuts are in `/usr/share/nekozame-os/niri/binds.kdl`, which it includes, so they update with the OS.
- Install apps with Flatpak (Bazaar), or Homebrew for command-line tools. Layering packages with rpm-ostree works too, but slows updates down.

## How it's built

- The [`Containerfile`](Containerfile) starts from Bazzite (`bazzite-dx`, `bazzite-dx-nvidia`, `bazzite-deck`) and runs [`build_files/build.sh`](build_files/build.sh). nekozame's own files are in [`system_files`](system_files).
- GitHub Actions builds the 3 images every day. Each build runs smoke tests before it's published as `:latest`.
- Once a week, the current `:latest` becomes `:stable`, which is what installs follow. That way a bad day upstream doesn't reach you.
- The ISOs are built from `:stable` every Sunday ([`build-disk.yml`](.github/workflows/build-disk.yml), [`disk_config/iso.toml`](disk_config/iso.toml)).
- Images are signed with Cosign: `cosign verify --key cosign.pub ghcr.io/purplekairi1312/nekozame-os`
- When something breaks: [`MAINTENANCE.md`](MAINTENANCE.md).

## FAQ

**What does nekozame mean?**
猫鮫, catshark. I'm a catgirl, I love cats, sharks are my fav animal, and I'm a Sonic fan: the Sonic hedgehog protein (yes, named after Sonic) gets studied a lot in catsharks, which I find funny and that way im fusing 3 things i really like :D

## Credits

- Based on [Bazzite](https://bazzite.gg) and the Universal Blue [image template](https://github.com/ublue-os/image-template).

The emulation frontend:

- Photos of the sea: [NOAA](https://www.noaa.gov/), its [Photo Library](https://www.flickr.com/photos/noaaphotolib/) and [National Marine Sanctuaries](https://sanctuaries.noaa.gov/), and the US National Park Service. Public domain, via [Wikimedia Commons](https://commons.wikimedia.org/).
- The sharks and rays: painted by Kawahara Keiga (川原慶賀) for Philipp Franz von Siebold, 1823-1829. Scans from the [Naturalis Biodiversity Center](https://www.naturalis.nl/), public domain. The paper of the spines is from one of his sheets.
- Photos of the consoles: [Evan-Amos](https://commons.wikimedia.org/wiki/User:Evan-Amos), via Wikimedia Commons. Public domain, apart from a few under CC BY-SA 3.0.
- Patent drawings of the consoles: from US patents, public domain.
- Flags: Wikimedia Commons, public domain.
- Fonts: Noto Sans and Noto Sans CJK JP by Google, SIL Open Font License.
- Music: "dolphin sanctuary" by purplekairi1312, released by [Passed Recordings](https://passedrecordings.co.uk/).
- The frontend itself: a fork of [ES-DE](https://es-de.org), by Leon Styhre, Northwestern Software and its contributors.

Every image and drawing, one by one, with its source and license: [Credits](docs/credits.md).

## License

- Code: [GPL-3.0-or-later](LICENSE).
- Art (logo, catshark, boot animation, wallpapers): © 2026 purplekairi1312, [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) ([LICENSE-ART](LICENSE-ART)).
- The emulation frontend's photos: public domain (NOAA, Kawahara Keiga's paintings from the Naturalis Biodiversity Center, most of Evan-Amos's console photos); a few console photos are CC BY-SA 3.0. Each one's source and license: [CREDITS.txt](system_files/usr/share/nekozame-os/es-de/photos/CREDITS.txt).
- The music, "dolphin sanctuary": © 2026 purplekairi1312, all rights reserved, not under the GPL ([its license](system_files/usr/share/nekozame-os/es-de/music/LICENSE)). Buy it on [Bandcamp](https://passedrecordings.bandcamp.com/track/dolphin-sanctuary).
