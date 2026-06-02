#!/usr/bin/env bash
# libvpx — VP8/VP9 codec library; FFmpeg --enable-libvpx.
# Uses its own ./configure (not autotools). yasm/nasm must be on PATH.
# Source fetched as a git tag from chromium.googlesource.com mirror.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.16.0"
SRC="${SRCROOT}/libvpx"

fetch_git "https://chromium.googlesource.com/webm/libvpx" "v${VER}" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --enable-pic \
  --disable-examples \
  --disable-unit-tests
make -j"${JOBS}"
make install
ldconfig

verify_pc vpx
cleanup "${SRC}"
