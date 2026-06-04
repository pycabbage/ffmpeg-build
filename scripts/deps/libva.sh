#!/usr/bin/env bash
# libva — Video Acceleration API (Intel VA-API); provides libva.pc + libva-drm.pc. FFmpeg
# --enable-vaapi uses libva + libva-drm (DRM render node). The X11 VA backend (libva-x11.pc)
# needs Xlib (libX11/libXext/libXfixes), which this build does NOT ship (we build the XCB stack,
# not Xlib), so it is explicitly disabled (-Dwith_x11=no) and not verified. FFmpeg's vaapi does
# not require it. Must run after libdrm.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.23.0"
SRC="${SRCROOT}/libva"

fetch_tar "https://github.com/intel/libva/archive/refs/tags/${VER}.tar.gz" "${SRC}"
meson setup "${SRC}/build" "${SRC}" \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dwith_x11=no \
  -Dwith_glx=no \
  -Dwith_wayland=no
ninja -C "${SRC}/build" -j"${JOBS}"
ninja -C "${SRC}/build" install
ldconfig

verify_pc libva libva-drm
cleanup "${SRC}"
