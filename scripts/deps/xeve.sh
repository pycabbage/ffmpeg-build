#!/usr/bin/env bash
# xeve: MPEG-5 EVC encoder for FFmpeg --enable-libxeve (FFmpeg >= 6.1).
# CRITICAL: build the MAIN profile (the DEFAULT cmake config; do NOT pass -DSET_PROF=BASE)
# so it produces libxeve.so + xeve.pc. Baseline yields libxeveb/xeveb.pc which FFmpeg won't find.
set -euxo pipefail

VER="v0.5.1"
SRC="/tmp/xeve"

git clone --depth 1 --branch "${VER}" \
  https://github.com/mpeg5/xeve.git "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DBUILD_SHARED_LIBS=ON
cmake --build "${SRC}/build" --parallel "$(nproc)"
cmake --install "${SRC}/build"
ldconfig

# xeve's pkgconfig/symlink install step is historically finicky; verify the MAIN .pc.
pkg-config --exists --print-errors xeve

rm -rf "${SRC}"
