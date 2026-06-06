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
# patchelf is GONE. Relocatability is baked at LINK time: our from-source gcc gives every
# binary/library a relocatable $ORIGIN DT_RPATH (via LD_RUN_PATH + binutils --disable-new-dtags;
# see scripts/deps/common.sh and scripts/deps/gcc.sh).
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
# Build parallelism. Empty default -> common.sh falls back to nproc (CI/full-speed). A constrained
# host can cap peak CPU/memory with `--build-arg JOBS=N` (e.g. local builds on a small box).
# common.sh does `: "${JOBS:=$(nproc)}"`, and `:=` treats the empty string as unset, so JOBS=""
# transparently becomes nproc inside every RUN — CI behavior is unchanged when JOBS is not passed.
ARG JOBS=
ENV JOBS=${JOBS}

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

# --- dependency build recipes are BIND-MOUNTED per RUN (no COPY) -----------------------------
# Each RUN below bind-mounts ONLY common.sh + the recipes it actually runs. BuildKit keys a
# RUN's cache on the *content of its bind-mounted sources*, so editing one recipe (the common
# case during phase-3 iteration) invalidates ONLY the RUN that mounts it — plus the RUNs chained
# after it — while every earlier RUN (the expensive toolchain + video layers) stays cached. A
# `COPY scripts/deps/` layer would instead sit before all build RUNs and bust EVERY later layer
# on any single-file edit. The recipes execute only during `docker build`, so they need not
# persist in the image (unlike the ENTRYPOINT scripts, COPYed last). common.sh is the shared
# contract: it is mounted into every RUN, so editing it (correctly) invalidates everything.
# Grouping libs per RUN (vs one-RUN-per-lib) keeps the layer count sane; `set -e` aborts the
# layer on the first failing recipe.

# ---- phase 0: pkg-config (needed by every later verify step) -------------------------------
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/pkgconf.sh,target=/opt/scripts/deps/pkgconf.sh \
    set -e; for s in pkgconf; do bash /opt/scripts/deps/$s.sh; done

# ---- phase 1: toolchain (built by the seed compiler) ---------------------------------------
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/zlib.sh,target=/opt/scripts/deps/zlib.sh \
    --mount=type=bind,source=scripts/deps/zstd.sh,target=/opt/scripts/deps/zstd.sh \
    --mount=type=bind,source=scripts/deps/bzip2.sh,target=/opt/scripts/deps/bzip2.sh \
    --mount=type=bind,source=scripts/deps/xz.sh,target=/opt/scripts/deps/xz.sh \
    set -e; for s in zlib zstd bzip2 xz; do bash /opt/scripts/deps/$s.sh; done
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/gmp.sh,target=/opt/scripts/deps/gmp.sh \
    --mount=type=bind,source=scripts/deps/mpfr.sh,target=/opt/scripts/deps/mpfr.sh \
    --mount=type=bind,source=scripts/deps/mpc.sh,target=/opt/scripts/deps/mpc.sh \
    --mount=type=bind,source=scripts/deps/isl.sh,target=/opt/scripts/deps/isl.sh \
    set -e; for s in gmp mpfr mpc isl; do bash /opt/scripts/deps/$s.sh; done
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/binutils.sh,target=/opt/scripts/deps/binutils.sh \
    set -e; for s in binutils; do bash /opt/scripts/deps/$s.sh; done
# gcc is the pivotal/slowest layer; keep it isolated for caching.
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/gcc.sh,target=/opt/scripts/deps/gcc.sh \
    set -e; for s in gcc; do bash /opt/scripts/deps/$s.sh; done

