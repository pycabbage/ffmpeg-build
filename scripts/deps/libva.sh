#!/usr/bin/env bash
# libva — Video Acceleration API (Intel VA-API); provides libva.pc + libva-drm.pc
# + libva-x11.pc. FFmpeg --enable-vaapi.
# Must run after libdrm + libxcb (x11 backend needs xcb).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.23.0"
SRC="${SRCROOT}/libva"

fetch_tar "https://github.com/intel/libva/archive/refs/tags/${VER}.tar.gz" "${SRC}"
meson setup "${SRC}/build" "${SRC}" \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dwith_glx=no \
  -Dwith_wayland=no
ninja -C "${SRC}/build" -j"${JOBS}"
ninja -C "${SRC}/build" install
ldconfig

verify_pc libva libva-drm libva-x11
cleanup "${SRC}"
