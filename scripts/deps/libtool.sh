#!/usr/bin/env bash
# GNU libtool — portable shared-library build helper (provides libtoolize + ltmain.sh).
# Requires m4 (built prior).
# No FFmpeg --enable flag; used by many autotools-based dep builds.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.5.4"
SRC="${SRCROOT}/libtool"

fetch_tar "https://ftp.gnu.org/gnu/libtool/libtool-${VER}.tar.xz" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --disable-static --enable-shared
make -j"${JOBS}"
make install
ldconfig

test -f "${PREFIX}/bin/libtool"
cleanup "${SRC}"
