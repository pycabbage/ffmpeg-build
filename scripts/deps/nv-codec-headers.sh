#!/usr/bin/env bash
# nv-codec-headers: NVIDIA codec API headers + dlopen stubs.
# Enables FFmpeg --enable-ffnvcodec/--enable-nvenc/--enable-nvdec/--enable-cuvid/--enable-cuda-llvm.
# Header-only: NO NVIDIA driver or CUDA toolkit is needed at build time.
set -euxo pipefail

VER="n12.2.72.0"
SRC="/tmp/nv-codec-headers"

git clone --depth 1 --branch "${VER}" \
  https://github.com/FFmpeg/nv-codec-headers.git "${SRC}"

# The Makefile is header-only; PREFIX defaults to /usr/local. Be explicit.
make -C "${SRC}" PREFIX=/usr/local install
ldconfig

# Sanity: configure checks ffnvcodec via pkg-config.
pkg-config --exists --print-errors ffnvcodec

rm -rf "${SRC}"
