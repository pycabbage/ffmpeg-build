#!/usr/bin/env bash
# libdrm — Direct Rendering Manager userspace library; provides libdrm.pc.
# FFmpeg --enable-libdrm + required by libva and v4l2-m2m.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.4.134"
SRC="${SRCROOT}/libdrm"

fetch_tar "https://dri.freedesktop.org/libdrm/libdrm-${VER}.tar.xz" "${SRC}"
meson setup "${SRC}/build" "${SRC}" \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dudev=false \
  -Dtests=false \
  -Dman-pages=disabled
ninja -C "${SRC}/build" -j"${JOBS}"
ninja -C "${SRC}/build" install
ldconfig

verify_pc libdrm
cleanup "${SRC}"
