#!/usr/bin/env bash
# libaribcaption: ARIB STD-B24 caption decoder/renderer for FFmpeg --enable-libaribcaption
# (FFmpeg >= 6.1). Coexists with apt libaribb24 (--enable-libaribb24) -- different decoders.
# Default build is STATIC; force shared. FreeType + Fontconfig dev libs (apt) enable rendering.
set -euxo pipefail

VER="v1.1.1"
SRC="/tmp/libaribcaption"

git clone --depth 1 --branch "${VER}" \
  https://github.com/xqq/libaribcaption.git "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DBUILD_SHARED_LIBS=ON \
  -DARIBCC_BUILD_TESTS=OFF
cmake --build "${SRC}/build" --parallel "$(nproc)"
cmake --install "${SRC}/build"
ldconfig

pkg-config --exists --print-errors libaribcaption

rm -rf "${SRC}"
