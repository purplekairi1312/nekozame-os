#!/usr/bin/env bash
# Anaconda, set up to install the nekozame os image this ISO carries, and the live
# desktop quietened. From Bazzite's titanoboa_hook_postrootfs.sh (Apache-2.0, see NOTICE.md).
set -exo pipefail

dnf -qy versionlock clear
dnf install -qy --enable-repo=fedora-cisco-openh264 --allowerasing firefox anaconda-live libblockdev-{btrfs,lvm,dm}
mkdir -p /var/lib/rpm-state  # for Anaconda's web interface
dnf install -qy --setopt=install_weak_deps=0 qrencode yad

imageref="$(podman images --format '{{ index .Names 0 }}\n' 'nekozame*' | head -1)"
imageref="${imageref##*://}"
imageref="${imageref%%:*}"
imagetag="$(podman images --format '{{ .Tag }}\n' "$imageref" | head -1)"
# nekozame os is built on Bazzite: the same kernel, signed with Universal Blue's key
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'
SECUREBOOT_KEY="/usr/share/ublue-os/sb_pubkey.der"
SECUREBOOT_DOC_URL="https://docs.bazzite.gg/sb"
SECUREBOOT_DOC_URL_QR="/usr/share/ublue-os/secure_boot_qr.png"

echo "nekozame os installer ($imageref)" >/etc/system-release
mkdir -p /usr/share/ublue-os
curl -Lo "$SECUREBOOT_KEY" "$sbkey"

cat <<KS >>/usr/share/anaconda/interactive-defaults.ks
%pre
mkdir -p /tmp/anacoda_custom_logs
%end

# a BitLocker partition can stop the install: say so first
%pre --erroronfail --log=/tmp/anacoda_custom_logs/detect_bitlocker.log
if lsblk -o FSTYPE --json | jq -e '.blockdevices | map(select(.fstype == "BitLocker")) | . != []' >/dev/null; then
    run0 --user=liveuser yad --on-top --button="Continue anyway:0" --button="Cancel:10" \
        --text="A Windows BitLocker partition is on this machine, and it can stop the install.\nUnplug its drive, or turn BitLocker off in Windows first." ||
        { pkill liveinst; exit 0; }
fi
%end

%pre-install --erroronfail
rm -rf /mnt/sysroot/boot/efi/EFI/fedora
%end

%onerror
run0 --user=liveuser yad --timeout=0 --text-info --no-buttons --width=600 --height=400 \
    --text="The install went wrong. The log is below: please open an issue on nekozame os's repository with it." \
    < /tmp/anaconda.log
%end

ostreecontainer --url=$imageref:$imagetag --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/follow-the-signed-image.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/restore-selinux-labels.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
%include /usr/share/anaconda/post-scripts/secureboot-docs.ks
KS

# after installing, it updates from the signed image on GitHub, like a rebase
cat <<KS >/usr/share/anaconda/post-scripts/follow-the-signed-image.ks
%post --erroronfail --log=/tmp/anacoda_custom_logs/bootc-switch.log
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $imageref:$imagetag
%end
KS

cat <<KS >/usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
%post --erroronfail --nochroot --log=/tmp/anacoda_custom_logs/secureboot-enroll-key.log
set -oue pipefail
readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="$SECUREBOOT_KEY"
[[ -d /sys/firmware/efi ]] || exit 0
[[ -f "\$SECUREBOOT_KEY" ]] || exit 0
SYS_ID="\$(cat /sys/devices/virtual/dmi/id/product_name)"
[[ ":Jupiter:Galileo:Fremont:" =~ ":\$SYS_ID:" ]] && exit 0  # a Steam Deck: no secure boot
mokutil --timeout -1 || :
echo -e "\$ENROLLMENT_PASSWORD\n\$ENROLLMENT_PASSWORD" | mokutil --import "\$SECUREBOOT_KEY" || :
%end
KS

cat <<KS >/usr/share/anaconda/post-scripts/secureboot-docs.ks
%post --nochroot --log=/tmp/anacoda_custom_logs/secureboot-docs.log
LC_ALL=C mokutil -t "$SECUREBOOT_KEY" | grep -q "is already in the enrollment request" && \
    run0 --user=liveuser yad --timeout=0 --on-top --button=OK:0 --image="$SECUREBOOT_DOC_URL_QR" \
        --text="<b>Secure boot's key is added.</b>\nOn the next start, a blue screen asks to enroll it: pick Enroll MOK, and type\nuniversalblue as the password. The details: $SECUREBOOT_DOC_URL"
%end
KS
qrencode -o "$SECUREBOOT_DOC_URL_QR" "$SECUREBOOT_DOC_URL"

# the live desktop: none of the installed system's background work
(
    set +e
    for s in rpm-ostree-countme.service tailscaled.service bazzite-hardware-setup.service \
        ublue-hardware-setup.service bootloader-update.service brew-upgrade.timer brew-update.timer \
        brew-setup.service rpm-ostreed-automatic.timer uupd.timer ublue-guest-user.service \
        ublue-os-media-automount.service ublue-system-setup.service bazzite-flatpak-manager.service \
        ublue-flatpak-manager.service flatpak-add-fedora-repos.service greenboot-set-rollback-trigger.service \
        greenboot-healthcheck.service input-remapper.service switcheroo-control.service check-sb-key.service; do
        if systemctl list-unit-files "$s" >/dev/null 2>&1; then systemctl disable "$s"; fi
    done
    for s in podman-auto-update.timer bazzite-user-setup.service ublue-user-setup.service; do
        if systemctl --global list-unit-files "$s" >/dev/null 2>&1; then systemctl --global disable "$s"; fi
    done
)
rm -vf /etc/skel/.config/autostart/steam*.desktop
dnf -yq remove steam lutris bazaar waydroid || :
rm -vf /etc/profile.d/verify_motd.sh
rm -f /usr/share/applications/bbrew.desktop /usr/share/applications/bazzite-steam*.desktop
rm -f /usr/bin/rpm-ostree  # never on a live system
dnf -yq install gparted
