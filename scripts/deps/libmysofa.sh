#!/usr/bin/env bash
# libmysofa — AES SOFA file reader for HRTF support; serves FFmpeg --enable-libmysofa.
# Requires zlib (built earlier in the chain, available in ${PREFIX}).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.4"
SRC="${SRCROOT}/libmysofa"

fetch_tar "https://github.com/hoene/libmysofa/archive/refs/tags/v${VER}.tar.gz" "${SRC}"
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

verify_pc libmysofa
cleanup "${SRC}"
