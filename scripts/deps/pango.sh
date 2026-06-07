#!/usr/bin/env bash
# pango — text layout/rendering; used by librsvg for <text> elements. meson. Needs glib + cairo +
# our harfbuzz/fribidi/fontconfig/freetype.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.57.1"
SRC="${SRCROOT}/pango"

fetch_tar "https://download.gnome.org/sources/pango/1.57/pango-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
export CC=gcc CXX=g++
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dintrospection=disabled
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc pango pangocairo
cleanup "${SRC}"