# ---- phase 2: build tools (built by OUR gcc; relocatable from here on) ----------------------
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/m4.sh,target=/opt/scripts/deps/m4.sh \
    --mount=type=bind,source=scripts/deps/autoconf.sh,target=/opt/scripts/deps/autoconf.sh \
    --mount=type=bind,source=scripts/deps/automake.sh,target=/opt/scripts/deps/automake.sh \
    --mount=type=bind,source=scripts/deps/libtool.sh,target=/opt/scripts/deps/libtool.sh \
    --mount=type=bind,source=scripts/deps/nasm.sh,target=/opt/scripts/deps/nasm.sh \
    --mount=type=bind,source=scripts/deps/yasm.sh,target=/opt/scripts/deps/yasm.sh \
    set -e; for s in m4 autoconf automake libtool nasm yasm; do bash /opt/scripts/deps/$s.sh; done
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/libffi.sh,target=/opt/scripts/deps/libffi.sh \
    --mount=type=bind,source=scripts/deps/openssl.sh,target=/opt/scripts/deps/openssl.sh \
    --mount=type=bind,source=scripts/deps/ncurses.sh,target=/opt/scripts/deps/ncurses.sh \
    --mount=type=bind,source=scripts/deps/readline.sh,target=/opt/scripts/deps/readline.sh \
    set -e; for s in libffi openssl ncurses readline; do bash /opt/scripts/deps/$s.sh; done
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/python.sh,target=/opt/scripts/deps/python.sh \
    set -e; for s in python; do bash /opt/scripts/deps/$s.sh; done
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/ninja.sh,target=/opt/scripts/deps/ninja.sh \
    --mount=type=bind,source=scripts/deps/cmake.sh,target=/opt/scripts/deps/cmake.sh \
    --mount=type=bind,source=scripts/deps/meson.sh,target=/opt/scripts/deps/meson.sh \
    set -e; for s in ninja cmake meson; do bash /opt/scripts/deps/$s.sh; done

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

# Our from-source cmake is 4.x, which removed compatibility with cmake_minimum_required(VERSION
# <3.5). Several phase-3 libs ship ancient CMakeLists (e.g. soxr, vidstab, frei0r) and would fail
# "Compatibility with CMake < 3.5 has been removed". This env var (honored by CMake >=3.31) raises
# the policy floor to 3.5 ONLY for projects declaring a lower minimum; it is a no-op for modern
# projects. Set globally so every phase-3 cmake build is covered. (FFmpeg itself does not use
# cmake, so leaving it set in the final image is harmless.)
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

# ---- phase 3: media libraries (built by OUR gcc; all get $ORIGIN rpath) --------------------
# base codec/filter deps
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/libogg.sh,target=/opt/scripts/deps/libogg.sh \
    --mount=type=bind,source=scripts/deps/libpng.sh,target=/opt/scripts/deps/libpng.sh \
    --mount=type=bind,source=scripts/deps/libjpeg-turbo.sh,target=/opt/scripts/deps/libjpeg-turbo.sh \
    --mount=type=bind,source=scripts/deps/expat.sh,target=/opt/scripts/deps/expat.sh \
    --mount=type=bind,source=scripts/deps/gperf.sh,target=/opt/scripts/deps/gperf.sh \
    --mount=type=bind,source=scripts/deps/fftw.sh,target=/opt/scripts/deps/fftw.sh \
    --mount=type=bind,source=scripts/deps/lcms2.sh,target=/opt/scripts/deps/lcms2.sh \
    set -e; for s in libogg libpng libjpeg-turbo expat gperf fftw lcms2; do bash /opt/scripts/deps/$s.sh; done
# video encoders/decoders (apt-replaced)
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/x264.sh,target=/opt/scripts/deps/x264.sh \
    --mount=type=bind,source=scripts/deps/x265.sh,target=/opt/scripts/deps/x265.sh \
    --mount=type=bind,source=scripts/deps/xvid.sh,target=/opt/scripts/deps/xvid.sh \
    --mount=type=bind,source=scripts/deps/libvpx.sh,target=/opt/scripts/deps/libvpx.sh \
    --mount=type=bind,source=scripts/deps/aom.sh,target=/opt/scripts/deps/aom.sh \
    --mount=type=bind,source=scripts/deps/dav1d.sh,target=/opt/scripts/deps/dav1d.sh \
    --mount=type=bind,source=scripts/deps/svtav1.sh,target=/opt/scripts/deps/svtav1.sh \
    --mount=type=bind,source=scripts/deps/openh264.sh,target=/opt/scripts/deps/openh264.sh \
    --mount=type=bind,source=scripts/deps/libtheora.sh,target=/opt/scripts/deps/libtheora.sh \
    --mount=type=bind,source=scripts/deps/libwebp.sh,target=/opt/scripts/deps/libwebp.sh \
    --mount=type=bind,source=scripts/deps/openjpeg.sh,target=/opt/scripts/deps/openjpeg.sh \
    set -e; for s in x264 x265 xvid libvpx aom dav1d svtav1 openh264 libtheora libwebp openjpeg; do bash /opt/scripts/deps/$s.sh; done
