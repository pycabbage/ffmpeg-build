#!/usr/bin/env bash
# vvenc: Fraunhofer HHI H.266/VVC encoder for FFmpeg --enable-libvvenc (FFmpeg >= 6.1).
# Not reliably packaged in Ubuntu 24.04 -> always built from source.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="v1.14.0"
SRC="${SRCROOT}/vvenc"

fetch_git https://github.com/fraunhoferhhi/vvenc.git "${VER}" "${SRC}"

# The convenience target builds Release + shared and installs libvvenc.pc. LD_RUN_PATH (exported
# by common.sh) bakes the $ORIGIN RPATH into libvvenc.so at link time.
make -C "${SRC}" install-release-shared install-prefix="${PREFIX}"
ldconfig

verify_pc libvvenc
cleanup "${SRC}"
