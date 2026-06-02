#!/usr/bin/env bash
# xevd: MPEG-5 EVC decoder for FFmpeg --enable-libxevd (FFmpeg >= 6.1).
# Same MAIN-profile rule as xeve: build the DEFAULT config (no -DSET_PROF=BASE) so it
# produces libxevd.so + xevd.pc. Baseline yields libxevdb/xevdb.pc which FFmpeg won't find.
set -euxo pipefail

VER="v0.5.0"
SRC="/tmp/xevd"

git clone --depth 1 --branch "${VER}" \
  https://github.com/mpeg5/xevd.git "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DBUILD_SHARED_LIBS=ON
cmake --build "${SRC}/build" --parallel "$(nproc)"
cmake --install "${SRC}/build"
ldconfig

pkg-config --exists --print-errors xevd

rm -rf "${SRC}"
