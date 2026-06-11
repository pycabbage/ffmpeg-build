#!/usr/bin/env bash
# libcdio — GNU CD-ROM Input and Control library for FFmpeg --enable-libcdio.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "${HERE}/common.sh"

VER="2.1.0"
SRC="${SRCROOT}/libcdio"

fetch_tar "https://ftp.gnu.org/gnu/libcdio/libcdio-${VER}.tar.bz2" "${SRC}"
cd "${SRC}"
./configure --prefix="${PREFIX}" --enable-shared --disable-static
make -j"${JOBS}"
make install
ldconfig

verify_pc libcdio
cleanup "${SRC}"
