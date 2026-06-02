#!/usr/bin/env bash
# x265 — H.265/HEVC encoder; FFmpeg --enable-libx265.
# cmake must be run from the source/CMakeLists.txt dir (not the repo root).
# Single 8-bit build; 10-bit and 12-bit multilib omitted (no linked-multilib setup).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.2"
SRC="${SRCROOT}/x265"

# The bitbucket "downloads/" tarballs 404 (and the agent's org name was wrong); clone the git
# repo from the CORRECT org (multicoreware, not multicorewareInc) and check out the release tag.
# cmake builds from the source/ subdir.
fetch_git "https://bitbucket.org/multicoreware/x265_git.git" "${VER}" "${SRC}"
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
