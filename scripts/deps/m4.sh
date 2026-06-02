#!/usr/bin/env bash
# GNU m4 — macro processor; prerequisite for autoconf/libtool.
# No FFmpeg --enable flag; pure build-tool dependency.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.4.21"
SRC="${SRCROOT}/m4"

fetch_tar "https://ftp.gnu.org/gnu/m4/m4-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/bin/m4"
cleanup "${SRC}"
