#!/usr/bin/env bash
# libtheora — Xiph Theora video codec; FFmpeg --enable-libtheora.
# Requires libogg (built earlier in this cluster). --disable-examples avoids a
# libpng/SDL dependency chain from the encoder example; --disable-spec skips TeX.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.2.0"
SRC="${SRCROOT}/libtheora"

fetch_tar "https://downloads.xiph.org/releases/theora/libtheora-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --disable-examples \
  --disable-spec
make -j"${JOBS}"
make install
ldconfig

verify_pc theora theoraenc theoradec
cleanup "${SRC}"
