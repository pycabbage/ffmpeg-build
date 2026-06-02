#!/usr/bin/env bash
# vvenc: Fraunhofer HHI H.266/VVC encoder for FFmpeg --enable-libvvenc (FFmpeg >= 6.1).
# Not reliably packaged in Ubuntu 24.04 -> always built from source.
set -euxo pipefail

VER="v1.14.0"
SRC="/tmp/vvenc"

git clone --depth 1 --branch "${VER}" \
  https://github.com/fraunhoferhhi/vvenc.git "${SRC}"

# The convenience target builds Release + shared and installs libvvenc.pc.
make -C "${SRC}" install-release-shared install-prefix=/usr/local
ldconfig

pkg-config --exists --print-errors libvvenc

rm -rf "${SRC}"
