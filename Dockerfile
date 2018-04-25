FROM base/archlinux:2018.04.01

# Build arguments.
ARG VCS_REF
ARG BUILD_DATE
ARG VARNISH_VERSION="0.0.0"

# Labels / Metadata.
LABEL maintainer="James Brink, brink.james@gmail.com" \
    decription="Varnish" \
    version="${VARNISH_VERSION}" \
    org.label-schema.name="varnish" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/jamesbrink/docker-varnish" \
    org.label-schema.schema-version="1.0.0-rc1"

# Create user for AUR builds.
RUN set -xe; \
    useradd --no-create-home --shell=/bin/false build && usermod -L build; \
    echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers; \
    echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers;

# Install all needed deps and compile the mesa llvmpipe driver from source.
RUN set -xe; \
    pacman -Syu --noconfirm; \
    pacman -S base-devel cmake automake autoconf wget vim archiso --noconfirm;
