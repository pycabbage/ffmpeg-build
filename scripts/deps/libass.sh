#!/usr/bin/env bash
# libass — subtitle rendering library; FFmpeg --enable-libass.
# Depends on freetype, fribidi, harfbuzz, and fontconfig. Autotools build.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.17.4"
SRC="${SRCROOT}/libass"

fetch_tar "https://github.com/libass/libass/releases/download/${VER}/libass-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libass
cleanup "${SRC}"
