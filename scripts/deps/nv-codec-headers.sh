#!/usr/bin/env bash
# nv-codec-headers: NVIDIA codec API headers + dlopen stubs.
# Enables FFmpeg --enable-ffnvcodec/--enable-nvenc/--enable-nvdec/--enable-cuvid/--enable-cuda-llvm.
# Header-only: NO NVIDIA driver or CUDA toolkit is needed at build time.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="n12.2.72.0"
SRC="${SRCROOT}/nv-codec-headers"

fetch_git https://github.com/FFmpeg/nv-codec-headers.git "${VER}" "${SRC}"

# The Makefile is header-only; PREFIX defaults to /usr/local. Be explicit.
make -C "${SRC}" PREFIX="${PREFIX}" install
ldconfig

# Sanity: configure checks ffnvcodec via pkg-config.
verify_pc ffnvcodec

cleanup "${SRC}"
