#!/usr/bin/env bash
# librist — Reliable Internet Stream Transport library. FFmpeg --enable-librist.
# Meson build. Provides librist.pc. Must run after gnutls (used as crypto backend).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v0.2.11"
SRC="${SRCROOT}/librist"

fetch_git "https://code.videolan.org/rist/librist.git" "${VER}" "${SRC}"
cd "${SRC}"
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dtest=false \
  -Dbuilt_tools=false \
  -Dhave_cjson=false
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc librist
cleanup "${SRC}"
