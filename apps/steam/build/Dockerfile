ARG BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app:edge

######################################
# The issue here is, that you don't want to give privileged,
# but bwrap needs CAP_SYS_ADMIN.
# However if you explicitly give CAP_SYS_ADMIN, bwrap throws an error,
# because it detects that capabilities have been tempered with
FROM ubuntu:25.04 AS bwrap-builder

ENV DEBIAN_FRONTEND=non-interactive
WORKDIR /root
COPY ignore_capabilities.patch /root/
RUN apt-get update -y
RUN apt-get install -y --no-install-recommends git meson ca-certificates dpkg-dev && \
    git clone https://github.com/containers/bubblewrap && \
    cd bubblewrap && \
    ./ci/builddeps.sh && \
    patch -p1 < ../ignore_capabilities.patch && \
    meson _builddir && \
    meson compile -C _builddir

######################################

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

ARG REQUIRED_PACKAGES=" \
    steam \
    dbus-daemon dbus-system-bus-common dbus-session-bus-common whoopsie network-manager bluez \
    ibus curl pkexec xz-utils zenity file xdg-user-dirs xdg-utils pciutils lsb-release mesa-utils \
    flatpak jq libfuse2 rsync unzip \
    libfontconfig1:i386 libfontconfig1:amd64 libfreetype6 libfreetype6:i386 \ 
    sudo nautilus locales \
"

ARG AVOID_PACKAGES=" \
    nvidia-driver-libs- nvidia-vulkan-icd- \
"

RUN apt-get update -y && \
    apt-get install -y python3-six software-properties-common && \
    # \
    # Install steam (Steam is 32-bit only) \
    dpkg --add-architecture i386 && \
    add-apt-repository multiverse && \
    apt-get update -y && \
    apt-get install -y $REQUIRED_PACKAGES $AVOID_PACKAGES && \
    # \
    # generate the pt_BR.UTF-8 locale
    echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen pt_BR.UTF-8 && \
    # \
    # Fix steam updater UI font file \
    ln -s /usr/share/fonts/truetype/dejavu /usr/share/fonts/truetype/ttf-dejavu && \
    # \
    # Cleanup \
    apt-get remove -y python3-six software-properties-common && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*
# fix NetworkManager not picking up devices
RUN touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

# skip annoying debian dialog
RUN rm /usr/bin/zenity && ln -s /usr/bin/true /usr/bin/zenity

# refresh system font cache. For font warnings on startup see: https://github.com/ValveSoftware/steam-runtime/issues/482
RUN fc-cache -f -v

# Install applications
RUN mkdir /applications && \
    chmod 777 /applications

RUN wget https://github.com/SteamGridDB/SGDBoop/releases/latest/download/sgdboop-linux64.tar.gz && \
    mkdir /applications/sgdboop-linux64 && \
    tar -zxf sgdboop-linux64.tar.gz -C /applications/sgdboop-linux64 && \
    chmod +x /applications/sgdboop-linux64/install.sh && \
    /applications/sgdboop-linux64/install.sh && wait

# Set environment variables for the desired locale
ENV LANG=pt_BR.UTF-8
ENV LANGUAGE=pt_BR:pt
ENV LC_ALL=pt_BR.UTF-8

COPY --chmod=777 scripts/startup.sh /opt/gow/startup-app.sh
COPY --chmod=777 scripts/system-services.sh /etc/cont-init.d/system-services.sh
COPY --chmod=777 steamos-update /usr/bin/steamos-update
COPY --chmod=777 steamos-update /usr/bin/steamos-polkit-helpers/steamos-update
COPY --chmod=777 steamos-session-select /usr/bin/steamos-session-select
COPY --chmod=777 jupiter-biosupdate /usr/bin/jupiter-biosupdate
COPY --chmod=777 jupiter-biosupdate /usr/bin/steamos-polkit-helpers/jupiter-biosupdate
COPY --chmod=777 scripts/steamos-dbus-watchdog.sh /usr/local/bin/steamos-dbus-watchdog.sh
COPY --from=bwrap-builder --chmod=755 /root/bubblewrap/_builddir/bwrap /usr/bin/bwrap

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE

RUN echo 'root:root' | chpasswd
