#!/usr/bin/env bash
# fontconfig — font discovery and configuration library; FFmpeg --enable-libfontconfig.
# Depends on freetype, expat, and gperf (build-time tool). Autotools build.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.18.0"
SRC="${SRCROOT}/fontconfig"

# GitHub read-only mirror of gitlab.freedesktop.org/fontconfig/fontconfig
fetch_git "https://github.com/fontconfig/fontconfig.git" "${VER}" "${SRC}"
cd "${SRC}"
autoreconf -fiv
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --disable-docs \
  --enable-libxml2=no
make -j"${JOBS}"
make install
ldconfig

verify_pc fontconfig
cleanup "${SRC}"
