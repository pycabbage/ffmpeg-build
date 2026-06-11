#!/usr/bin/env bash
# xeve: MPEG-5 EVC encoder for FFmpeg --enable-libxeve (FFmpeg >= 6.1).
# CRITICAL: build the MAIN profile (the DEFAULT cmake config; do NOT pass -DSET_PROF=BASE)
# so it produces libxeve.so + xeve.pc. Baseline yields libxeveb/xeveb.pc which FFmpeg won't find.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v0.5.1"
SRC="${SRCROOT}/xeve"

fetch_git https://github.com/mpeg5/xeve.git "${VER}" "${SRC}"

cmake -S "${SRC}" -B "${SRC}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_SHARED_LIBS=ON
cmake --build "${SRC}/build" --parallel "${JOBS}"
cmake --install "${SRC}/build"
ldconfig

# xeve's pkgconfig/symlink install step is historically finicky; verify the MAIN .pc.
verify_pc xeve
cleanup "${SRC}"
