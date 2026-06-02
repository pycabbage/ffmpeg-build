#!/usr/bin/env bash
# davs2: AVS2 DECODER (GPL) for FFmpeg --enable-libdavs2 (requires --enable-gpl).
# x264-derived build system (same as xavs2): in-tree build under build/linux.
# nasm >= 2.13 mandatory. 8-bit only. No whitespace in paths.
set -euxo pipefail

VER="1.7"
SRC="/tmp/davs2"

git clone --depth 1 --branch "${VER}" \
  https://github.com/pkuvcl/davs2.git "${SRC}"

# gcc 14 promotes incompatible-pointer-types (and friends) to ERRORS; demote them for this
# older AVS2 C code via the x264-style --extra-cflags (same treatment as xavs2).
cd "${SRC}/build/linux"
./configure --prefix=/usr/local --enable-pic --enable-shared --disable-cli \
  --extra-cflags="-Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-int-conversion -Wno-implicit-int"
make -j"$(nproc)"
make install
ldconfig

pkg-config --exists --print-errors davs2

rm -rf "${SRC}"
