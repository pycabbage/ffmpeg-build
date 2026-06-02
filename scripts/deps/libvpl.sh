#!/usr/bin/env bash
# libvpl — Intel oneVPL dispatcher library; provides vpl.pc.
# FFmpeg --enable-libvpl (modern Intel QSV encode/decode; replaces libmfx).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v2.16.0"
SRC="${SRCROOT}/libvpl"

fetch_tar "https://github.com/intel/libvpl/archive/refs/tags/${VER}.tar.gz" "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DINSTALL_EXAMPLE_CODE=OFF
cmake --build "${SRC}/build" -j"${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc vpl
cleanup "${SRC}"
