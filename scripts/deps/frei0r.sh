#!/usr/bin/env bash
# frei0r-plugins — minimalist plugin API for video effects; FFmpeg --enable-frei0r.
# CMake build; installs frei0r.h header, plugin .so files, and frei0r.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v3.1.3"
SRC="${SRCROOT}/frei0r"

fetch_git "https://github.com/dyne/frei0r.git" "${VER}" "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DWITHOUT_OPENCV=ON
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc frei0r
cleanup "${SRC}"
