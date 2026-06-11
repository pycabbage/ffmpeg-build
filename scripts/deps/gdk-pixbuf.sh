#!/usr/bin/env bash
# gdk-pixbuf — image loading; librsvg uses it for raster <image> elements + as a loader host.
# meson. Needs glib + our libpng/libjpeg.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.44.6"
SRC="${SRCROOT}/gdk-pixbuf"

fetch_tar "https://download.gnome.org/sources/gdk-pixbuf/2.44/gdk-pixbuf-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
export CC=gcc CXX=g++
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dtests=false \
  -Dintrospection=disabled \
  -Dman=false \
  -Dgio_sniffing=false \
  -Dglycin=disabled
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc gdk-pixbuf-2.0
cleanup "${SRC}"
