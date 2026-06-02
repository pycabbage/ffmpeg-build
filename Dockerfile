# syntax=docker/dockerfile:1
#
# Maximal full-featured FFmpeg BUILD IMAGE.
#
# This is a SINGLE-STAGE image: it is the *environment* for building FFmpeg, not a
# compiled FFmpeg. `docker build` installs all build tooling, every apt -dev dependency
# and every source-built dependency. FFmpeg itself is NEITHER fetched NOR compiled during
# `docker build` -- the image contains no FFmpeg source and no FFmpeg binary.
#
# FFmpeg is downloaded AND compiled at `docker run` time: the ENTRYPOINT runs
# scripts/build-ffmpeg.sh, which downloads the FFmpeg source, then configures + builds +
# installs + verifies FFmpeg inside the running container.
#
# Build the build-image:   docker build -t ffmpeg-build .
# Compile FFmpeg:           docker run --rm ffmpeg-build
# Compile + extract bins:   docker run --rm -v "$PWD/out:/output" ffmpeg-build
#
# The build is a GPL + version3 + nonfree variant (links fdk-aac). The resulting binary is
# therefore NOT redistributable -- it is intended for personal / internal / server use.

############################################################
# build-image — toolchain + apt deps + source-built deps
############################################################
FROM ubuntu:24.04 AS build-image

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/bin:${PATH}"
# pkg-config must find both apt multiarch .pc files and source-built /usr/local ones.
# /usr/local is listed FIRST so source-built libs take precedence over apt ones.
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig"
# Rust (rav1e) toolchain lives here so it is on PATH for the rav1e layer.
ENV RUSTUP_HOME="/opt/rust/rustup" CARGO_HOME="/opt/rust/cargo"
ENV PATH="/opt/rust/cargo/bin:${PATH}"

# --- enable universe + multiverse, then install build tooling + all -dev deps ---
# Only packages reported AVAILABLE on ubuntu:24.04 are installed here. Packages reported
# missing (libkvazaar-dev, libilbc-dev, libvmaf-dev) are NOT installed; libvmaf is built
# from source instead, and kvazaar/ilbc are intentionally omitted (no provider).
RUN set -eux; \
    sed -i '/^Components:/ s/$/ universe multiverse/' \
        /etc/apt/sources.list.d/ubuntu.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        nasm \
        yasm \
        patchelf \
        pkg-config \
        cmake \
        meson \
        ninja-build \
        git \
        ca-certificates \
        curl \
        wget \
        python3 \
        python3-pip \
        autoconf \
        automake \
        libtool \
        texinfo \
        clang \
        xxd \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libxml2-dev \
        libgnutls28-dev \
        libssl-dev \
        libsnappy-dev \
        libgmp-dev \
        libffi-dev \
        libx264-dev \
        libx265-dev \
        libxvidcore-dev \
        libvpx-dev \
        libaom-dev \
        libdav1d-dev \
        libsvtav1-dev \
        libsvtav1enc-dev \
        libtheora-dev \
        libopenh264-dev \
        libde265-dev \
        libwebp-dev \
        libopenjp2-7-dev \
        libmp3lame-dev \
        libopus-dev \
        libvorbis-dev \
        libfdk-aac-dev \
        libtwolame-dev \
        libgsm1-dev \
        libspeex-dev \
        libopencore-amrnb-dev \
        libopencore-amrwb-dev \
        libvo-amrwbenc-dev \
        libshine-dev \
        libcodec2-dev \
        libmysofa-dev \
        libass-dev \
        libfreetype-dev \
        libfribidi-dev \
        libfontconfig1-dev \
        libharfbuzz-dev \
        libaribb24-dev \
        libzimg-dev \
        librubberband-dev \
        libsoxr-dev \
        libvidstab-dev \
        frei0r-plugins-dev \
        ladspa-sdk \
        libbs2b-dev \
        liblcms2-dev \
        libplacebo-dev \
        libtesseract-dev \
        libleptonica-dev \
        liblensfun-dev \
        librtmp-dev \
        libsrt-gnutls-dev \
        libssh-dev \
        libzmq3-dev \
        librist-dev \
        libsmbclient-dev \
        libbluray-dev \
        libopenmpt-dev \
        libgme-dev \
        libmodplug-dev \
        libchromaprint-dev \
        libcaca-dev \
        libva-dev \
        libvdpau-dev \
        libvulkan-dev \
        ocl-icd-opencl-dev \
        opencl-headers \
        libvpl-dev \
        libdrm-dev \
        libshaderc-dev \
        glslang-tools \
        spirv-tools \
        libdc1394-dev \
        libcdio-dev \
        libcdio-paranoia-dev \
        libopenal-dev \
        libpulse-dev \
        libsdl2-dev \
        libxcb1-dev \
        libxcb-shm0-dev \
        libxcb-xfixes0-dev \
        libxcb-shape0-dev \
        libv4l-dev \
        libjack-jackd2-dev \
        libasound2-dev \
        libsndio-dev \
        libgl1-mesa-dev \
        libegl1-mesa-dev \
        libgles2-mesa-dev \
        flite1-dev; \
    rm -rf /var/lib/apt/lists/*

# Source-built libs land in /usr/local; make sure the loader sees them.
RUN set -eux; \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/ffmpeg-local.conf; \
    ldconfig

# --- source-built dependencies, one RUN per lib for cacheability ---
# Only the dependency scripts are copied here (BEFORE the dependency RUN lines) so that
# editing build-ffmpeg.sh / build-deps.sh does NOT invalidate these cached dep layers.
# A failure in one library does not invalidate the layers above/below it.
COPY scripts/deps/ /opt/scripts/deps/

RUN bash /opt/scripts/deps/nv-codec-headers.sh
RUN bash /opt/scripts/deps/amf.sh
# Newer Vulkan-Headers + libplacebo source builds restore --enable-vulkan and
# --enable-libplacebo (Ubuntu 24.04's apt versions are too old). vulkan-headers MUST run
# before libplacebo: libplacebo's vulkan backend needs the newer headers + shadowing .pc.
RUN bash /opt/scripts/deps/vulkan-headers.sh
RUN bash /opt/scripts/deps/libplacebo.sh
RUN bash /opt/scripts/deps/vvenc.sh
RUN bash /opt/scripts/deps/xeve.sh
RUN bash /opt/scripts/deps/xevd.sh
RUN bash /opt/scripts/deps/uavs3d.sh
RUN bash /opt/scripts/deps/xavs2.sh
RUN bash /opt/scripts/deps/davs2.sh
RUN bash /opt/scripts/deps/libaribcaption.sh
RUN bash /opt/scripts/deps/libvmaf.sh
RUN bash /opt/scripts/deps/rav1e.sh

# Latest stable verified in the research spec.
ARG FFMPEG_VERSION=8.1.1
ENV FFMPEG_VERSION=${FFMPEG_VERSION}

# --- entrypoint script copied LAST so edits to it reuse all cached dep layers above ---
# NO FFmpeg source and NO FFmpeg compile happen in this image. The ENTRYPOINT script
# downloads + configures + builds + installs + verifies FFmpeg AT `docker run` TIME.
COPY scripts/build-ffmpeg.sh scripts/build-deps.sh /opt/scripts/

# `docker run <image>` downloads + compiles FFmpeg inside the container, installs it, and
# runs the verification suite. Pass extra args to override (e.g. `docker run ... bash`).
ENTRYPOINT ["bash", "/opt/scripts/build-ffmpeg.sh"]
