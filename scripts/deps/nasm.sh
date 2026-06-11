#!/usr/bin/env bash
# NASM — Netwide Assembler; required by libx264, libx265, libaom, libdav1d, etc.
# No FFmpeg --enable flag; used at build time only.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="3.01"
SRC="${SRCROOT}/nasm"

fetch_tar "https://www.nasm.us/pub/nasm/releasebuilds/${VER}/nasm-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/bin/nasm"
cleanup "${SRC}"
