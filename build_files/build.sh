#!/bin/bash
# nekozame os: niri, DankMaterialShell, a few editors and tools, and the
# nekozame theme, on Bazzite DX (AMD and Intel), Bazzite DX NVIDIA or the Steam Deck image.

set -ouex pipefail

# copr and other mirrors have bad minutes: try again a few times before failing
retry() {
    local n
    for n in 1 2 3 4; do
        "$@" && return 0
        echo "attempt $n failed: $*; retrying in $((n * 30))s" >&2
        sleep $((n * 30))
    done
    "$@"
}

# Theme files, wallpaper and configs from system_files/
cp -avf "/ctx/system_files"/. /

### niri + DankMaterialShell (not on the steam deck image: kde there, and
### ujust nekozame-niri layers niri for whoever wants it).
# niri comes from Fedora. DMS comes from its developers' COPR, which pulls in
# its helper repo (avengemedia/danklinux) for dependencies such as quickshell.
if [ "${VARIANT:-amd}" != deck ]; then
    # the pc images have no kde at all: niri with dms is the whole desktop
    dnf5 -y remove "plasma-*" "kwin*" "kde-*" "kdeplasma-*" "kdeconnect*" "kf5-*" "kf6-*" \
        "kio-*" "kscreen*" "krunner*" "kwallet*" "kwrite*" "akonadi*" "baloo*" "dolphin*" \
        "konsole*" "kate*" ark gwenview okular spectacle filelight khelpcenter kinfocenter \
        kmenuedit kdebugsettings kdesu kdecoration "kdegraphics-*" powerdevil polkit-kde \
        xdg-desktop-portal-kde sddm-wayland-plasma plasma-login-manager "breeze-*" \
        kwalletmanager5 bazzite-updater
    # what kde happened to be carrying that stays, and the non-kde replacements
    retry dnf5 -y install virt-manager gnome-keyring pinentry-gnome3 \
        Thunar thunar-archive-plugin thunar-volman tumbler gvfs file-roller

    retry dnf5 -y copr enable avengemedia/dms
    retry dnf5 -y install niri dms dms-greeter greetd
    # niri's screen capture (screen sharing, sunshine) goes through the gnome portal
    retry dnf5 -y install xdg-desktop-portal-gnome
    # dms's media widget draws an audio visualizer on the bar with cava
    retry dnf5 -y install cava
    dnf5 -y copr disable avengemedia/dms
    dnf5 -y copr disable avengemedia/danklinux || true

    # dms's login screen, on greetd
    mkdir -p /etc/greetd
    printf '[terminal]\nvt = 1\n\n[default_session]\nuser = "greeter"\ncommand = "dms-greeter --command niri"\n' \
        > /etc/greetd/config.toml
    systemctl enable greetd.service

    # thunar for folders; file dialogs from the gtk portal (gnome's needs nautilus)
    printf '[Default Applications]\ninode/directory=thunar.desktop\n' >> /usr/share/applications/mimeapps.list
    mkdir -p /etc/xdg-desktop-portal
    { cat /usr/share/xdg-desktop-portal/niri-portals.conf
      echo "org.freedesktop.impl.portal.FileChooser=gtk"; } > /etc/xdg-desktop-portal/niri-portals.conf

    # the kde look-setup only belongs on the deck
    rm -f /etc/xdg/autostart/nekozame-kde-defaults.desktop
    # qt apps under niri: kvantum's look through qt6ct
    echo 'QT_QPA_PLATFORMTHEME=qt6ct' > /usr/lib/environment.d/60-nekozame-qt.conf
    echo 'XCURSOR_THEME=nekozame-cursors' > /usr/lib/environment.d/60-nekozame-cursor.conf
