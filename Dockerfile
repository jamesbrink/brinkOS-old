FROM base/archlinux:2018.04.01

# Build arguments.
ARG VCS_REF
ARG BUILD_DATE
ARG BRINKOS_VERSION="2018.04.01"

# Labels / Metadata.
LABEL maintainer="James Brink, brink.james@gmail.com" \
    decription="brinkOS" \
    version="${BRINKOS_VERSION}" \
    org.label-schema.name="brinkos" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/jamesbrink/brinkos" \
    org.label-schema.schema-version="1.0.0-rc1"

# Create user for builds.
RUN set -xe; \
    useradd --no-create-home --shell=/bin/false build; \
    usermod -L build; \
    echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers; \
    echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers;

# Install all needed deps
RUN set -xe; \
    pacman -Syu --noconfirm; \
    pacman -S base base-devel cmake automake autoconf wget vim archiso openssh git nginx --noconfirm;

# Package is currently not resolving properly, quick work-around
# TODO remove this later
RUN cd /var/tmp; \
    wget https://sgp.mirror.pkgbuild.com/extra/os/x86_64/libepoxy-1.5.1-1-x86_64.pkg.tar.xz; \
    pacman -U --noconfirm ./libepoxy-1.5.1-1-x86_64.pkg.tar.xz; \
    rm libepoxy-1.5.1-1-x86_64.pkg.tar.xz;

# Prepare AUR builds
RUN set -xe; \
    mkdir -p /AUR/repo; \
    mkdir -p /AUR/packages; \
    chown -R build:build /AUR;

# Build uvesafb
RUN set -xe; \
    cd /AUR/packages; \
    wget https://aur.archlinux.org/cgit/aur.git/snapshot/uvesafb-dkms.tar.gz; \
    tar xfv uvesafb-dkms.tar.gz; \
    rm uvesafb-dkms.tar.gz; \
    chown -R build:build uvesafb-dkms; \
    cd uvesafb-dkms; \
    sudo -u  build makepkg -si --noconfirm; \
    repo-add /AUR/repo/AUR.db.tar.gz uvesafb-dkms*.pkg.tar.xz; \
    mv uvesafb-dkms*.pkg.tar.xz /AUR/repo/;

# Build plymouth from AUR
# TODO move these elswhere as the list grows?
# TODO how do I build without installing (dep errors will arise)
RUN set -xe; \
    cd /AUR/packages; \
    wget https://aur.archlinux.org/cgit/aur.git/snapshot/plymouth.tar.gz; \
    tar xfv plymouth.tar.gz; \
    rm plymouth.tar.gz; \
    chown -R build:build plymouth; \
    cd plymouth; \
    sudo -u  build makepkg -si --noconfirm; \
    repo-add /AUR/repo/AUR.db.tar.gz plymouth*.pkg.tar.xz; \
    mv plymouth*.pkg.tar.xz /AUR/repo/;

# Build gdm-plymouth from AUR
RUN set -xe; \
    cd /AUR/packages; \
    wget https://aur.archlinux.org/cgit/aur.git/snapshot/gdm-plymouth.tar.gz; \
    tar xfv gdm-plymouth.tar.gz; \
    rm gdm-plymouth.tar.gz; \
    chown -R build:build gdm-plymouth; \
    cd gdm-plymouth; \
    sudo -u  build makepkg -si --noconfirm; \
    repo-add /AUR/repo/AUR.db.tar.gz *plymouth*.pkg.tar.xz; \
    mv *plymouth*.pkg.tar.xz /AUR/repo/;

# Install build deps for brinkOS packages
RUN set -xe; \
    pacman -Syu --noconfirm; \
    pacman -S kdebase-runtime icedtea-web --noconfirm;

# Create prepare our build.
RUN set -xe; \
    mkdir -p /build/brinkOS-packages; \
    mkdir -p /build/AUR; \
    chown -R build:build /build;

# If building on a debian host, dev/shm points to /run/shm
# and will fail without this directory.
RUN mkdir -p /build/archiso/work/x86_64/airootfs/run/shm; \
    mkdir -p /build/archiso/work/x86_64/airootfs/var/run/shm; \
    mkdir -p /run/shm; \
    mkdir -p /var/run/shm;

# Copy in brinkOS packages and work dir.
COPY ./brinkOS/packages /build/packages
COPY ./brinkOS/work /build/work
RUN chown -R build:build /build

# Build brinkOS assets package.
RUN set -xe; \
    cd /build/packages/brinkOS-assets; \
    sudo -u build makepkg; \
    repo-add /build/brinkOS-packages/brinkOS.db.tar.gz *.pkg.tar.xz; \
    mv *.pkg.tar.xz /build/brinkOS-packages/;

# Build brinkOS Cinnamon Themes package.
RUN set -xe; \
    cd /build/packages/brinkOS-themes-cinnamon; \
    sudo -u build makepkg; \
    repo-add /build/brinkOS-packages/brinkOS.db.tar.gz brinkOS-themes-cinnamon-1.0.0-1-any.pkg.tar.xz; \
    mv brinkOS-themes-cinnamon-1.0.0-1-any.pkg.tar.xz /build/brinkOS-packages/;

# Build brinkOS Icons package.
RUN set -xe; \
    cd /build/packages/brinkOS-icons; \
    sudo -u build makepkg; \
    repo-add /build/brinkOS-packages/brinkOS.db.tar.gz brinkOS-icons-1.0.0-1-any.pkg.tar.xz; \
    mv brinkOS-icons-1.0.0-1-any.pkg.tar.xz /build/brinkOS-packages/;
    
# Build brinkOS Wallpaper package.
RUN set -xe; \
    cd /build/packages/brinkOS-wallpapers; \
    sudo -u build makepkg; \
    repo-add /build/brinkOS-packages/brinkOS.db.tar.gz brinkOS-wallpapers-1.0.0-1-any.pkg.tar.xz; \
    mv brinkOS-wallpapers-1.0.0-1-any.pkg.tar.xz /build/brinkOS-packages/;

# Prepare build for brinkOS-installer.
# Due to an issue with qt5 packages calling
# speciic syscalls during build process, these have to be compiled
# during docker run --priviledged
RUN set -xe; \
    cd /AUR/packages; \
    wget https://aur.archlinux.org/cgit/aur.git/snapshot/qt5-styleplugins-git.tar.gz; \
    tar xfv qt5-styleplugins-git.tar.gz; \
    rm qt5-styleplugins-git.tar.gz; \
    chown -R build:build qt5-styleplugins-git;
COPY ./brinkOS/brinkOS-installer /build/packages/brinkOS-installer
RUN chown -R build:build /build/packages

# Copy in our entrypoint and archlive and set ownership.
COPY ./brinkOS/archlive /build/archlive
RUN chown -R build:build /build /AUR
COPY ./brinkOS/docker-entrypoint.sh /build/docker-entrypoint.sh

# Setup Environment variables.
ENV GTK_THEME="Arctic-brinkOS" \
    SHELL_THEME="Arctic-brinkOS" \
    ICON_THEME="brinkOS-Icons" \
    WALLPAPER="file:///usr/share/backgrounds/gnome/bear-rock.jpg" \
    PACKAGE_PROXY=""

# Set our entrypoint which kicks off our build.
ENTRYPOINT [ "/build/docker-entrypoint.sh" ]