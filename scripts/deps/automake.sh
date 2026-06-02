#!/usr/bin/env bash
# GNU automake — generates Makefile.in from Makefile.am.
# Requires autoconf (built prior).
# No FFmpeg --enable flag; pure build-tool dependency.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.18.1"
SRC="${SRCROOT}/automake"

fetch_tar "https://ftp.gnu.org/gnu/automake/automake-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/bin/automake"
cleanup "${SRC}"
