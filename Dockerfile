# syntax=docker/dockerfile:1
#
# Maximal full-featured FFmpeg BUILD IMAGE — FULL-BUILD (everything from source).
#
# This is a SINGLE-STAGE build *environment*. Per docs/todo/001-full-build.md it no longer
# apt-installs any libraries: the entire toolchain (gcc/binutils + gmp/mpfr/mpc/isl), the build
# tools (cmake/ninja/meson/nasm/yasm/autotools/python + their deps) AND every media library
# FFmpeg links are compiled FROM SOURCE into /usr/local, in dependency order, one phase per RUN.
#
# Only the OS floor + a throwaway BOOTSTRAP SEED stay from apt: glibc/coreutils/bash, plus a
# seed gcc/make/perl used solely to compile our own gcc (a compiler cannot build itself from
# nothing — even Linux From Scratch bootstraps off the host toolchain). The seed never ends up
# in the shipped artifact.
#
# patchelf is GONE. Relocatability is baked at LINK time: gcc.sh installs a `specs` file so our
# from-source gcc gives every binary/library a relocatable $ORIGIN DT_RPATH. See
# scripts/deps/common.sh (ORIGIN_SPECS) and scripts/deps/gcc.sh.
#
# FFmpeg itself is still NEITHER fetched NOR compiled during `docker build`; the ENTRYPOINT
# (scripts/build-ffmpeg.sh) downloads + configures + builds + installs + verifies it at
# `docker run` time, then exports a self-contained relocatable bundle to /output.
#
#   docker build -t ffmpeg-build .
#   docker run --rm -v "$PWD/out:/output" ffmpeg-build
#
# The build is GPL + version3 + nonfree (links fdk-aac) -> the resulting binary is NOT
# redistributable; intended for personal / internal / server use.

############################################################
# build-image — bootstrap seed, then EVERYTHING from source
############################################################
FROM ubuntu:24.04 AS build-image

ENV DEBIAN_FRONTEND=noninteractive
# /usr/local/bin FIRST so our from-source tools (pkg-config, gcc, nasm, cmake, python, …) shadow
# the apt seed as soon as each is built.
ENV PATH="/usr/local/bin:${PATH}"
# Our from-source pkgconf resolves /usr/local first.
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/share/pkgconfig"
# lib64 included: our from-source gcc installs libstdc++/libgcc_s under /usr/local/lib64.
ENV LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64"
ENV SRCROOT="/tmp/src"