else
    # the deck keeps kde; niri is one ujust away
    echo deck > /usr/share/nekozame-os/variant  # for nekozame-setup
    # the first-boot setup (nekozame-firstboot): a controller-friendly app that game
    # mode runs once, right before steam starts
    retry dnf5 -y install python3-pygame python3-qrcode
    S=/usr/share/gamescope-session-plus/sessions.d/steam
    grep -q '^function post_gamescope_start {' "$S"
    sed -i 's|^function post_gamescope_start {|&\n\t/usr/libexec/nekozame-firstboot \|\| true  # nekozame os: the first-boot setup, once|' "$S"
    grep -q nekozame-firstboot "$S"
    cat /usr/share/nekozame-os/just/deck.just >> /usr/share/ublue-os/just/60-custom.just
    # kde's moving wallpaper: smart video wallpaper reborn (gpl-2.0) plays the catshark
    # loop, and pauses while a window covers the desktop
    # renovate: datasource=github-releases depName=luisbocanegra/plasma-smart-video-wallpaper-reborn
    VW=v2.17.0
    W=/usr/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn
    mkdir -p "$W"
    retry curl -fsSL "https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/releases/download/${VW}/plasma-smart-video-wallpaper-reborn-${VW}.tar.gz" \
        | tar -xz -C "$W"
    test -s "$W/metadata.json"
    # kde's look: nekozame's (the panel on top, the nekozame menu), not valve's vapor
    sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.nekozame.desktop/' /etc/xdg/kdeglobals
    grep -q '^LookAndFeelPackage=org.nekozame.desktop' /etc/xdg/kdeglobals
    # one click opens files and folders (bazzite has one click select)
    sed -i 's/^SingleClick=.*/SingleClick=true/' /etc/xdg/kdeglobals
fi

# dms starts with every niri session, and a first niri login gets dms's config.
# plain links, so they're ready on the deck too once niri gets layered
mkdir -p /etc/systemd/user/niri.service.wants
ln -sf /usr/lib/systemd/user/dms.service /etc/systemd/user/niri.service.wants/dms.service
ln -sf /usr/lib/systemd/user/nekozame-niri-config.service \
    /etc/systemd/user/niri.service.wants/nekozame-niri-config.service

### xremap: Super works like Cmd on a Mac (Super+C/V/X...), app by app; the niri
### build knows which window is focused. config in system_files/usr/share/nekozame-os/xremap
# renovate: datasource=github-releases depName=xremap/xremap
XREMAP=v0.15.18
retry curl -fsSL -o /tmp/xremap.zip \
    "https://github.com/xremap/xremap/releases/download/${XREMAP}/xremap-linux-x86_64-niri.zip"
python3 -m zipfile -e /tmp/xremap.zip /tmp/xremap
install -m 0755 /tmp/xremap/xremap /usr/bin/xremap
rm -rf /tmp/xremap /tmp/xremap.zip
ln -sf /usr/lib/systemd/user/nekozame-keys.service /etc/systemd/user/niri.service.wants/nekozame-keys.service

### yazi, the terminal file manager (not in fedora): the official release build
# renovate: datasource=github-releases depName=sxyazi/yazi
YAZI=v26.9.1
retry curl -fsSL -o /tmp/yazi.zip \
    "https://github.com/sxyazi/yazi/releases/download/${YAZI}/yazi-x86_64-unknown-linux-gnu.zip"
python3 -m zipfile -e /tmp/yazi.zip /tmp/yazi
install -m 0755 /tmp/yazi/yazi-x86_64-unknown-linux-gnu/{yazi,ya} /usr/bin/
rm -rf /tmp/yazi /tmp/yazi.zip

### Packages that used to be layered by hand on this machine
retry dnf5 -y copr enable scottames/ghostty
retry dnf5 -y install emacs fuzzel ghostty

### icons: tela in pink (gpl-3.0), dark panels' variant. tela circle has no
### license, so nekozame os can't ship it: nekozame-icons fetches it per user
# renovate: datasource=github-tags depName=vinceliuice/Tela-icon-theme
TELA=2026-07-07
retry curl -fsSL -o /tmp/tela.tar.gz "https://github.com/vinceliuice/Tela-icon-theme/archive/refs/tags/${TELA}.tar.gz"
tar -xzf /tmp/tela.tar.gz -C /tmp
(cd "/tmp/Tela-icon-theme-${TELA}" && ./install.sh -d /usr/share/icons pink)
rm -rf /tmp/tela.tar.gz "/tmp/Tela-icon-theme-${TELA}"
systemctl --global enable nekozame-icons.timer

### nekozame music: mpv plays (yt-dlp comes per user, kept up to date), the player
### runs for everyone in the background
retry dnf5 -y install mpv

