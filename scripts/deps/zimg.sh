#!/usr/bin/env bash
# zimg — scaling, colorspace conversion, and dithering; FFmpeg --enable-libzimg (zscale filter).
# Autotools build; autogen.sh must be run to create the configure script from git checkout.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="release-3.0.6"
SRC="${SRCROOT}/zimg"

fetch_tar "https://github.com/sekrit-twc/zimg/archive/refs/tags/${VER}.tar.gz" "${SRC}"
cd "${SRC}"
autoreconf -fiv
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc zimg
cleanup "${SRC}"