# --- bootstrap SEED only: OS-floor build tools needed to compile our own toolchain ----------
# NO libraries, NO cmake/meson/ninja/nasm/yasm/pkg-config, NO patchelf — all built from source.
# build-essential = seed gcc/g++/make/libc6-dev (+ kernel UAPI headers via linux-libc-dev).
# m4 is required by GMP's configure (phase 1, before our own m4 exists); perl/gettext/texinfo/
# patch are OS-floor tools many `./configure`/`make` steps invoke.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        m4 \
        ca-certificates \
        curl \
        wget \
        git \
        xz-utils \
        bzip2 \
        file \
        patch \
        perl \
        gettext \
        texinfo; \
    rm -rf /var/lib/apt/lists/*

# Source-built libs land in /usr/local; make sure the loader sees them across RUN layers.
RUN set -eux; \
    { echo "/usr/local/lib"; \
      echo "/usr/local/lib64"; \
      echo "/usr/local/lib/x86_64-linux-gnu"; } > /etc/ld.so.conf.d/ffmpeg-local.conf; \
    ldconfig

# --- dependency scripts. Split into TWO COPY layers for cache granularity: the toolchain +
#     build-tool scripts (phases 0-2) are copied FIRST, so editing a media-library recipe (the
#     common case during phase-3 iteration) does NOT bust the expensive cached toolchain layers
#     below — only the phase-3 layers rebuild. common.sh is the shared contract; editing it
#     (correctly) invalidates everything. -----------------------------------------------------
COPY scripts/deps/common.sh \
     scripts/deps/pkgconf.sh \
     scripts/deps/zlib.sh scripts/deps/zstd.sh scripts/deps/bzip2.sh scripts/deps/xz.sh \
     scripts/deps/gmp.sh scripts/deps/mpfr.sh scripts/deps/mpc.sh scripts/deps/isl.sh \
     scripts/deps/binutils.sh scripts/deps/gcc.sh \
     scripts/deps/m4.sh scripts/deps/autoconf.sh scripts/deps/automake.sh scripts/deps/libtool.sh \
     scripts/deps/nasm.sh scripts/deps/yasm.sh \
     scripts/deps/libffi.sh scripts/deps/openssl.sh scripts/deps/ncurses.sh scripts/deps/readline.sh \
     scripts/deps/python.sh \
     scripts/deps/ninja.sh scripts/deps/cmake.sh scripts/deps/meson.sh \
     /opt/scripts/deps/

# Each RUN builds one dependency PHASE in order. Grouping (vs one-RUN-per-lib) keeps the layer
# count sane for ~130 packages while preserving coarse caching + clear failure isolation.
# `set -e` aborts the layer on the first failing script.

# ---- phase 0: pkg-config (needed by every later verify step) -------------------------------
RUN set -e; for s in pkgconf; do bash /opt/scripts/deps/$s.sh; done

# ---- phase 1: toolchain (built by the seed compiler) ---------------------------------------
RUN set -e; for s in zlib zstd bzip2 xz; do bash /opt/scripts/deps/$s.sh; done
RUN set -e; for s in gmp mpfr mpc isl; do bash /opt/scripts/deps/$s.sh; done
RUN set -e; for s in binutils; do bash /opt/scripts/deps/$s.sh; done
# gcc is the pivotal/slowest layer + installs the $ORIGIN specs; keep it isolated for caching.
RUN set -e; for s in gcc; do bash /opt/scripts/deps/$s.sh; done

# ---- phase 2: build tools (built by OUR gcc; relocatable from here on) ----------------------
RUN set -e; for s in m4 autoconf automake libtool nasm yasm; do bash /opt/scripts/deps/$s.sh; done
RUN set -e; for s in libffi openssl ncurses readline; do bash /opt/scripts/deps/$s.sh; done
RUN set -e; for s in python; do bash /opt/scripts/deps/$s.sh; done
RUN set -e; for s in ninja cmake meson; do bash /opt/scripts/deps/$s.sh; done

# autopoint (gettext): needed by some phase-3 autotools libs (e.g. fontconfig) whose
# configure.ac uses AM_GNU_GETTEXT — autoreconf invokes autopoint to stage the gettext
# infrastructure (config.rpath + m4 macros) into the source tree, else automake fails with
# "required file './config.rpath' not found". autopoint is only a Recommends of the seed
# `gettext`, so --no-install-recommends skipped it. Install it HERE (after the cached toolchain
# layers, before phase 3) so it does not invalidate the expensive gcc layer above.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends autopoint; \
    rm -rf /var/lib/apt/lists/*

# media-library scripts copied HERE (after the toolchain RUNs) so editing a media recipe does
# not invalidate the cached phases 0-2 above. This re-copies the whole deps/ dir (incl. the
# already-copied toolchain scripts; identical content keeps their layers cached).
COPY scripts/deps/ /opt/scripts/deps/

# ---- phase 3: media libraries (built by OUR gcc; all get $ORIGIN rpath) --------------------
# base codec/filter deps
RUN set -e; for s in libogg libpng libjpeg-turbo expat gperf fftw lcms2; do bash /opt/scripts/deps/$s.sh; done
# video encoders/decoders (apt-replaced)
RUN set -e; for s in x264 x265 xvid libvpx aom dav1d svtav1 openh264 libtheora libwebp openjpeg; do bash /opt/scripts/deps/$s.sh; done
# video encoders/decoders (already source-built; no apt equivalent)
# uavs3d omitted: --enable-libuavs3d is not passed (its v1.x API is too old for FFmpeg 8.1.1),
# so building it only adds a fragile, unused gcc-14 compile. (Recipe kept in scripts/deps/.)
RUN set -e; for s in vvenc xeve xevd xavs2 davs2 rav1e; do bash /opt/scripts/deps/$s.sh; done
# audio codecs
RUN set -e; for s in lame opus libvorbis fdk-aac twolame libgsm speex speexdsp opencore-amr vo-amrwbenc shine codec2 libmysofa; do bash /opt/scripts/deps/$s.sh; done
# subtitles / text / fonts
RUN set -e; for s in freetype fribidi fontconfig harfbuzz libass; do bash /opt/scripts/deps/$s.sh; done
# filters
RUN set -e; for s in aribb24 libaribcaption zimg rubberband soxr vidstab frei0r ladspa libbs2b flite; do bash /opt/scripts/deps/$s.sh; done
# OCR + quality metric
RUN set -e; for s in leptonica tesseract libvmaf; do bash /opt/scripts/deps/$s.sh; done
# TLS stack
RUN set -e; for s in nettle libtasn1 libunistring p11-kit gnutls; do bash /opt/scripts/deps/$s.sh; done
# network protocols
RUN set -e; for s in librtmp libsrt libssh libzmq librist; do bash /opt/scripts/deps/$s.sh; done
# demux / containers / sources
RUN set -e; for s in libxml2 snappy libgme libmodplug libopenmpt chromaprint libcaca; do bash /opt/scripts/deps/$s.sh; done
RUN set -e; for s in libusb libraw1394 libdc1394 libcdio libcdio-paranoia; do bash /opt/scripts/deps/$s.sh; done
RUN set -e; for s in libbluray; do bash /opt/scripts/deps/$s.sh; done
# X11 / XCB stack (FFmpeg --enable-libxcb screen grab + SDL2)
RUN set -e; for s in util-macros xorgproto libxau libxdmcp xcb-proto libpthread-stubs libxcb; do bash /opt/scripts/deps/$s.sh; done
# audio/video devices
RUN set -e; for s in alsa-lib; do bash /opt/scripts/deps/$s.sh; done
RUN set -e; for s in sndio openal-soft sdl2; do bash /opt/scripts/deps/$s.sh; done
# hardware acceleration: drm / vaapi / vdpau / v4l
RUN set -e; for s in libdrm libva libvdpau v4l-utils; do bash /opt/scripts/deps/$s.sh; done
# vulkan (headers + from-source loader)
RUN set -e; for s in vulkan-headers vulkan-loader; do bash /opt/scripts/deps/$s.sh; done
# shader compiler stack (libplacebo compute / --enable-libshaderc)
RUN set -e; for s in spirv-headers spirv-tools glslang shaderc; do bash /opt/scripts/deps/$s.sh; done
# opengl (libglvnd) / opencl loader / oneVPL
RUN set -e; for s in libglvnd opencl-headers ocl-icd libvpl; do bash /opt/scripts/deps/$s.sh; done
# GPU codec headers (nvenc/nvdec/cuvid/ffnvcodec + AMD AMF)
RUN set -e; for s in nv-codec-headers amf; do bash /opt/scripts/deps/$s.sh; done
# libplacebo LAST: needs vulkan-loader + shaderc + lcms2 above
RUN set -e; for s in libplacebo; do bash /opt/scripts/deps/$s.sh; done

# Latest stable verified in the research spec.
ARG FFMPEG_VERSION=8.1.1
ENV FFMPEG_VERSION=${FFMPEG_VERSION}

# --- entrypoint scripts copied LAST so edits to them reuse all cached dep layers above -------
# NO FFmpeg source and NO FFmpeg compile happen in this image. The ENTRYPOINT downloads +
# configures + builds + installs + verifies FFmpeg with OUR gcc AT `docker run` TIME, and the
# resulting bundle is relocatable via the baked $ORIGIN rpath (verified with readelf; no patchelf).
COPY scripts/build-ffmpeg.sh scripts/build-deps.sh /opt/scripts/

ENTRYPOINT ["bash", "/opt/scripts/build-ffmpeg.sh"]