# video encoders/decoders (already source-built; no apt equivalent)
# uavs3d omitted: --enable-libuavs3d is not passed (its v1.x API is too old for FFmpeg 8.1.1).
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/vvenc.sh,target=/opt/scripts/deps/vvenc.sh \
    --mount=type=bind,source=scripts/deps/xeve.sh,target=/opt/scripts/deps/xeve.sh \
    --mount=type=bind,source=scripts/deps/xevd.sh,target=/opt/scripts/deps/xevd.sh \
    --mount=type=bind,source=scripts/deps/xavs2.sh,target=/opt/scripts/deps/xavs2.sh \
    --mount=type=bind,source=scripts/deps/davs2.sh,target=/opt/scripts/deps/davs2.sh \
    --mount=type=bind,source=scripts/deps/rav1e.sh,target=/opt/scripts/deps/rav1e.sh \
    set -e; for s in vvenc xeve xevd xavs2 davs2 rav1e; do bash /opt/scripts/deps/$s.sh; done
# audio codecs
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/lame.sh,target=/opt/scripts/deps/lame.sh \
    --mount=type=bind,source=scripts/deps/opus.sh,target=/opt/scripts/deps/opus.sh \
    --mount=type=bind,source=scripts/deps/libvorbis.sh,target=/opt/scripts/deps/libvorbis.sh \
    --mount=type=bind,source=scripts/deps/fdk-aac.sh,target=/opt/scripts/deps/fdk-aac.sh \
    --mount=type=bind,source=scripts/deps/twolame.sh,target=/opt/scripts/deps/twolame.sh \
    --mount=type=bind,source=scripts/deps/libgsm.sh,target=/opt/scripts/deps/libgsm.sh \
    --mount=type=bind,source=scripts/deps/speex.sh,target=/opt/scripts/deps/speex.sh \
    --mount=type=bind,source=scripts/deps/speexdsp.sh,target=/opt/scripts/deps/speexdsp.sh \
    --mount=type=bind,source=scripts/deps/opencore-amr.sh,target=/opt/scripts/deps/opencore-amr.sh \
    --mount=type=bind,source=scripts/deps/vo-amrwbenc.sh,target=/opt/scripts/deps/vo-amrwbenc.sh \
    --mount=type=bind,source=scripts/deps/shine.sh,target=/opt/scripts/deps/shine.sh \
    --mount=type=bind,source=scripts/deps/codec2.sh,target=/opt/scripts/deps/codec2.sh \
    --mount=type=bind,source=scripts/deps/libmysofa.sh,target=/opt/scripts/deps/libmysofa.sh \
    set -e; for s in lame opus libvorbis fdk-aac twolame libgsm speex speexdsp opencore-amr vo-amrwbenc shine codec2 libmysofa; do bash /opt/scripts/deps/$s.sh; done
# subtitles / text / fonts
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/freetype.sh,target=/opt/scripts/deps/freetype.sh \
    --mount=type=bind,source=scripts/deps/fribidi.sh,target=/opt/scripts/deps/fribidi.sh \
    --mount=type=bind,source=scripts/deps/fontconfig.sh,target=/opt/scripts/deps/fontconfig.sh \
    --mount=type=bind,source=scripts/deps/harfbuzz.sh,target=/opt/scripts/deps/harfbuzz.sh \
    --mount=type=bind,source=scripts/deps/libass.sh,target=/opt/scripts/deps/libass.sh \
    set -e; for s in freetype fribidi fontconfig harfbuzz libass; do bash /opt/scripts/deps/$s.sh; done
