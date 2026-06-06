#!/usr/bin/env bash
# build-deps.sh — ordered driver that builds EVERY from-source dependency, in dependency order.
#
# This is the canonical ordering (the Dockerfile mirrors it, grouped into per-phase RUN layers
# for caching). Per docs/todo/001-full-build.md the build no longer apt-installs any libraries:
# the toolchain, the build tools, and all media libraries are compiled from source into
# /usr/local by our own from-source gcc. Only an OS-floor bootstrap seed (gcc/make/perl, see the
# Dockerfile) comes from apt, used solely to compile our gcc.
#
# Run inside the build image (or any Ubuntu 24.04 with the seed packages) as:
#     bash scripts/build-deps.sh
# A failing script aborts the run (set -e). Each scripts/deps/<lib>.sh sources deps/common.sh.
set -euxo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS="${HERE}/deps"

# Order matters: each library is built after everything it links against.
LIBS=(
  # phase 0: pkg-config (every later verify_pc needs it)
  pkgconf
  # phase 1: toolchain (built by the bootstrap seed compiler)
  zlib zstd bzip2 xz
  gmp mpfr mpc isl
  binutils
  gcc                       # installs the $ORIGIN rpath specs; OUR gcc is used from here on
  # phase 2: build tools (built by our gcc)
  m4 autoconf automake libtool nasm yasm
  libffi openssl ncurses readline
  python
  ninja cmake meson
  # phase 3: media-library base deps
  libogg libpng libjpeg-turbo expat gperf fftw lcms2
  # video codecs
  x264 x265 xvid libvpx aom dav1d svtav1 openh264 libtheora libwebp openjpeg
  vvenc xeve xevd xavs2 davs2 rav1e
  # uavs3d omitted from the build: --enable-libuavs3d is not passed (API too old for FFmpeg 8.1.1)
  # audio codecs
  lame opus libvorbis fdk-aac twolame libgsm speex speexdsp opencore-amr vo-amrwbenc shine codec2 libmysofa
  # subtitles / text / fonts
  freetype fribidi fontconfig harfbuzz libass
  # filters
  aribb24 libaribcaption zimg rubberband soxr vidstab frei0r ladspa libbs2b flite
  # OCR + quality metric
  leptonica tesseract libvmaf
  # TLS + network protocols
  nettle libtasn1 libunistring p11-kit gnutls
  librtmp libsrt libssh libzmq librist
  # demux / containers / sources
  libxml2 snappy libgme libmodplug libopenmpt chromaprint libcaca
  libusb libraw1394 libdc1394 libcdio libcdio-paranoia
  libbluray
  # X11 / XCB stack (libX11/xtrans added: vdpau + opengl-GLX need Xlib, not just XCB)
  util-macros xorgproto libxau libxdmcp xcb-proto libpthread-stubs libxcb xtrans libX11
  # audio/video devices
  alsa-lib sndio openal-soft sdl2
  # hardware acceleration
  libdrm libva libvdpau v4l-utils
  vulkan-headers vulkan-loader
  spirv-headers spirv-tools glslang shaderc
  # libXext (X11 ext lib) sits with its consumer libglvnd, not the X11 base stack above, so it
  # doesn't cache-bust the heavy vulkan/spirv/glslang/shaderc layers; deps (libX11) already built.
  libXext libglvnd opencl-headers ocl-icd libvpl
  nv-codec-headers amf
  libplacebo                # needs vulkan-loader + shaderc + lcms2
  # clang/LLVM last: build-time-only tool for FFmpeg --enable-cuda-llvm (compiles CUDA kernels to
  # PTX). Nothing else depends on it; placed last so it never cache-busts the media-lib layers.
  llvm
)

for lib in "${LIBS[@]}"; do
  echo "==== building ${lib} ===="
  bash "${DEPS}/${lib}.sh"
done

echo "All source dependencies built."
