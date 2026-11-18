#!/bin/bash
# smoke tests, run at the end of every build: if the image is missing something,
# the build fails and nothing gets pushed to anyone.
set -uo pipefail
V="${VARIANT:-amd}"
fail=0
check() {  # check "what" 'command'
    local out
    if out=$(bash -c "$2" 2>&1); then echo "ok    $1"
    else echo "FAIL  $1"; printf '%s\n' "$out" | tail -5 | sed 's/^/      /'; fail=1; fi
}

check "sunshine, with the screen capture right" 'getcap "$(readlink -f /usr/bin/sunshine)" | grep -q cap_sys_admin'
check "mpvpaper" 'command -v mpvpaper'
check "quickemu" 'command -v quickemu && command -v quickget'
check "nekozame keys (xremap and niri shortcuts)" 'xremap --version && test -s /usr/share/nekozame-os/xremap/config.yml && test -s /usr/share/nekozame-os/niri/binds.kdl'
check "qpwgraph" 'command -v qpwgraph'
check "music checklist (audinux)" 'test "$(wc -l < /usr/share/nekozame-os/audinux/catalog.tsv)" -gt 300 && grep -q "^surge-xt	" /usr/share/nekozame-os/audinux/catalog.tsv && test -s /usr/share/nekozame-os/audinux/audinux.repo'
check "native bitwig's libraries" 'test -e /usr/lib64/libxcb-icccm.so.4 && test -e /usr/lib64/libxcb-util.so.1 && test -e /usr/lib64/libxcb-imdkit.so.1'
check "plugin folders for every daw" 'test -L /usr/lib/vst3/lib64 && test -L /usr/lib/clap/lib64 && test -L /usr/lib/vst/lib64 && grep -q LV2_PATH /usr/lib/environment.d/60-nekozame-plugins.conf'
check "wine" 'command -v wine'
check "realtime audio for everyone" 'test -f /etc/security/limits.d/95-nekozame-audio.conf'
check "game mode's videos are nekozame's" 'cmp -s /usr/share/nekozame-os/steam/startup.webm /usr/share/ublue-os/bazzite/bazzite.webm && grep -q nekozame-steam-videos /usr/bin/steam-tweaks && test -x /usr/libexec/nekozame-steam-videos'
check "nekozame in gtk and qt apps" 'test -s /usr/share/Kvantum/nekozame/nekozame.svg && test -s /usr/share/Kvantum/nekozame/nekozame.kvconfig && test -s /usr/share/nekozame-os/gtk/gtk-4.0.css && test -s /usr/share/qt6ct/colors/nekozame.conf && test -s /usr/share/nekozame-os/yazi/theme.toml && test -d /usr/share/themes/adw-gtk3-dark'
check "kde's nekozame look" 'test -s /usr/share/plasma/desktoptheme/nekozame/widgets/panel-background.svg && test -s /usr/share/aurorae/themes/nekozame/close.svg && test -s /usr/share/plasma/look-and-feel/org.nekozame.desktop/contents/defaults && test -s /usr/share/icons/hicolor/256x256/apps/nekozame.png'
check "the nekozame pointer, the default" 'test -e /usr/share/icons/nekozame-cursors/cursors/left_ptr && test -e /usr/share/icons/nekozame-cursors/cursors/hand2 && grep -q "Inherits=nekozame-cursors" /usr/share/icons/default/index.theme'
check "nekozame in steam" 'test -s /usr/share/nekozame-os/steam/nekozame.css && test -x /usr/libexec/nekozame-steam-theme && test -L /etc/systemd/user/default.target.wants/nekozame-steam-theme.service'
check "emulation" 'test -x /usr/bin/nekozame-emu && /usr/bin/nekozame-emu systems >/dev/null'
check "the network share helper, for the first boot" 'test -x /usr/libexec/nekozame-mount-share && test -s /usr/share/polkit-1/actions/org.nekozame.mount-share.policy'
check "vencord after discord updates" 'test -x /usr/libexec/nekozame-vencord && test -L /etc/systemd/user/timers.target.wants/nekozame-vencord.timer && test -L /etc/systemd/system/timers.target.wants/nekozame-vencord-system.timer'
check "cava in tmux" 'command -v cava && test -x /usr/libexec/nekozame-cava-tmux && test -L /etc/systemd/user/default.target.wants/nekozame-cava-tmux.service'
check "ports" 'test -x /usr/bin/nekozame-ports && python3 -c "import ast, json; ast.parse(open(\"/usr/bin/nekozame-ports\").read()); assert json.load(open(\"/usr/share/nekozame-ports/catalog.json\"))[\"ports\"]" && test -L /etc/systemd/user/timers.target.wants/nekozame-ports-check.timer'
check "emulation setup" 'test -x /usr/bin/nekozame-emulation && bash -n /usr/bin/nekozame-emulation'
check "save sync" 'test -x /usr/bin/nekozame-saves && /usr/bin/nekozame-saves help >/dev/null; python3 -c "import ast; ast.parse(open(\"/usr/bin/nekozame-saves\").read())"'
check "emulation collections kept in steam" 'test -L /etc/systemd/user/default.target.wants/nekozame-emu-collections.service'
check "sound follows your headphones" 'test -x /usr/libexec/nekozame-audio-follow && test -L /etc/systemd/user/default.target.wants/nekozame-audio-follow.service'
[ "${VARIANT:-amd}" != deck ] || check "nekozame music (decky) and library art" 'command -v mpv && test -x /usr/libexec/nekozame-steam-launch-options && test -x /usr/libexec/nekozame-steam-controls && test -x /usr/libexec/nekozame-decky && test -s /usr/share/polkit-1/actions/org.nekozame.decky.policy && test -x /usr/libexec/nekozame-steam-art && python3 -c "import sys; sys.path.insert(0, \"/usr/share/nekozame-os/python\"); import nekoui"'
check "tela icons (pink)" 'test -s /usr/share/icons/Tela-pink-dark/index.theme && test -x /usr/libexec/nekozame-icons && test -L /usr/lib/systemd/user/timers.target.wants/nekozame-icons.timer -o -L /etc/systemd/user/timers.target.wants/nekozame-icons.timer'
[ "${VARIANT:-amd}" != deck ] || check "kde's moving wallpaper" 'test -s /usr/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn/metadata.json && test -s /usr/share/backgrounds/nekozame/small-16x10.mkv'
[ "${VARIANT:-amd}" != deck ] || check "first-boot setup before game mode" 'grep -q nekozame-firstboot /usr/share/gamescope-session-plus/sessions.d/steam && python3 -c "import pygame, qrcode" && test -x /usr/libexec/nekozame-firstboot'
[ "${VARIANT:-amd}" != deck ] || check "nekozame updater: nekozame's images only, updates the booted one" '! grep -q "ublue-os" /etc/bazzite-updater/rebase-targets.json && grep -q nekozame-os-deck /etc/bazzite-updater/rebase-targets.json && grep -q "^systemUpdateCommand=/usr/libexec/uupd-update" /etc/bazzite-updater/config.ini && grep -q "^Name=nekozame Updater" /usr/share/applications/io.github.rfrench3.bazzite-updater.desktop && rpm -q bazzite-updater | grep -q nekozame && grep -aq "nekozame Updater" /usr/bin/bazzite-updater'
check "screens setup (niri)" 'test -x /usr/bin/nekozame-display'
check "first-login setup" 'test -x /usr/bin/nekozame-setup && test -f /etc/xdg/autostart/nekozame-setup.desktop && command -v gum'
check "emacs and cava themes" 'test -s /usr/share/nekozame-os/emacs/nekozame-theme.el && test -s /usr/share/nekozame-os/cava/config'
check "browser policies" 'jq -e ".policies.ExtensionSettings[\"uBlock0@raymondhill.net\"]" /usr/share/nekozame-os/zen/policies/policies.json && jq -e .WebRtcIPHandling /etc/chromium/policies/managed/nekozame.json'
check "emacs, ghostty, fuzzel, yazi" 'command -v emacs && command -v ghostty && command -v fuzzel && command -v yazi'
check "boot screen is the default" 'plymouth-set-default-theme | grep -qx nekozame'
check "boot screen is in the initramfs" 'lsinitrd /usr/lib/modules/*/initramfs.img | grep -q themes/nekozame/frames-16x9'
check "nekozame ujust recipes" 'just --justfile /usr/share/ublue-os/justfile --list | grep -q nekozame-sunshine'
check "nekozame in apps (zen, discord, bitwig)" 'test -x /usr/bin/nekozame-apps-theme && test -s /usr/share/nekozame-os/zen/userContent.css && test -s /usr/share/nekozame-os/discord/nekozame.theme.css && test -s /usr/share/nekozame-os/bitwig/nekozame.bte && test -s /usr/share/nekozame-os/improvedtube/nekozame.json'
check "theme files" 'test -s /usr/share/color-schemes/nekozame.colors && jq -e .primary /usr/share/nekozame-os/dms/nekozame.json'
check "wallpapers" 'test -s /usr/share/backgrounds/nekozame/small-16x9.mkv'
check "signed updates, every image" 'for i in nekozame-os nekozame-os-nvidia nekozame-os-deck; do jq -e ".transports.docker[\"ghcr.io/purplekairi1312/$i\"]" /etc/containers/policy.json || exit 1; done'
check "low latency audio" 'test -f /usr/share/pipewire/pipewire.conf.d/50-nekozame-lowlatency.conf'
check "greenboot login screen check" 'test -x /etc/greenboot/check/required.d/50-nekozame-login-screen.sh'
check "kitty-logo (the fetch logo as text)" 'kitty-logo /usr/share/nekozame-os/fastfetch/logo.png 30 | grep -q " 30 "'
check "nekozame-fetch with its logos" 'test -x /usr/bin/nekozame-fetch && test -s /usr/share/nekozame-os/fastfetch/logo-tty.txt && test -s /usr/share/nekozame-os/fastfetch/logo.png'
check "nekozame terminal welcome" 'grep -q "nekozame" /usr/share/ublue-os/motd/template.md'
check "nekozame colours for the welcome and gum" 'jq -e ".heading.color == \"#ffc0e5\"" /usr/share/ublue-os/motd/themes/nekozame.json && test -r /usr/share/nekozame-os/colors.sh'
check "bazaar" 'rpm -q bazaar'
if [ "$V" = deck ]; then
    check "kde for desktop mode" 'rpm -q plasma-workspace'
    check "ujust nekozame-niri" 'grep -q "^nekozame-niri:" /usr/share/ublue-os/just/60-custom.just'
else
    check "niri, dms and its login screen" 'command -v niri && command -v dms && command -v dms-greeter'
    check "greetd is the login manager" 'systemctl is-enabled greetd.service'
    check "no kde" '! rpm -q plasma-workspace && ! rpm -q kwin && ! rpm -q plasma-login-manager'
    check "thunar" 'command -v thunar'
    check "virt-manager" 'command -v virt-manager'
    check "gnome portal for screen capture" 'rpm -q xdg-desktop-portal-gnome'
fi
[ "$fail" = 0 ] && echo "all good" || echo "some checks failed"
exit "$fail"
