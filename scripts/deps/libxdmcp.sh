#!/usr/bin/env bash
# libXdmcp — X Display Manager Control Protocol library; provides xdmcp.pc.
# Required by libxcb. Must run after xorgproto + util-macros.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.1.5"
SRC="${SRCROOT}/libxdmcp"

fetch_tar "https://xorg.freedesktop.org/releases/individual/lib/libXdmcp-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

verify_pc xdmcp
cleanup "${SRC}"
