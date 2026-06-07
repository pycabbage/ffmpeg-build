#!/usr/bin/env bash
# pixman — low-level pixel manipulation; cairo's core dependency. meson.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.46.4"
SRC="${SRCROOT}/pixman"

fetch_tar "https://cairographics.org/releases/pixman-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
export CC=gcc CXX=g++
meson setup build \
  --prefix="${PREFIX}" \
  --buildtype=release \
  --default-library=shared \
  -Dtests=disabled \
  -Ddemos=disabled
ninja -C build -j"${JOBS}"
ninja -C build install
ldconfig

verify_pc pixman-1
cleanup "${SRC}"
