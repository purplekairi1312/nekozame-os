#!/usr/bin/bash
# the live installer, inside a nekozame os image: the nekozame os image to install, Anaconda,
# a live boot. From Bazzite's installer/build.sh (Apache-2.0, see NOTICE.md).
set -exo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_IMAGE_PAYLOAD=${INSTALL_IMAGE_PAYLOAD:?}

mkdir -p "$(realpath /root)"
# bwrap writes /proc/sys/user/max_user_namespaces, mounted read-only here
mount -o remount,rw /proc/sys

# the image it installs, from the host's container storage when it's there
if mountpoint -q /usr/lib/containers/storage; then
    podman save --format oci-archive "$INSTALL_IMAGE_PAYLOAD" | podman load --storage-opt additionalimagestore=''
else
    podman pull "$INSTALL_IMAGE_PAYLOAD"
fi

cp -a /src/system_files/. /

# a signed kernel for secure boot, then a live initramfs
"$SCRIPT_DIR/hook_preinitramfs.sh"
dnf install -y dracut-live
kernel=$(kernel-install list --json pretty | jq -r '.[] | select(.has_kernel == true) | .version')
DRACUT_NO_XATTR=1 dracut -v --force --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# the live session: nekozame os itself, niri with dms. livesys (Bazzite's way) only knows
# kde and gnome, so: a passwordless liveuser, logged straight into niri by greetd
cat >/usr/libexec/nekozame-liveuser <<'SH'
#!/usr/bin/bash
# the live desktop's user: no password, an administrator
id liveuser >/dev/null 2>&1 && exit 0
useradd -m -c "nekozame os live" -G wheel liveuser
passwd -d liveuser
echo 'liveuser ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/liveuser
SH
chmod +x /usr/libexec/nekozame-liveuser
cat >/etc/systemd/system/nekozame-liveuser.service <<'UNIT'
[Unit]
Description=nekozame os live: the live user
Before=greetd.service systemd-user-sessions.service

[Service]
Type=oneshot
ExecStart=/usr/libexec/nekozame-liveuser

[Install]
WantedBy=multi-user.target
UNIT
systemctl enable nekozame-liveuser.service
printf '\n[initial_session]\nuser = "liveuser"\ncommand = "niri-session"\n' >>/etc/greetd/config.toml
# the installer and anything else it asks for, without a password prompt
cat >/etc/polkit-1/rules.d/49-nekozame-live.rules <<'JS'
polkit.addRule(function (action, subject) {
    if (subject.user == "liveuser") return polkit.Result.YES;
});
JS
# nekozame's own setup is for after installing, not the live desktop
rm -f /etc/xdg/autostart/nekozame-setup.desktop

"$SCRIPT_DIR/hook_postrootfs.sh"

# what image-builder needs: gcdx64.efi, and the EFI folder in /boot/efi
dnf install -y grub2-efi-x64-cdboot
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/
cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi

rm -f /etc/localtime
systemd-firstboot --timezone UTC

# a live / is an overlay in /run, too small for ostree's temporary files: a bigger /var/tmp
rm -rf /var/tmp
mkdir /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'UNIT'
[Unit]
Description=Larger tmpfs for /var/tmp on the live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m,x-systemd.graceful-option=usrquota

[Install]
WantedBy=local-fs.target
UNIT
systemctl enable var-tmp.mount

# systemd-tmpfiles can't label the install target when /mnt is a link
rm /mnt
mkdir /mnt

mkdir -p /usr/lib/bootc-image-builder
cp /src/iso.yaml /usr/lib/bootc-image-builder/iso.yaml
dnf clean all