### gtk and qt apps in nekozame: kvantum (the qt style), qt6ct/qt5ct (qt outside kde)
### and adw-gtk3 (gtk 3 apps that take libadwaita's colors)
retry dnf5 -y install kvantum qt6ct qt5ct adw-gtk3-theme

### the nekozame theme, from its own repo (github.com/purplekairi1312/nekozame-theme)
retry curl -fsSL -o /tmp/dl.tar https://github.com/purplekairi1312/nekozame-theme/archive/refs/heads/main.tar.gz
tar -xzf /tmp/dl.tar -C /tmp && rm -f /tmp/dl.tar
T=/tmp/nekozame-theme-main/themes
install -Dm0644 "$T/kde/nekozame.colors" /usr/share/color-schemes/nekozame.colors
install -Dm0644 "$T/konsole/nekozame.colorscheme" /usr/share/konsole/nekozame.colorscheme
install -Dm0644 "$T/ghostty/nekozame" /usr/share/ghostty/themes/nekozame
install -Dm0644 "$T/btop/nekozame.theme" /usr/share/btop/themes/nekozame.theme
install -Dm0644 "$T/cava/config" /usr/share/nekozame-os/cava/config
install -Dm0644 "$T/palettes/nekozame.gpl" /usr/share/nekozame-os/nekozame.gpl
install -Dm0644 "$T/dms/nekozame.json" /usr/share/nekozame-os/dms/nekozame.json
install -Dm0644 "$T/darkreader/nekozame.json" /usr/share/nekozame-os/darkreader/nekozame.json
# for nekozame-apps-theme: zen's look, youtube (improvedtube), discord (vencord), bitwig
install -Dm0644 "$T/zen/userChrome.css" /usr/share/nekozame-os/zen/userChrome.css
install -Dm0644 "$T/zen/userContent.css" /usr/share/nekozame-os/zen/userContent.css
install -Dm0644 "$T/improvedtube/nekozame.json" /usr/share/nekozame-os/improvedtube/nekozame.json
install -Dm0644 "$T/discord/nekozame.theme.css" /usr/share/nekozame-os/discord/nekozame.theme.css
install -Dm0644 "$T/bitwig/nekozame.bte" /usr/share/nekozame-os/bitwig/nekozame.bte
install -Dm0644 "$T/emacs/nekozame-theme.el" /usr/share/nekozame-os/emacs/nekozame-theme.el
# gtk and qt apps (nekozame-look puts them in place per user), and yazi
install -Dm0644 "$T/gtk/gtk-3.0/gtk.css" /usr/share/nekozame-os/gtk/gtk-3.0.css
install -Dm0644 "$T/gtk/gtk-4.0/gtk.css" /usr/share/nekozame-os/gtk/gtk-4.0.css
install -Dm0644 -t /usr/share/Kvantum/nekozame "$T"/kvantum/nekozame/*
install -Dm0644 "$T/qt/nekozame.conf" /usr/share/qt6ct/colors/nekozame.conf
install -Dm0644 "$T/qt/nekozame.conf" /usr/share/qt5ct/colors/nekozame.conf
install -Dm0644 "$T/yazi/theme.toml" /usr/share/nekozame-os/yazi/theme.toml
install -Dm0644 "$T/tauon/nekozame.ttheme" /usr/share/nekozame-os/tauon/nekozame.ttheme
# steam: nekozame-steam-theme puts it into steam's pages (no decky needed)
install -Dm0644 "$T/steam/nekozame.css" /usr/share/nekozame-os/steam/nekozame.css
install -Dm0644 "$T/steam/nekozame.js" /usr/share/nekozame-os/steam/nekozame.js
systemctl --global enable nekozame-steam-theme.service
systemctl --global enable nekozame-audio-follow.service
systemctl --global enable nekozame-emu-collections.service
# kde: the plasma style (panel, popups) and the window decorations (round buttons)
mkdir -p /usr/share/plasma/desktoptheme /usr/share/aurorae/themes
cp -r "$T/plasma/nekozame" /usr/share/plasma/desktoptheme/nekozame
cp -r "$T/aurorae/nekozame" /usr/share/aurorae/themes/nekozame
# the pointer (the trans flag, glossy like the bubble), and the default everywhere
cp -a "$T/cursors/nekozame" /usr/share/icons/nekozame-cursors
mkdir -p /usr/share/icons/default
printf '[Icon Theme]\nInherits=nekozame-cursors\n' > /usr/share/icons/default/index.theme
rm -rf /tmp/nekozame-theme-main

### Branding: the name and logo people see. ID, VARIANT_ID and image-info.json
### stay Bazzite's, because ujust and the update tools read them.
sed -i -e 's/^PRETTY_NAME=.*/PRETTY_NAME="nekozame os"/' \
       -e 's/^LOGO=.*/LOGO=nekozame-os/' /usr/lib/os-release
