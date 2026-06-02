#!/usr/bin/env bash
# SoX Resampler library (libsoxr) — high-quality audio resampling; FFmpeg --enable-libsoxr.
# CMake build; produces soxr.pc.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="0.1.3"
SRC="${SRCROOT}/soxr"

fetch_git "https://github.com/chirlu/soxr.git" "${VER}" "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTS=OFF \
  -DWITH_OPENMP=OFF
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc soxr
cleanup "${SRC}"