# filters
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/aribb24.sh,target=/opt/scripts/deps/aribb24.sh \
    --mount=type=bind,source=scripts/deps/libaribcaption.sh,target=/opt/scripts/deps/libaribcaption.sh \
    --mount=type=bind,source=scripts/deps/zimg.sh,target=/opt/scripts/deps/zimg.sh \
    --mount=type=bind,source=scripts/deps/rubberband.sh,target=/opt/scripts/deps/rubberband.sh \
    --mount=type=bind,source=scripts/deps/soxr.sh,target=/opt/scripts/deps/soxr.sh \
    --mount=type=bind,source=scripts/deps/vidstab.sh,target=/opt/scripts/deps/vidstab.sh \
    --mount=type=bind,source=scripts/deps/frei0r.sh,target=/opt/scripts/deps/frei0r.sh \
    --mount=type=bind,source=scripts/deps/ladspa.sh,target=/opt/scripts/deps/ladspa.sh \
    --mount=type=bind,source=scripts/deps/libbs2b.sh,target=/opt/scripts/deps/libbs2b.sh \
    --mount=type=bind,source=scripts/deps/flite.sh,target=/opt/scripts/deps/flite.sh \
    set -e; for s in aribb24 libaribcaption zimg rubberband soxr vidstab frei0r ladspa libbs2b flite; do bash /opt/scripts/deps/$s.sh; done
# OCR + quality metric
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/leptonica.sh,target=/opt/scripts/deps/leptonica.sh \
    --mount=type=bind,source=scripts/deps/tesseract.sh,target=/opt/scripts/deps/tesseract.sh \
    --mount=type=bind,source=scripts/deps/libvmaf.sh,target=/opt/scripts/deps/libvmaf.sh \
    set -e; for s in leptonica tesseract libvmaf; do bash /opt/scripts/deps/$s.sh; done
# TLS stack
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/nettle.sh,target=/opt/scripts/deps/nettle.sh \
    --mount=type=bind,source=scripts/deps/libtasn1.sh,target=/opt/scripts/deps/libtasn1.sh \
    --mount=type=bind,source=scripts/deps/libunistring.sh,target=/opt/scripts/deps/libunistring.sh \
    --mount=type=bind,source=scripts/deps/p11-kit.sh,target=/opt/scripts/deps/p11-kit.sh \
    --mount=type=bind,source=scripts/deps/gnutls.sh,target=/opt/scripts/deps/gnutls.sh \
    set -e; for s in nettle libtasn1 libunistring p11-kit gnutls; do bash /opt/scripts/deps/$s.sh; done
# network protocols
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/librtmp.sh,target=/opt/scripts/deps/librtmp.sh \
    --mount=type=bind,source=scripts/deps/libsrt.sh,target=/opt/scripts/deps/libsrt.sh \
    --mount=type=bind,source=scripts/deps/libssh.sh,target=/opt/scripts/deps/libssh.sh \
    --mount=type=bind,source=scripts/deps/libzmq.sh,target=/opt/scripts/deps/libzmq.sh \
    --mount=type=bind,source=scripts/deps/librist.sh,target=/opt/scripts/deps/librist.sh \
    set -e; for s in librtmp libsrt libssh libzmq librist; do bash /opt/scripts/deps/$s.sh; done
