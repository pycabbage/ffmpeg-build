#!/usr/bin/env bash
# xorg util-macros — autoconf macros for X.Org builds; provides xorg-macros.pc and
# the m4 macros (XORG_DEFAULT_OPTIONS etc.) required by libXau, libXdmcp, libxcb chain.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.20.2"
SRC="${SRCROOT}/util-macros"

fetch_tar "https://xorg.freedesktop.org/releases/individual/util/util-macros-${VER}.tar.gz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

verify_pc xorg-macros
cleanup "${SRC}"
