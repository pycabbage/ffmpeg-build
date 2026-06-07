#!/usr/bin/env bash
# kvazaar — HEVC/H.265 encoder; FFmpeg --enable-libkvazaar (pkg-config: kvazaar). cmake build.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.3.2"
SRC="${SRCROOT}/kvazaar"

fetch_git "https://github.com/ultravideo/kvazaar" "v${VER}" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTS=OFF
make -j"${JOBS}"
make install
ldconfig

verify_pc kvazaar
cleanup "${SRC}"