# demux / containers / sources
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/libxml2.sh,target=/opt/scripts/deps/libxml2.sh \
    --mount=type=bind,source=scripts/deps/snappy.sh,target=/opt/scripts/deps/snappy.sh \
    --mount=type=bind,source=scripts/deps/libgme.sh,target=/opt/scripts/deps/libgme.sh \
    --mount=type=bind,source=scripts/deps/libmodplug.sh,target=/opt/scripts/deps/libmodplug.sh \
    --mount=type=bind,source=scripts/deps/libopenmpt.sh,target=/opt/scripts/deps/libopenmpt.sh \
    --mount=type=bind,source=scripts/deps/chromaprint.sh,target=/opt/scripts/deps/chromaprint.sh \
    --mount=type=bind,source=scripts/deps/libcaca.sh,target=/opt/scripts/deps/libcaca.sh \
    set -e; for s in libxml2 snappy libgme libmodplug libopenmpt chromaprint libcaca; do bash /opt/scripts/deps/$s.sh; done
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/libusb.sh,target=/opt/scripts/deps/libusb.sh \
    --mount=type=bind,source=scripts/deps/libraw1394.sh,target=/opt/scripts/deps/libraw1394.sh \
    --mount=type=bind,source=scripts/deps/libdc1394.sh,target=/opt/scripts/deps/libdc1394.sh \
    --mount=type=bind,source=scripts/deps/libcdio.sh,target=/opt/scripts/deps/libcdio.sh \
    --mount=type=bind,source=scripts/deps/libcdio-paranoia.sh,target=/opt/scripts/deps/libcdio-paranoia.sh \
    set -e; for s in libusb libraw1394 libdc1394 libcdio libcdio-paranoia; do bash /opt/scripts/deps/$s.sh; done
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/libbluray.sh,target=/opt/scripts/deps/libbluray.sh \
    set -e; for s in libbluray; do bash /opt/scripts/deps/$s.sh; done
# X11 / XCB stack (FFmpeg --enable-libxcb screen grab + SDL2; libX11 for vdpau / opengl-GLX)
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/util-macros.sh,target=/opt/scripts/deps/util-macros.sh \
    --mount=type=bind,source=scripts/deps/xorgproto.sh,target=/opt/scripts/deps/xorgproto.sh \
    --mount=type=bind,source=scripts/deps/libxau.sh,target=/opt/scripts/deps/libxau.sh \
    --mount=type=bind,source=scripts/deps/libxdmcp.sh,target=/opt/scripts/deps/libxdmcp.sh \
    --mount=type=bind,source=scripts/deps/xcb-proto.sh,target=/opt/scripts/deps/xcb-proto.sh \
    --mount=type=bind,source=scripts/deps/libpthread-stubs.sh,target=/opt/scripts/deps/libpthread-stubs.sh \
    --mount=type=bind,source=scripts/deps/libxcb.sh,target=/opt/scripts/deps/libxcb.sh \
    --mount=type=bind,source=scripts/deps/xtrans.sh,target=/opt/scripts/deps/xtrans.sh \
    --mount=type=bind,source=scripts/deps/libX11.sh,target=/opt/scripts/deps/libX11.sh \
    set -e; for s in util-macros xorgproto libxau libxdmcp xcb-proto libpthread-stubs libxcb xtrans libX11; do bash /opt/scripts/deps/$s.sh; done
# audio/video devices
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/alsa-lib.sh,target=/opt/scripts/deps/alsa-lib.sh \
    set -e; for s in alsa-lib; do bash /opt/scripts/deps/$s.sh; done
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/sndio.sh,target=/opt/scripts/deps/sndio.sh \
    --mount=type=bind,source=scripts/deps/openal-soft.sh,target=/opt/scripts/deps/openal-soft.sh \
    --mount=type=bind,source=scripts/deps/sdl2.sh,target=/opt/scripts/deps/sdl2.sh \
    set -e; for s in sndio openal-soft sdl2; do bash /opt/scripts/deps/$s.sh; done
# hardware acceleration: drm / vaapi / vdpau / v4l
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/libdrm.sh,target=/opt/scripts/deps/libdrm.sh \
    --mount=type=bind,source=scripts/deps/libva.sh,target=/opt/scripts/deps/libva.sh \
    --mount=type=bind,source=scripts/deps/libvdpau.sh,target=/opt/scripts/deps/libvdpau.sh \
    --mount=type=bind,source=scripts/deps/v4l-utils.sh,target=/opt/scripts/deps/v4l-utils.sh \
    set -e; for s in libdrm libva libvdpau v4l-utils; do bash /opt/scripts/deps/$s.sh; done
# vulkan (headers + from-source loader)
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/vulkan-headers.sh,target=/opt/scripts/deps/vulkan-headers.sh \
    --mount=type=bind,source=scripts/deps/vulkan-loader.sh,target=/opt/scripts/deps/vulkan-loader.sh \
    set -e; for s in vulkan-headers vulkan-loader; do bash /opt/scripts/deps/$s.sh; done