# Terminal welcome: same layout and ujust table, nekozame os title.
# Terminal welcome: nekozame's own (system_files/usr/share/nekozame-os/motd.md)
cp /usr/share/nekozame-os/motd.md /usr/share/ublue-os/motd/template.md

### Animated wallpaper: mpvpaper, compiled in its own stage (see Containerfile);
### nekozame-wallpaper in system_files runs it. It only needs libmpv here.
retry dnf5 -y install mpv-libs
cp -avf /ctx/mpvpaper/. /
command -v mpvpaper

### audio, for everyone: low latency (pipewire config + threadirqs in system_files),
### realtime priority (limits.d in system_files) and a patchbay. daws and plugins are
### per user: nekozame-music-production
retry dnf5 -y install realtime-setup qpwgraph

### music production (nekozame-music-production layers what each person picks): the audinux
### checklist from its build stage, and plugin folders every daw finds. fedora's
### plugins are in /usr/lib64; reaper, bitwig and most hosts look in /usr/lib (and
### follow folders inside it), so link lib64 in there. lv2/ladspa/dssi don't follow
### folders: environment.d sets their paths
# what native bitwig needs that the base doesn't have (reaper needs nothing)
retry dnf5 -y install xcb-util xcb-util-wm xcb-imdkit
install -Dm0644 /ctx/audinux/catalog.tsv /usr/share/nekozame-os/audinux/catalog.tsv
install -Dm0644 /ctx/audinux/audinux.repo /usr/share/nekozame-os/audinux/audinux.repo
for f in vst3 vst clap; do
    mkdir -p "/usr/lib64/$f" "/usr/lib/$f"
    ln -sfn "/usr/lib64/$f" "/usr/lib/$f/lib64"
done

### wine: windows apps (and windows plugins, once nekozame-music-production sets up yabridge)
retry dnf5 -y install wine

### windows vms: quickemu on top of dx's libvirt/qemu/swtpm/ovmf
### ("quickget windows 11" downloads windows and sets up the vm). fedora's package
### wants mesa-demos, which bazzite's own mesa blocks; quickemu is just scripts,
### so take them from the release and install what they use
retry dnf5 -y install qemu edk2-tools genisoimage jq pciutils socat spice-gtk-tools swtpm \
    unzip usbutils xdg-user-dirs xrandr
# renovate: datasource=github-releases depName=quickemu-project/quickemu
QUICKEMU=4.9.9
retry curl -fsSL -o /tmp/dl.tar "https://github.com/quickemu-project/quickemu/archive/refs/tags/${QUICKEMU}.tar.gz"
tar -xzf /tmp/dl.tar -C /tmp && rm -f /tmp/dl.tar
install -m 0755 "/tmp/quickemu-${QUICKEMU}"/{quickemu,quickget,quickreport,chunkcheck} /usr/bin/
rm -rf "/tmp/quickemu-${QUICKEMU}"

### doom emacs: its dependencies (nekozame-setup installs doom itself per user),
### and the emacs daemon always running for every user (EDITOR is its client)
retry dnf5 -y install ripgrep fd-find git
if [ -f /usr/lib/systemd/user/emacs.service ]; then
    systemctl --global enable emacs.service
else
    echo "warning: no emacs.service in this emacs build" >&2
fi

### sunshine, always on over tailscale: native, so kms capture works under niri (the
### flatpak can't get the capture right); ujust nekozame-sunshine turns it on
retry dnf5 -y copr enable lizardbyte/stable
retry dnf5 -y install Sunshine
dnf5 -y copr disable lizardbyte/stable
setcap cap_sys_admin+p "$(readlink -f /usr/bin/sunshine)"

