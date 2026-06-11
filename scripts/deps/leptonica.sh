#!/usr/bin/env bash
# Leptonica — image processing library required by tesseract; no direct FFmpeg flag.
# CMake build; produces lept.pc. Depends on libpng, libjpeg, zlib (built earlier).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.87.0"
SRC="${SRCROOT}/leptonica"

fetch_tar "https://github.com/DanBloomberg/leptonica/releases/download/${VER}/leptonica-${VER}.tar.gz" "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON \
  -DSW_BUILD=OFF
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc lept
cleanup "${SRC}"
