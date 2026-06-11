#!/usr/bin/env bash
# xcb-proto — XCB protocol descriptions (Python + XML); provides xcb-proto.pc.
# Header/data-only install; must run before libxcb. Requires python3 on PATH.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.17.0"
SRC="${SRCROOT}/xcb-proto"

fetch_tar "https://xcb.freedesktop.org/dist/xcb-proto-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

verify_pc xcb-proto
cleanup "${SRC}"
