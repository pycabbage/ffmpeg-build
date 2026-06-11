#!/usr/bin/env bash
# libXau — X authorization protocol library; provides xau.pc.
# Required by libxcb. Must run after xorgproto + util-macros.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.0.12"
SRC="${SRCROOT}/libxau"

fetch_tar "https://xorg.freedesktop.org/releases/individual/lib/libXau-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc xau
cleanup "${SRC}"
