#!/usr/bin/env bash
# libpng — PNG image library; needed by libtheora (--disable-examples), libwebp, openjpeg, etc.
# Uses autotools; zlib must be built before this script.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="1.6.58"
SRC="${SRCROOT}/libpng"

fetch_tar "https://sourceforge.net/projects/libpng/files/libpng16/${VER}/libpng-${VER}.tar.xz/download" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libpng
cleanup "${SRC}"
