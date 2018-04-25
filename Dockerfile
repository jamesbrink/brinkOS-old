FROM base/archlinux:2018.04.01

# Build arguments.
ARG VCS_REF
ARG BUILD_DATE
ARG BRINKOS_VERSION="2018.04.01"

# Labels / Metadata.
LABEL maintainer="James Brink, brink.james@gmail.com" \
    decription="BrinkOS" \
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

# Install all needed deps and compile the mesa llvmpipe driver from source.
RUN set -xe; \
    pacman -Syu --noconfirm; \
    pacman -S base-devel cmake automake autoconf wget vim archiso --noconfirm;

RUN pacman -S openssh git --noconfirm

COPY ./build /build
COPY ./keyring /build/keyring
COPY ./brink-packages /build/brink-packages

# Install keyrings.
RUN set -xe; \
    cd /build/keyring; \
    make; \
    cp -rv /usr/local/share/pacman/keyrings/* /usr/share/pacman/keyrings/;

# This is a bug work-around for qt-5
# https://bugs.archlinux.org/task/57254
RUN set -xe; \
    cd /var/tmp; \
    wget https://archive.archlinux.org/packages/q/qt5-base/qt5-base-5.10.0-2-x86_64.pkg.tar.xz; \
    pacman -U qt5-base-5.10.0-2-x86_64.pkg.tar.xz --noconfirm;

# Install qt5-styleplugins
RUN set -xe; \
    cd /var/tmp/; \
    sudo -u build wget https://aur.archlinux.org/cgit/aur.git/snapshot/qt5-styleplugins-git.tar.gz; \
    sudo -u build tar xfv qt5-styleplugins-git.tar.gz; \
    rm qt5-styleplugins-git.tar.gz; \
    cd qt5-styleplugins-git; \
    sudo -u build makepkg -si --noconfirm; \
    cd ..; \
    rm -rf qt5-styleplugins-git;

# RUN set -xe; \
#     chown -R build:build /build/brink-packages; \
#     cd /build/brink-packages/calamares; \
#     sudo -u build makepkg -si --noconfirm;
