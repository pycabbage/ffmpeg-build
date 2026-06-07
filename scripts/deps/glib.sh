#!/usr/bin/env bash
# GLib — core GNOME library (GLib/GObject/GIO); the base of the librsvg stack
# (pango/gdk-pixbuf/librsvg all need it). meson. Needs pcre2 + libffi + zlib (all built).
# Our gcc-14 for the whole build (avoid the seed gcc-13 for C under any LTO).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.86.5"
SRC="${SRCROOT}/glib"

fetch_tar "https://download.gnome.org/sources/glib/2.86/glib-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
export CC=gcc CXX=g++
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dtests=false \
  -Dintrospection=disabled \
  -Dman-pages=disabled
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc glib-2.0 gobject-2.0 gio-2.0
cleanup "${SRC}"
