#!/usr/bin/env bash
# FreeType — font rendering library; FFmpeg --enable-libfreetype.
# First-pass build (without harfbuzz); the freetype<->harfbuzz circular dep is
# resolved by building harfbuzz against this freetype, then rebuilding if needed.
# Depends on zlib, libpng, bzip2 (built earlier in the cluster ordering).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.14.3"
SRC="${SRCROOT}/freetype"

fetch_tar "https://download.savannah.gnu.org/releases/freetype/freetype-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure \
  --prefix="${PREFIX}" \
  --enable-shared \
  --disable-static \
  --with-zlib \
  --with-png \
  --with-bzip2 \
  --without-harfbuzz
make -j"${JOBS}"
make install
ldconfig

verify_pc freetype2
cleanup "${SRC}"
