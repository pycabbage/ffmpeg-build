#!/usr/bin/env bash
# YASM — assembler compatible with NASM syntax; used by libvpx and some FFmpeg internals.
# No FFmpeg --enable flag; used at build time only.
# Upstream 1.3.0 (2014) is still the only stable release.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.3.0"
SRC="${SRCROOT}/yasm"

fetch_tar "https://www.tortall.net/projects/yasm/releases/yasm-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/bin/yasm"
cleanup "${SRC}"
