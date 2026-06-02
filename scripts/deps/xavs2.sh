#!/usr/bin/env bash
# xavs2: AVS2 ENCODER (GPL) for FFmpeg --enable-libxavs2 (requires --enable-gpl).
# x264-derived build system: in-tree build under build/linux. nasm >= 2.13 mandatory.
# 8-bit only. No whitespace in paths.
set -euxo pipefail

VER="1.4"
SRC="/tmp/xavs2"

git clone --depth 1 --branch "${VER}" \
  https://github.com/pkuvcl/xavs2.git "${SRC}"

cd "${SRC}/build/linux"
./configure --prefix=/usr/local --enable-pic --enable-shared --disable-cli
make -j"$(nproc)"
make install
ldconfig

pkg-config --exists --print-errors xavs2

rm -rf "${SRC}"
