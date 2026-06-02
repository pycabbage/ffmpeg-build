#!/usr/bin/env bash
# GNU FriBidi — Unicode bidirectional algorithm implementation; FFmpeg --enable-libfribidi.
# Used by libass for RTL text handling. Meson build; produces fribidi.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.0.16"
SRC="${SRCROOT}/fribidi"

fetch_tar "https://github.com/fribidi/fribidi/releases/download/v${VER}/fribidi-${VER}.tar.xz" "${SRC}"

meson setup "${SRC}/build" "${SRC}" \
  --buildtype release \
  --prefix="${PREFIX}" \
  --default-library shared \
  -Ddocs=false \
  -Dtests=false
ninja -C "${SRC}/build" install
ldconfig

verify_pc fribidi
cleanup "${SRC}"
