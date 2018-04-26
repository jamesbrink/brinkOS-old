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

# Install all needed deps and compile the mesa llvmpipe driver from source.
RUN set -xe; \
    pacman -Syu --noconfirm; \
    pacman -S base base-devel cmake automake autoconf wget vim archiso openssh git --noconfirm;

# Copy in brinkOS assets
COPY ./brinkOS /build

# Create prepare our build.
RUN set -xe; \
    mkdir -p /build/brinkOS-packages; \
    chown -R build:build /build;
    

# Build brinkOS Icons package.
RUN set -xe; \
    cd /build/packages/brinkOS-icons; \
    sudo -u build makepkg; \
    repo-add /build/brinkOS-packages/repo.db.tar.gz brinkOS-icons-1.0.0-1-any.pkg.tar.xz; 

# Set our entrypoint which kicks off our build.
ENTRYPOINT [ "/build/docker-entrypoint.sh" ]