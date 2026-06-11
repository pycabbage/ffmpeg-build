#!/usr/bin/env bash
# openal-soft — software OpenAL implementation; provides openal.pc.
# FFmpeg --enable-openal (audio capture/playback device).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.25.2"
SRC="${SRCROOT}/openal-soft"

fetch_tar "https://github.com/kcat/openal-soft/archive/refs/tags/${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DALSOFT_UTILS=OFF \
  -DALSOFT_EXAMPLES=OFF \
  -DALSOFT_TESTS=OFF
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc openal
cleanup "${SRC}"