# shader compiler stack (libplacebo compute / --enable-libshaderc)
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/spirv-headers.sh,target=/opt/scripts/deps/spirv-headers.sh \
    --mount=type=bind,source=scripts/deps/spirv-tools.sh,target=/opt/scripts/deps/spirv-tools.sh \
    --mount=type=bind,source=scripts/deps/glslang.sh,target=/opt/scripts/deps/glslang.sh \
    --mount=type=bind,source=scripts/deps/shaderc.sh,target=/opt/scripts/deps/shaderc.sh \
    set -e; for s in spirv-headers spirv-tools glslang shaderc; do bash /opt/scripts/deps/$s.sh; done
# ruby: ocl-icd's build runs icd_generator.rb (a Ruby code generator) over ocl_interface.yaml to
# emit the loader's dispatch sources. It is a build-time tool only (NOT linked into libOpenCL or
# any artifact), same category as the seed's perl / the autopoint above. Installed HERE — right
# before the libglvnd/opencl cluster, after the cached vulkan/spirv/glslang/shaderc layers — so it
# does not invalidate those expensive layers.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ruby; \
    rm -rf /var/lib/apt/lists/*
# opengl (libglvnd, needs libXext for GLX) / opencl loader / oneVPL
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/libXext.sh,target=/opt/scripts/deps/libXext.sh \
    --mount=type=bind,source=scripts/deps/libglvnd.sh,target=/opt/scripts/deps/libglvnd.sh \
    --mount=type=bind,source=scripts/deps/opencl-headers.sh,target=/opt/scripts/deps/opencl-headers.sh \
    --mount=type=bind,source=scripts/deps/ocl-icd.sh,target=/opt/scripts/deps/ocl-icd.sh \
    --mount=type=bind,source=scripts/deps/libvpl.sh,target=/opt/scripts/deps/libvpl.sh \
    set -e; for s in libXext libglvnd opencl-headers ocl-icd libvpl; do bash /opt/scripts/deps/$s.sh; done
# GPU codec headers (nvenc/nvdec/cuvid/ffnvcodec + AMD AMF)
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/nv-codec-headers.sh,target=/opt/scripts/deps/nv-codec-headers.sh \
    --mount=type=bind,source=scripts/deps/amf.sh,target=/opt/scripts/deps/amf.sh \
    set -e; for s in nv-codec-headers amf; do bash /opt/scripts/deps/$s.sh; done
# libplacebo: needs vulkan-loader + shaderc + lcms2 above
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/libplacebo.sh,target=/opt/scripts/deps/libplacebo.sh \
    set -e; for s in libplacebo; do bash /opt/scripts/deps/$s.sh; done
# clang/LLVM (from source) for FFmpeg --enable-cuda-llvm; placed LAST so it never cache-busts the
# media-lib layers above (nothing there needs it). Build-time tool only — not in the bundle.
RUN --mount=type=bind,source=scripts/deps/common.sh,target=/opt/scripts/deps/common.sh \
    --mount=type=bind,source=scripts/deps/llvm.sh,target=/opt/scripts/deps/llvm.sh \
    set -e; for s in llvm; do bash /opt/scripts/deps/$s.sh; done

# Latest stable verified in the research spec.
ARG FFMPEG_VERSION=8.1.1
ENV FFMPEG_VERSION=${FFMPEG_VERSION}

# --- entrypoint scripts COPYed LAST so edits to them reuse all cached dep layers above -------
# These MUST persist in the image (the bind-mounted dep recipes above do not): the ENTRYPOINT
# downloads + configures + builds + installs + verifies FFmpeg with OUR gcc AT `docker run` TIME,
# and the resulting bundle is relocatable via the baked $ORIGIN rpath (verified with readelf).
COPY scripts/build-ffmpeg.sh scripts/build-deps.sh /opt/scripts/

ENTRYPOINT ["bash", "/opt/scripts/build-ffmpeg.sh"]
