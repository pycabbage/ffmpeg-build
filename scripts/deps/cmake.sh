#!/usr/bin/env bash
# CMake — cross-platform build system generator; required by many media libs
# (libvmaf, svt-av1, libplacebo deps, etc.).
# Bootstraps using our ninja (built prior). Uses its own bundled curl/zlib for
# the bootstrap step so no external cmake dependency is needed.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="4.3.3"
SRC="${SRCROOT}/cmake"

fetch_tar "https://github.com/Kitware/CMake/archive/refs/tags/v${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./bootstrap \
  --prefix="${PREFIX}" \
  --parallel="${JOBS}" \
  --generator=Ninja
ninja -j"${JOBS}"
ninja install
ldconfig

cmake --version
cleanup "${SRC}"
