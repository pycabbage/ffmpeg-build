#!/usr/bin/env bash
# xavs2: AVS2 ENCODER (GPL) for FFmpeg --enable-libxavs2 (requires --enable-gpl).
# x264-derived build system: in-tree build under build/linux. nasm >= 2.13 mandatory.
# 8-bit only. No whitespace in paths.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.4"
SRC="${SRCROOT}/xavs2"

fetch_git https://github.com/pkuvcl/xavs2.git "${VER}" "${SRC}"

# gcc 14 promotes incompatible-pointer-types (and friends) from warnings to ERRORS; xavs2's
# older C code trips encoder.c. Demote them back to warnings via the x264-style --extra-cflags.
cd "${SRC}/build/linux"
./configure --prefix="${PREFIX}" --enable-pic --enable-shared --disable-cli \
  --extra-cflags="-Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-int-conversion -Wno-implicit-int"
make -j"${JOBS}"
make install
ldconfig

verify_pc xavs2
cleanup "${SRC}"
