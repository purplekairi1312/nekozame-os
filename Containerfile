# the bazzite base for this variant (see the FROM below); declared before the first
# FROM so the FROM can use it
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-dx:stable

# mpvpaper (the animated wallpaper player) isn't in Fedora. Compile it in plain
# Fedora, matching nekozame os's Fedora release, so no build tools touch the image
# (Bazzite ships its own graphics drivers, which Fedora's -devel packages clash with).
FROM registry.fedoraproject.org/fedora:45 AS mpvpaper
# renovate: datasource=github-releases depName=GhostNaN/mpvpaper
ARG MPVPAPER=1.9
RUN dnf -y install gcc meson ninja-build pkgconf-pkg-config mpv-devel wayland-devel \
        wayland-protocols-devel mesa-libEGL-devel tar gzip && \
    curl -fsSL "https://github.com/GhostNaN/mpvpaper/archive/refs/tags/${MPVPAPER}.tar.gz" \
        | tar -xz -C /tmp && \
    meson setup /tmp/build "/tmp/mpvpaper-${MPVPAPER}" --prefix=/usr --buildtype=release && \
    DESTDIR=/out ninja -C /tmp/build install

# The music production checklist: what Audinux has for this Fedora release (see
# build_files/audinux-catalog.sh). Nothing from Audinux goes into the image itself.
FROM registry.fedoraproject.org/fedora:45 AS audinux
COPY build_files/audinux-catalog.sh build_files/audinux-formats.awk /ctx/
RUN /ctx/audinux-catalog.sh

# nekozame updater: a fork of bazzite updater with nekozame's name, built as an rpm in
# plain Fedora like mpvpaper. it takes bazzite updater's place in the image.
FROM registry.fedoraproject.org/fedora:45 AS updater
# renovate: datasource=git-refs depName=https://github.com/purplekairi1312/nekozame-updater
ARG UPDATER=46185f344a34d4f0643a6b202c1ca9b52cb2023e
RUN dnf -y install rpm-build git && \
    git clone -q https://github.com/purplekairi1312/nekozame-updater /src && cd /src && \
    git checkout -q "${UPDATER}" && git submodule update -q --init && \
    dnf -y builddep bazzite-updater.spec && \
    V="$(cat version.txt)" && mkdir -p /root/rpmbuild/SOURCES && \
    tar --exclude=.git --transform "s|^\.|bazzite-updater-$V|" -czf "/root/rpmbuild/SOURCES/$V.tar.gz" . && \
    rpmbuild -bb bazzite-updater.spec && mkdir -p /out && cp /root/rpmbuild/RPMS/*/bazzite-updater-[0-9]*.rpm /out/

# Allow build scripts to be referenced without being copied into the final image
# nekozame-ports, from its own repo (anyone can use it): the program and its catalog
FROM registry.fedoraproject.org/fedora:45 AS ports
# renovate: datasource=git-refs depName=https://github.com/purplekairi1312/nekozame-ports
ARG PORTS=6d93500bd4d0351607c20f3d208825e4c2565902
RUN dnf -y install git && \
    git clone -q https://github.com/purplekairi1312/nekozame-ports /src && cd /src && git checkout -q "${PORTS}" && \
    install -Dm755 nekozame-ports /out/usr/bin/nekozame-ports && \
    install -Dm644 catalog.json /out/usr/share/nekozame-ports/catalog.json && \
    install -Dm644 LICENSE /out/usr/share/licenses/nekozame-ports/LICENSE

FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files
COPY --from=mpvpaper /out /mpvpaper
COPY --from=audinux /out /audinux
COPY --from=updater /out /updater
COPY --from=ports /out /ports

# Base image: one per variant (the workflow builds all three)
#   nekozame-os         bazzite-dx          amd / intel pcs and laptops
#   nekozame-os-nvidia  bazzite-dx-nvidia   nvidia pcs
#   nekozame-os-deck  bazzite-deck        steam deck
FROM ${BASE_IMAGE}
ARG VARIANT=amd
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:testing
# FROM ghcr.io/ublue-os/aurora:stable
# FROM ghcr.io/ublue-os/bluefin-nvidia-open:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:44
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    VARIANT=${VARIANT} /ctx/build.sh

### SMOKE TESTS
## If the image is missing something, fail here, so it never gets pushed.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    VARIANT=${VARIANT} /ctx/test.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
