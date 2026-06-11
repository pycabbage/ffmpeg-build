#!/usr/bin/env bash
# cairo — 2D graphics; librsvg/pango render through it. meson. Needs pixman + our
# freetype/fontconfig/libpng/zlib/glib.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.18.4"
SRC="${SRCROOT}/cairo"

fetch_tar "https://cairographics.org/releases/cairo-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
export CC=gcc CXX=g++
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dtests=disabled
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc cairo cairo-ft
cleanup "${SRC}"
