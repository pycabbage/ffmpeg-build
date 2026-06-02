#!/usr/bin/env bash
# HarfBuzz — OpenType text shaping engine; FFmpeg --enable-libharfbuzz.
# Built with freetype support; glib/gobject/cairo disabled to avoid heavy deps.
# Depends on freetype (first-pass build above is sufficient).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="14.2.0"
SRC="${SRCROOT}/harfbuzz"

fetch_tar "https://github.com/harfbuzz/harfbuzz/releases/download/${VER}/harfbuzz-${VER}.tar.xz" "${SRC}"

meson setup "${SRC}/build" "${SRC}" \
  --buildtype release \
  --prefix="${PREFIX}" \
  --default-library shared \
  -Dfreetype=enabled \
  -Dglib=disabled \
  -Dgobject=disabled \
  -Dcairo=disabled \
  -Dtests=disabled \
  -Ddocs=disabled \
  -Dbenchmark=disabled
ninja -C "${SRC}/build" install
ldconfig

verify_pc harfbuzz
cleanup "${SRC}"
