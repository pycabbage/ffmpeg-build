#!/usr/bin/env bash
# snappy — fast compression library for FFmpeg --enable-libsnappy.
# Snappy ships no .pc file; sanity-check the shared lib directly.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.2.2"
SRC="${SRCROOT}/snappy"

fetch_tar "https://github.com/google/snappy/archive/refs/tags/${VER}.tar.gz" "${SRC}"
cd "${SRC}"
cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DSNAPPY_BUILD_TESTS=OFF \
      -DSNAPPY_BUILD_BENCHMARKS=OFF \
      -DBUILD_SHARED_LIBS=ON
cmake --build build -j"${JOBS}"
cmake --install build
ldconfig

test -f "${PREFIX}/lib/libsnappy.so"
cleanup "${SRC}"
