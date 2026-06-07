#!/usr/bin/env bash
# libaribcaption: ARIB STD-B24 caption decoder/renderer for FFmpeg --enable-libaribcaption
# (FFmpeg >= 6.1). Coexists with libaribb24 (--enable-libaribb24) -- different decoders.
# Default build is STATIC; force shared. FreeType + Fontconfig (from source) enable rendering.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.1.1"
SRC="${SRCROOT}/libaribcaption"

fetch_git https://github.com/xqq/libaribcaption.git "${VER}" "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON \
  -DARIBCC_BUILD_TESTS=OFF
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc libaribcaption
cleanup "${SRC}"
