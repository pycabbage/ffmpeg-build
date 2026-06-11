#!/usr/bin/env bash
# xevd: MPEG-5 EVC decoder for FFmpeg --enable-libxevd (FFmpeg >= 6.1).
# Same MAIN-profile rule as xeve: build the DEFAULT config (no -DSET_PROF=BASE) so it
# produces libxevd.so + xevd.pc. Baseline yields libxevdb/xevdb.pc which FFmpeg won't find.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v0.5.0"
SRC="${SRCROOT}/xevd"

fetch_git https://github.com/mpeg5/xevd.git "${VER}" "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

verify_pc xevd
cleanup "${SRC}"
