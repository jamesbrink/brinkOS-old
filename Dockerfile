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
    pacman -S base base-devel cmake automake autoconf wget vim archiso openssh git --noconfirm;

# Copy in brinkOS assets
COPY ./brinkOS /build

# If building on a debian host, dev/shm points to /run/shm
# and will fail without this directory.
RUN mkdir -p /build/archiso/work/x86_64/airootfs/run/shm; \
    mkdir -p /build/archiso/work/x86_64/airootfs/var/run/shm; \
    mkdir -p /run/shm; \
    mkdir -p /var/run/shm;

# Create prepare our build.
RUN set -xe; \
    mkdir -p /build/brinkOS-packages; \
    chown -R build:build /build;

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

ENV GTK_THEME="Arctic-brinkOS" \
    SHELL_THEME="Arctic-brinkOS" \
    ICON_THEME="brinkOS-Icons" \
    WALLPAPER="file:///usr/share/backgrounds/gnome/bear-rock.jpg"

# Set our entrypoint which kicks off our build.
ENTRYPOINT [ "/build/docker-entrypoint.sh" ]