### ujust: hide bazzite's recipes that don't fit (deck, handhelds, other hardware,
### bazzite branding) and the ones nekozame os wraps under its own names
python3 /ctx/hide-recipes.py /usr/share/ublue-os/just "${VARIANT:-amd}"

### bazzite's own apps that nekozame replaces: the portal (nekozame-setup does its
### job), bazzite's announcements and its documentation shortcut
dnf5 -y remove bazzite-portal || true
rm -f /etc/xdg/autostart/bazzite-announcement.desktop
if [ -f /usr/share/applications/bazzite-documentation.desktop ]; then
    sed -i 's/^NoDisplay=.*/NoDisplay=true/' /usr/share/applications/bazzite-documentation.desktop
fi

### bazzite's updater, as nekozame updater: it updates and rolls back whatever image
### is booted (nekozame), offers only nekozame's images to switch to, and shows
### nekozame-os's own changes as its news
U=/etc/bazzite-updater
if [ "${VARIANT:-amd}" = deck ]; then  # a kde app: only the deck keeps kde
    dnf5 -y install /ctx/updater/*.rpm  # nekozame updater, in bazzite updater's place
    install -m0644 /usr/share/nekozame-os/updater/rebase-targets.json "$U/rebase-targets.json"
    install -m0644 /usr/share/nekozame-os/updater/KAboutData_OS.json "$U/KAboutData_OS.json"
    sed -i -e 's|^rssFeedType=.*|rssFeedType=atom|' \
           -e 's|^rssFeed=.*|rssFeed=https://github.com/purplekairi1312/nekozame-os/commits/main.atom|' \
           -e 's|^systemRollbackCommand=.*|systemRollbackCommand=rpm-ostree rollback|' "$U/config.ini"
    grep -q '^systemUpdateCommand=/usr/libexec/uupd-update' "$U/config.ini"
    D=/usr/share/applications/io.github.rfrench3.bazzite-updater.desktop
    sed -i -e '/^Name\[/d' -e 's/^Name=.*/Name=nekozame Updater/' -e 's/^Icon=.*/Icon=nekozame/' "$D"
fi

### Game mode's startup and suspend videos: the same underwater loop, in place of
### bazzite's. steam-tweaks copies them into steam where there's none yet; just
### before it, nekozame-steam-videos clears out copies of bazzite's own
for v in bazzite bazzite-oled; do
    install -m0644 /usr/share/nekozame-os/steam/startup.webm "/usr/share/ublue-os/bazzite/$v.webm"
done
for v in bazzite-suspend bazzite-suspend-oled; do
    install -m0644 /usr/share/nekozame-os/steam/suspend.webm "/usr/share/ublue-os/bazzite/$v.webm"
done
grep -q '^if ! \$SKIP_VIDEOS; then' /usr/bin/steam-tweaks
sed -i 's|^if ! \$SKIP_VIDEOS; then|/usr/libexec/nekozame-steam-videos\n&|' /usr/bin/steam-tweaks

### Boot screen: the nekozame underwater loop (Plymouth theme in system_files),
### baked into the initramfs so it shows from the very start of boot.
retry dnf5 -y install plymouth-plugin-script  # the theme is a plymouth script
plymouth-set-default-theme nekozame
KVER="$(ls /usr/lib/modules | head -n1)"
dracut --no-hostonly --kver "$KVER" --reproducible --zstd -v --add ostree \
    -f "/usr/lib/modules/$KVER/initramfs.img"
chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"

### Only accept updates signed with this repo's key (cosign.pub)
jq '["nekozame-os", "nekozame-os-nvidia", "nekozame-os-deck"] as $images
    | reduce $images[] as $i (.; .transports.docker["ghcr.io/purplekairi1312/\($i)"] = [{
      "type": "sigstoreSigned",
      "keyPath": "/etc/pki/containers/nekozame-os.pub",
      "signedIdentity": {"type": "matchRepository"}
    }])' /etc/containers/policy.json > /tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json

# Don't leave the COPRs enabled on the finished system.
dnf5 -y copr disable scottames/ghostty
