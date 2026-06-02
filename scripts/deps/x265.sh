#!/usr/bin/env bash
# x265 — H.265/HEVC encoder; FFmpeg --enable-libx265.
# cmake must be run from the source/CMakeLists.txt dir (not the repo root).
# Single 8-bit build; 10-bit and 12-bit multilib omitted (no linked-multilib setup).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.2"
SRC="${SRCROOT}/x265"

fetch_tar "https://bitbucket.org/multicorewareInc/x265_git/downloads/x265_${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake ../source \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SHARED=ON \
  -DENABLE_STATIC=OFF
make -j"${JOBS}"
make install
ldconfig

verify_pc x265
cleanup "${SRC}"
