#!/usr/bin/env bash
# xtrans — X Transport abstraction. Build-time only: installs transport headers + xtrans.pc
# (no shared library). Required to build libX11 (and other X.org client libs).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.6.0"
SRC="${SRCROOT}/xtrans"

fetch_tar "https://www.x.org/releases/individual/lib/xtrans-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

verify_pc xtrans
cleanup "${SRC}"
