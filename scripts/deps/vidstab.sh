#!/usr/bin/env bash
# vid.stab — video stabilization library; FFmpeg --enable-libvidstab.
# CMake build; produces vidstab.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.1.1"
SRC="${SRCROOT}/vidstab"

fetch_git "https://github.com/georgmartius/vid.stab.git" "${VER}" "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc vidstab
cleanup "${SRC}"
