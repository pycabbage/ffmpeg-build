#!/usr/bin/env bash
# libgme — game-music-emu; video game music emulation for FFmpeg --enable-libgme.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.6.5"
SRC="${SRCROOT}/libgme"

fetch_tar "https://github.com/libgme/game-music-emu/archive/refs/tags/${VER}.tar.gz" "${SRC}"
cd "${SRC}"
cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DBUILD_SHARED_LIBS=ON
cmake --build build -j"${JOBS}"
cmake --install build
ldconfig

verify_pc libgme
cleanup "${SRC}"
