#!/usr/bin/env bash
# codec2 — open-source low-bitrate speech codec; serves FFmpeg --enable-libcodec2.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.2.0"
SRC="${SRCROOT}/codec2"

fetch_tar "https://github.com/drowe67/codec2/archive/refs/tags/${VER}.tar.gz" "${SRC}"
mkdir -p "${SRC}/build"
cd "${SRC}/build"
cmake .. \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DUNITTEST=OFF \
  -DGENERATE_CODEBOOK=/usr/bin/false
make -j"${JOBS}"
make install
ldconfig

verify_pc codec2
cleanup "${SRC}"
