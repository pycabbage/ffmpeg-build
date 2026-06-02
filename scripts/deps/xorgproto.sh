#!/usr/bin/env bash
# xorgproto — X.Org protocol header definitions (replaces individual proto packages).
# Header-only install; provides xproto.pc, randrproto.pc, etc. required by libXau/libXdmcp.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2025.1"
SRC="${SRCROOT}/xorgproto"

fetch_tar "https://xorg.freedesktop.org/releases/individual/proto/xorgproto-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

verify_pc xproto
cleanup "${SRC}"
